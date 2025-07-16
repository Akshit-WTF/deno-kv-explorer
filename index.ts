#!/usr/bin/env bun
import { openKv } from "@deno/kv";
import { serialize as encodeV8, deserialize as decodeV8 } from "v8"; // actually JavaScriptCore format on Bun!

// Configuration from environment variables
const DENO_KV_ACCESS_TOKEN = process.env.DENO_KV_ACCESS_TOKEN;
const KV_URL = process.env.KV_URL;
const PORT = parseInt(process.env.PORT || "4055");
const PASSWORD = process.env.PASSWORD || "";

// Session storage for authenticated sessions
const authenticatedSessions = new Set<string>();

function generateSessionId(): string {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

const kv = await openKv(KV_URL, { encodeV8, decodeV8 });

async function getEntriesForNamespace(namespace: string) {
  const prefix = namespace ? [namespace] : [];
  const entries = await Array.fromAsync(kv.list({ prefix }));
  // We also need to get the list of all namespaces (top-level keys)
  const allKeys = await Array.fromAsync(kv.list({ prefix: [] }));
  const namespaces = [...new Set(allKeys.map((entry) => entry.key[0]))];

  return { entries, namespaces };
}

async function getNamespaceCounts() {
  const allKeys = await Array.fromAsync(kv.list({ prefix: [] }));
  const namespaces = [...new Set(allKeys.map((entry) => entry.key[0]))];
  
  const counts: Record<string, number> = {};
  for (const ns of namespaces) {
    if (typeof ns === 'string') {
      const nsEntries = allKeys.filter(entry => 
        entry.key[0] === ns && 
        entry.key.length > 1 &&
        typeof entry.key[1] === 'string' &&
        !entry.key[1].startsWith('_deno_kv_placeholder')
      );
      counts[ns] = nsEntries.length;
    }
  }
  
  return { namespaces: namespaces.filter(ns => typeof ns === 'string') as string[], counts };
}

async function createNamespace(namespace: string) {
  // Create a placeholder entry to ensure the namespace exists
  const placeholderKey = [namespace, "_deno_kv_placeholder"];
  await kv.set(placeholderKey, { _placeholder: true, created: new Date().toISOString() });
  return await getEntriesForNamespace(namespace);
}

// --- Web Server with WebSocket ---
const server = Bun.serve({
  port: PORT,
  async fetch(req, server) {
    const url = new URL(req.url);
    const sessionId = new URL(req.url).searchParams.get('session') || 
                     req.headers.get('cookie')?.match(/session=([^;]+)/)?.[1];

    if (url.pathname === "/") {
      return new Response(Bun.file("./index.html"));
    }

    if (url.pathname === "/auth") {
      const body = await req.text();
      const { password } = JSON.parse(body);
      
      if (!PASSWORD || password === PASSWORD) {
        const sessionId = generateSessionId();
        authenticatedSessions.add(sessionId);
        
        const response = { 
          success: true, 
          sessionId,
          requiresPassword: !!PASSWORD 
        };
        
        return new Response(JSON.stringify(response), {
          headers: { 
            'Content-Type': 'application/json',
            'Set-Cookie': `session=${sessionId}; HttpOnly; SameSite=Strict`
          }
        });
      } else {
        const response = { 
          success: false, 
          message: 'Invalid password' 
        };
        console.log('Auth failed response:', response);
        
        return new Response(JSON.stringify(response), {
          status: 401,
          headers: { 'Content-Type': 'application/json' }
        });
      }
    }

    if (url.pathname === "/ws") {
      // Check authentication for WebSocket connections
      if (PASSWORD && (!sessionId || !authenticatedSessions.has(sessionId))) {
        return new Response("Unauthorized", { status: 401 });
      }
      
      if (server.upgrade(req)) {
        return;
      }
      return new Response("WebSocket upgrade failed", { status: 500 });
    }

    return new Response("Not Found", { status: 404 });
  },
  websocket: {
    // A client connected
    async open(ws) {
      console.log("WebSocket client connected");
      ws.subscribe("kv-updates");

      // Send initial data (all namespaces and entries from the "default" namespace)
      const initialData = await getEntriesForNamespace("default");
      ws.send(JSON.stringify({ type: "initial-data", payload: initialData }));
    },
    // A client sent a message
    async message(ws, message) {
      try {
        const { type, payload } = JSON.parse(message as string);
        let data;

        switch (type) {
          case "get-namespace-data":
            data = await getEntriesForNamespace(payload.namespace);
            // Send data only to the requesting client
            ws.send(JSON.stringify({ type: "namespace-data", payload: data }));
            break;
          case "get-namespace-counts":
            const countsData = await getNamespaceCounts();
            ws.send(JSON.stringify({ type: "namespace-counts", payload: countsData }));
            break;
          case "create-namespace":
            if (payload.namespace) {
              data = await createNamespace(payload.namespace);
              // Send updated data to the requesting client
              ws.send(JSON.stringify({ type: "namespace-data", payload: data }));
              // Broadcast the update to all clients
              server.publish(
                "kv-updates",
                JSON.stringify({
                  type: "update",
                  payload: { ...data, updatedNamespace: payload.namespace },
                })
              );
              // Also send updated namespace counts
              const countsData = await getNamespaceCounts();
              server.publish(
                "kv-updates",
                JSON.stringify({ type: "namespace-counts", payload: countsData })
              );
            }
            break;
          case "add-item":
            if (
              payload.namespace &&
              payload.key &&
              payload.value !== undefined
            ) {
              // Remove placeholder if it exists
              const placeholderKey = [payload.namespace, "_deno_kv_placeholder"];
              await kv.delete(placeholderKey);
              
              const key = [payload.namespace, payload.key];
              await kv.set(key, payload.value);
              console.log(`Set key: ${key.join("/")}`);
              data = await getEntriesForNamespace(payload.namespace);
              server.publish(
                "kv-updates",
                JSON.stringify({
                  type: "update",
                  payload: { ...data, updatedNamespace: payload.namespace },
                })
              );
            }
            break;
          case "delete-item":
            if (payload.namespace && payload.key) {
              const key = [payload.namespace, payload.key];
              await kv.delete(key);
              console.log(`Deleted key: ${key.join("/")}`);
              data = await getEntriesForNamespace(payload.namespace);
              server.publish(
                "kv-updates",
                JSON.stringify({
                  type: "update",
                  payload: { ...data, updatedNamespace: payload.namespace },
                })
              );
            }
            break;
          case "delete-namespace":
            if (payload.namespace && payload.namespace !== 'default') {
              // Delete all entries in the namespace
              const entries = await Array.fromAsync(kv.list({ prefix: [payload.namespace] }));
              for (const entry of entries) {
                await kv.delete(entry.key);
              }
              console.log(`Deleted namespace: ${payload.namespace}`);
              
              // Send updated namespace counts
              const countsData = await getNamespaceCounts();
              server.publish(
                "kv-updates",
                JSON.stringify({ type: "namespace-counts", payload: countsData })
              );
              
              // Send success response
              ws.send(JSON.stringify({ 
                type: "namespace-deleted", 
                payload: { namespace: payload.namespace } 
              }));
            }
            break;
        }
      } catch (error) {
        console.error("Error processing WebSocket message:", error);
        ws.send(
          JSON.stringify({
            type: "error",
            payload: { message: "An internal server error occurred." },
          })
        );
      }
    },
    // A client disconnected
    close(ws) {
      console.log("WebSocket client disconnected");
      ws.unsubscribe("kv-updates");
    },
  },
});

console.log(`🗄️  Deno KV Explorer running at http://localhost:${server.port}`);
console.log(`📊 Connected to KV at: ${KV_URL}`);
console.log(`🚀 Environment: ${process.env.NODE_ENV || 'development'}`);
console.log(`🔒 Password protection: ${PASSWORD ? 'ENABLED' : 'DISABLED'}`);
if (PASSWORD) {
  console.log(`💡 Set PASSWORD environment variable to change the password`);
}
