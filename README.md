

# Linux System Administration Suite

A comprehensive collection of bash scripts for automating common system administration tasks on Linux with a beautiful, interactive dashboard.

![Screenshot_20250331_005223](https://github.com/user-attachments/assets/ef7dc508-0f73-44a1-b21a-692d1aa032e1)


## Features

- **Interactive Dashboard**: Colorful, user-friendly interface with neofetch integration
- **System Updates**: Automatically detect distribution and update packages
- **User Management**: Add, delete, list users and manage groups
- **Security Audit**: Comprehensive system security scan and recommendations
- **Backup System**: Create and manage system backups with easy restore options
- **System Monitoring**: Real-time monitoring of system resources
- **Log Viewer**: Easy access to important system logs

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/linux_admin_suite.git
cd linux_admin_suite
```

2. Make the scripts executable:
```bash
chmod +x *.sh
```

3. Run the dashboard:
```bash
sudo ./sysadmin-dashboard.sh
```

## Requirements

- Bash shell
- Root access (sudo)
- Optional: neofetch (automatically installed if missing)
- Optional: htop (for enhanced system monitoring)

## Script Details

### sysadmin-dashboard.sh
The main interface that brings all tools together in a colorful, easy-to-use menu system with neofetch integration.

### system_update.sh
Detects your Linux distribution and updates system packages using the appropriate package manager (apt, dnf, pacman, zypper).

### user_management.sh
Provides comprehensive user and group management functionality:
- List all system users
- Add new users
- Delete users
- Reset passwords
- Lock/unlock accounts
- Manage groups

### security_audit.sh
Performs a thorough system security audit:
- User account security
- Network configuration
- Filesystem permissions
- Running services
- Security configurations
- Generates recommendations

### backup.sh
Backs up important system files and directories:
- Configurable backup locations
- Backup rotation
- Integrity verification
- Cancellable operations

## Usage

Run the main dashboard and select options from the menu:
```bash
sudo ./sysadmin-dashboard.sh
```

Or run individual scripts directly:
```bash
sudo ./system_update.sh
sudo ./user_management.sh --list
sudo ./security_audit.sh
sudo ./backup.sh
```

## Customization

You can customize the backup locations, exclude patterns, and other settings by editing the variables at the top of each script.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contribution

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## Acknowledgements

- Inspired by neofetch for the system information display
- Thanks to the Linux community for the valuable system administration tools and knowledge

---

**Note**: These scripts require root privileges and should be used with caution. Always review scripts before running them with elevated privileges.
