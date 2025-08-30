# WSL Debian Installation Script

This script automates the installation and configuration of Debian Linux on Windows Subsystem for Linux (WSL).

## Prerequisites

- Windows 10 or Windows 11 with WSL enabled
- PowerShell with administrative privileges

## Usage

1. Run `WSL_Install_Step_1.ps1` to enable WSL features (if not already enabled)
2. Run `WSL_Install_Step_2.ps2` to install and configure Debian
The script does not work on PowerShell Core, so you need to run it via `WSL_Install_Step_2.cmd`

## What the Script Does

1. Uninstalls any existing Debian Appx packages
2. Downloads the latest Debian GNU/Linux package from Microsoft
3. Installs the Debian package
4. Sets up the Debian distribution with a root user
5. Exports the distribution and imports it to a custom location
6. Creates a default user with sudo privileges
7. Configures WSL settings including systemd support
8. Mounts the Windows SSH keys directory to the WSL environment
9. Updates and upgrades all Debian packages
10. Performs a full system upgrade
11. Run Ansible playbook if needed

## Customization

You can modify the following variables in `WSL_Install_Step_2.ps1`:
- `$username` - Default user name
- `$password` - Default user password
- `$WslFolder` - Custom location for WSL distributions
