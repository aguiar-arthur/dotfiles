# Dotfiles

A robust, extensible dotfiles management system with automated setup pipeline for seamless development environment configuration.

## Features

- **🔄 Idempotent Operations**: Safe to run multiple times without side effects
- **🎯 Modular Architecture**: Easily extensible for new tools and configurations
- **📝 Comprehensive Logging**: Detailed logs for troubleshooting and auditing
- **🛡️ Error Handling**: Graceful failure recovery with clear error reporting
- **🎨 Rich Feedback**: Colored output and progress indicators
- **⚡ Smart Detection**: Automatically detects existing configurations

## 📁 Project Structure

```
dotfiles/
├── pipeline/
│   └── bash_functions.sh     # Reusable utility functions
├── config/
│   ├── editor/               # Editor configuration
│   └── terminal/             # Terminal configuration
├── terminal/
│   └── utils.sh              # Custom shell utilities
│── pipeine.sh                # Main setup script
└── README.md
```

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Run the setup pipeline**:
   ```bash
   ./pipeline.sh
   ```

3. **Apply changes**:
   ```bash
   # Restart your terminal or reload shell configuration
   source ~/.zshrc  # or your shell's config file
   
   # Follow any tool-specific instructions shown in the output
   ```

## 🔧 What Gets Configured

The pipeline automatically configures various development tools and environments:

### Configuration Management
- **Symlinked Configs**: Maintains version control for configuration files
- **Appended Configs**: Safely adds custom configurations to existing files
- **Directory Linking**: Creates clean directory-level symlinks
- **Location**: Primarily in `~/.config/` and home directory

### Development Environment
- **Editor Configuration**: Complete setup for your preferred editor
- **Shell Environment**: Enhanced shell with themes and utilities
- **Terminal Emulator**: Custom terminal configuration and themes
- **Utilities**: Custom shell functions and productivity tools

### Additional Features
- **Theme Management**: Automated theme installation and updates
- **Backup System**: Automatic backup of existing configurations
- **Custom Utilities**: Shell functions for enhanced productivity

## 🛠️ Pipeline Architecture

The setup system is built around three core components:

### 1. Utility Functions (`bash_functions.sh`)

#### `create_symlink(source, target)`
Creates symbolic links with intelligent conflict resolution:
- Validates source file existence
- Handles existing symlinks, files, and directories
- **Idempotent**: Skips if correct symlink already exists
- Creates parent directories as needed

#### `create_directory_symlink(source_dir, target_dir)`
Creates directory-level symbolic links:
- Links entire directories for cleaner organization
- Replaces individual file symlinking approach
- **Idempotent**: Checks existing symlink validity
- Safer than individual file management

#### `append_text_to_file(file, text)`
Safely appends content to configuration files:
- **Idempotent**: Prevents duplicate entries
- Creates automatic backups (`.bak` files)
- Handles file formatting (newlines, spacing)
- Validates file existence before modification

### 2. Main Pipeline (`setup.sh`)

The pipeline follows a structured approach:

```bash
# 1. Environment Setup
- Dependency checking
- Logging initialization
- Path resolution

# 2. Configuration Steps
- Editor setup
- Terminal setup  
- Theme installation

# 3. Reporting
- Success/failure summary
- Next steps guidance
- Log file location
```

### 3. Error Handling & Resilience

- **Strict Mode**: `set -euo pipefail` for robust error detection
- **Graceful Degradation**: Individual step failures don't halt entire process
- **Detailed Logging**: Timestamped logs with color-coded severity levels
- **Dependency Validation**: Pre-flight checks for required tools

## Idempotency

All operations are designed to be **idempotent**, meaning:

- ✅ Safe to run multiple times
- ✅ Only makes changes when necessary
- ✅ Preserves existing correct configurations
- ✅ Provides clear feedback on what was changed vs. skipped

### Example Output:
```bash
[2024-01-15 10:30:45] 1 - Creating symlink for configuration
Symlink already exists and is correct: ~/.config/editor/init.el -> ~/dotfiles/config/editor/init.el
[SUCCESS] Editor configuration symlink created successfully
```

## Extending the Pipeline

The architecture makes it easy to add new tools and configurations:

### Adding a New Tool

1. **Create the function** in `bash_functions.sh` (if needed):
   ```bash
   setup_new_tool() {
       local source_config="$DOTFILES_DIR/config/newtool"
       local target_config="$HOME/.config/newtool"
       
       if create_directory_symlink "$source_config" "$target_config"; then
           success "New tool configured successfully"
       else
           error "Failed to configure new tool"
           return 1
       fi
   }
   ```

2. **Add to main pipeline** in `setup.sh`:
   ```bash
   # In the main() function
   if ! setup_new_tool; then
       failed_steps+=("new-tool")
   fi
   ```

3. **Add configuration files** in appropriate directories:
   ```
   config/newtool/
   ├── config.yaml
   └── themes/
   ```

### Configuration Patterns

The system supports various configuration approaches:

- **Symlink Strategy**: For files you want to keep in version control
- **Append Strategy**: For adding to existing system configurations
- **Template Strategy**: For files that need dynamic content

## Logging & Debugging

### Log Levels
- **🔵 INFO**: General progress information
- **🟢 SUCCESS**: Successful operations
- **🟡 WARNING**: Non-critical issues
- **🔴 ERROR**: Failed operations

### Log File Location
- **Path**: `~/.dotfiles-setup.log`
- **Format**: Timestamped entries with severity levels
- **Retention**: Appends to existing log for history

### Debugging Tips
```bash
# View recent logs
tail -f ~/.dotfiles-setup.log

# Check for errors
grep ERROR ~/.dotfiles-setup.log

# Verbose mode (if needed)
bash -x ./pipeline/setup.sh
```

## Safety Features

### Backup System
- Automatic `.bak` files for modified configurations
- Preserves original files before making changes
- Easy rollback capability

### Validation
- Dependency checking before execution
- File existence validation
- Symlink integrity verification

### Non-Destructive Operations
- Never overwrites without backing up
- Skips operations when targets are already correct
- Clear warnings for potentially destructive actions

## Customization

### Personal Configurations
Edit files in their respective directories:
- `config/editor/` - Editor configurations
- `config/terminal/` - Terminal configurations  
- `terminal/utils.sh` - Custom shell functions

### Pipeline Behavior
Modify variables in `setup.sh`:
```bash
# Custom paths
DOTFILES_DIR="your/custom/path"
LOG_FILE="$HOME/.custom-setup.log"

# Color scheme
RED='\033[0;31m'
GREEN='\033[0;32m'
# ... etc
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-tool`
3. Follow the existing patterns for consistency
4. Test your changes thoroughly
5. Submit a pull request

### Development Guidelines
- All functions should be idempotent
- Include proper error handling
- Add logging for important operations
- Update documentation for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- The open-source community for amazing development tools
- Contributors to various shell frameworks and terminal emulators
- Everyone who shares their dotfiles for inspiration and learning
