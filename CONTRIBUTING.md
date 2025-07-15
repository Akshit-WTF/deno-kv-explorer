# Contributing to Deno KV Explorer

Thank you for your interest in contributing to Deno KV Explorer! This document provides guidelines and instructions for contributing.

## 🚀 Quick Start

1. **Fork the repository**
2. **Clone your fork**:
   ```bash
   git clone https://github.com/your-username/deno-kv-explorer.git
   cd deno-kv-explorer
   ```
3. **Install dependencies**:
   ```bash
   bun install
   ```
4. **Start development**:
   ```bash
   bun run dev
   ```

## 📋 Development Guidelines

### Code Style

- Use TypeScript for all new code
- Follow the existing code style and formatting
- Use meaningful variable and function names
- Add comments for complex logic

### Commit Messages

Use conventional commit format:
- `feat: add new feature`
- `fix: resolve bug`
- `docs: update documentation`
- `style: formatting changes`
- `refactor: code restructuring`
- `test: add tests`
- `chore: maintenance tasks`

### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and test thoroughly

3. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: describe your feature"
   ```

4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a pull request** with:
   - Clear description of changes
   - Screenshots for UI changes
   - Reference any related issues

## 🐛 Bug Reports

When reporting bugs, please include:
- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected vs actual behavior**
- **Environment details** (OS, browser, versions)
- **Screenshots** if applicable

## 💡 Feature Requests

For new features:
- **Describe the problem** you're trying to solve
- **Explain your proposed solution**
- **Consider alternatives** you've thought of
- **Provide context** on why this would be valuable

## 🧪 Testing

Before submitting:
- Test your changes thoroughly
- Ensure the application starts without errors
- Test on different screen sizes (responsive design)
- Verify WebSocket functionality works correctly

## 📦 Building and Publishing

### Local Testing

```bash
# Test the application
bun run start

# Test Docker build
docker build -t deno-kv-explorer .
docker run -p 4055:4055 deno-kv-explorer
```

### Publishing to npm

Publishing is automated via GitHub Actions when releases are created. For manual testing:

1. **Configure npm authentication**:
   ```bash
   npm login
   ```

2. **Test publishing**:
   ```bash
   npm publish --dry-run
   ```

## 🔧 Development Environment

### Required Tools

- [Bun](https://bun.sh) v1.2.17+
- [Docker](https://docker.com) (optional)
- Modern web browser
- Text editor/IDE with TypeScript support

### Environment Variables

Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

### Docker Development

```bash
# Build and run with Docker
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📝 Documentation

When contributing:
- Update README.md for new features
- Add inline code comments
- Update configuration examples
- Include screenshots for UI changes

## 🤝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a welcoming community

## 🙋‍♂️ Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and community chat
- **Email**: For private concerns

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Deno KV Explorer! 🎉
