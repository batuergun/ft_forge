# 42 Norminette & Build Check Action

A comprehensive GitHub Action for 42 School C projects that runs norminette (the 42 coding standard checker) and verifies successful compilation.

## Usage

### Basic Usage

Add this action to your workflow file (`.github/workflows/ci.yml`):

```yaml
name: 42 CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  norminette-and-build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Run Norminette & Build Check
      uses: batuergun/ft_forge@v1
      with:
        project_path: '.'
        makefile_target: 'all'
        strict_mode: 'true'
```

### Advanced Usage

```yaml
name: 42 CI with Matrix

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  check:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        target: [all, bonus]
        
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Run Norminette & Build Check
      uses: batuergun/ft_forge@v1
      with:
        project_path: '.'
        makefile_target: ${{ matrix.target }}
        strict_mode: 'true'
        norminette_flags: '-R CheckForbiddenSourceHeader'
```

### Multiple Projects in One Repository

```yaml
name: Multi-Project CI

on: [push, pull_request]

jobs:
  check-libft:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: batuergun/ft_forge@v1
      with:
        project_path: 'libft'
        
  check-cub3d:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: batuergun/ft_forge@v1
      with:
        project_path: 'cub3d'
        makefile_target: 'all'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `project_path` | Path to the C project directory (relative to repository root) | No | `.` |
| `makefile_target` | Makefile target to build (e.g., `all`, `bonus`) | No | `all` |
| `norminette_flags` | Additional flags to pass to norminette | No | `''` |
| `strict_mode` | Fail the action if norminette finds any violations | No | `true` |
| `build_only` | Only run build check, skip norminette | No | `false` |
| `norminette_only` | Only run norminette, skip build check | No | `false` |
| `with_minilibx` | Enable minilibx support (`auto`=detect automatically, `true`=force enable, `false`=disable) | No | `auto` |

## Outputs

| Output | Description |
|--------|-------------|
| `norminette_status` | Status of norminette check (`passed`/`failed`/`skipped`) |
| `build_status` | Status of build check (`passed`/`failed`/`skipped`) |
| `norminette_violations` | Number of norminette violations found |

## Example Workflows

```yaml
name: Libft CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Check libft
      uses: batuergun/ft_forge@v1
      with:
        project_path: '.'
        makefile_target: 'all'
    - name: Check bonus
      uses: batuergun/ft_forge@v1
      with:
        project_path: '.'
        makefile_target: 'bonus'
```

### Norminette Only (for code review)

```yaml
name: Code Style Check

on: [pull_request]

jobs:
  style-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Check coding style
      uses: batuergun/ft_forge@v1
      with:
        norminette_only: 'true'
        strict_mode: 'true'
```

### Build Only (for testing compilation)

```yaml
name: Build Test

on: [push]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Test build
      uses: batuergun/ft_forge@v1
      with:
        build_only: 'true'
```

## Supported Make Targets

The action automatically detects and works with common 42 School Makefile targets:

- `all` - Default build target
- `bonus` - Bonus part compilation
- `clean` - Clean object files
- `fclean` - Full clean (called automatically before build)
- `re` - Rebuild everything

## Norminette Configuration

The action uses the standard norminette configuration. You can pass additional flags:

```yaml
- uses: batuergun/ft_forge@v1
  with:
    norminette_flags: '-R CheckForbiddenSourceHeader -R CheckDefine'
```

## Error Handling

- **Norminette Violations**: In strict mode (default), any norminette violation will fail the action
- **Build Failures**: Any compilation error will fail the action
- **Missing Files**: If no Makefile is found, the build check will fail
- **No C Files**: If no C files are found, norminette check will be skipped

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/batuergun/ft_forge/issues) page
2. Create a new issue if your problem isn't already reported
3. Provide as much detail as possible, including your workflow file and error messages
