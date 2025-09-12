# Contributing to 42 Norminette & Build Check Action

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the action.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature/fix
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

### Prerequisites

- Docker (for testing the containerized action)
- Git
- A GitHub account

### Local Testing

You can test the action locally using [act](https://github.com/nektos/act):

```bash
# Install act (macOS)
brew install act

# Run the test workflow
act -j test-action
```

Or test individual components:

```bash
# Test the Docker container directly
docker build -t ft_forge_test .
docker run --rm -v $(pwd)/test-project:/github/workspace/test-project ft_forge_test
```

## Making Changes

### Code Style

- Follow shell scripting best practices
- Use consistent indentation (2 spaces)
- Add comments for complex logic
- Use meaningful variable names

### Testing

Before submitting a pull request:

1. Test with valid 42 School projects
2. Test with projects that have norminette violations
3. Test with projects that fail to build
4. Test edge cases (no Makefile, no C files, etc.)

### Documentation

- Update the README.md if you add new features
- Add examples for new functionality
- Update the action.yml file if you add new inputs/outputs

## Pull Request Process

1. **Create a descriptive title** for your PR
2. **Describe your changes** in detail
3. **Reference any related issues**
4. **Include test results** or screenshots if applicable
5. **Ensure all tests pass**

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing
- [ ] Tested with valid 42 projects
- [ ] Tested with norminette violations
- [ ] Tested with build failures
- [ ] Tested edge cases

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass
```

## Reporting Issues

When reporting issues:

1. Use a clear, descriptive title
2. Provide steps to reproduce
3. Include your workflow file
4. Include error messages/logs
5. Specify your environment (OS, project type, etc.)

### Issue Template

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Project: [e.g., cub3d, minishell]
- Action Version: [e.g., v1.0.0]

## Additional Context
Any other relevant information
```

## Feature Requests

For feature requests:

1. Check if the feature already exists
2. Describe the use case
3. Explain why it would be beneficial
4. Consider implementation complexity

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow GitHub's community guidelines

## Development Guidelines

### Shell Script Guidelines

- Use `set -e` for error handling
- Quote variables to prevent word splitting
- Use `[[ ]]` instead of `[ ]` for conditionals
- Prefer `$()` over backticks for command substitution

### Docker Guidelines

- Keep the image size minimal
- Use specific base image versions
- Clean up package caches
- Follow security best practices

### Action Guidelines

- Keep inputs/outputs well documented
- Provide sensible defaults
- Handle edge cases gracefully
- Provide clear error messages

## Release Process

Releases are managed by maintainers:

1. Version bumping follows semantic versioning
2. Release notes are auto-generated from PRs
3. Actions are automatically published to marketplace
4. Docker images are built and tagged

## Questions?

If you have questions about contributing:

1. Check existing issues/discussions
2. Create a new discussion
3. Reach out to maintainers

Thank you for contributing! 🚀
