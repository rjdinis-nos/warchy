<#
.SYNOPSIS
    Creates and configures a Arch Linux distribution on Windows 11 Linux Subsystem (WSL2).

.DESCRIPTION
    This script automates the installation and configuration of an Arch Linux WSL2 distribution.
    It supports three installation types: lite (no systemd), default (with systemd), and warchy (enhanced configuration).

.PARAMETER VmName
    The name of the WSL distro to create. This will also be used as the hostname.
    Default: "archbox"

.PARAMETER Username
    The username to create in the WSL distro. This user will have sudo privileges.
    This parameter is mandatory.

.PARAMETER WslBasePath
    The base directory where WSL VMs will be stored. A subdirectory with the distro name will be created here.
    This parameter is mandatory.
    Example: "C:\WSL\VMs"

.PARAMETER VHDSizeGB
    The size of the virtual hard disk in gigabytes.
    Default: 10

.PARAMETER UserPassword
    The password for the created user.
    Default: "changeme"

.PARAMETER OsType
    The type of installation to perform:
    - lite: Lightweight installation without systemd
    - base: Standard installation with systemd enabled
    - warchy: Full installation with systemd and custom Warchy configuration
    Default: "warchy"

.PARAMETER WarchyBranch
    The git branch to use when cloning the Warchy repository. Only applies when OsType is "warchy" and WarchyPath is not specified.
    If not specified, defaults to "main".
    Example: "develop" or "feature-branch"

.PARAMETER WarchyPath
    Local path to Warchy configuration directory in Windows format (just for local testing).
    The path will be automatically converted to WSL format.
    Example: "C:\Projects\warchy" or "C:/Projects/warchy"

.PARAMETER WarchySkipBase
    Skip installation of Warchy base packages. Only applies when OsType is "warchy".
    Useful for faster testing or minimal installations.
    Default: Not set (base packages will be installed)

.PARAMETER WarchySkipOptional
    Skip installation of Warchy optional packages. Only applies when OsType is "warchy".
    Reduces installation time and disk space by skipping AUR and optional packages.
    Default: Not set (optional packages will be installed)

.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/rjdinis-nos/warchy/main/New-ArchWSL.ps1 | iex -Command {& $([ScriptBlock]::Create($input)) -Username "john" -WslBasePath "C:\WSL" -OsType warchy}
    One-liner to download and execute with parameters directly from GitHub, creating a WSL distro with Warchy configuration.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL"
    Creates a default WSL distro with systemd enabled.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -VmName "myarch" -VHDSizeGB 10 -OsType lite
    Creates a lite WSL distro named "myarch" with a 10GB VHD and no systemd.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy
    Creates a WSL distro with Warchy configuration cloned from GitHub (main branch).

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchyBranch "develop"
    Creates a WSL distro with Warchy configuration cloned from the "develop" branch.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchyPath "C:\Projects\warchy"
    Creates a WSL distro with Warchy configuration using local files (just for local testing).

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchySkipOptional
    Creates a WSL distro with Warchy but skips optional packages for faster installation.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchySkipBase -WarchySkipOptional
    Creates a WSL distro with only Warchy configuration (no packages installed).

.NOTES
    Prerequisites:
    - Requires Windows 11 or Windows 10 version 2004 or later with WSL2 enabled
    - The script will configure en_US.UTF-8 locale
    - For warchy type, WarchyPath parameter is required
    - The script will display connection information including wsl cli command to access distro and SSH connection at completion
    
    Recommended Fonts:
    For best visual experience, install a Nerd Font (Cascadia Code NF, JetBrains Mono NF, or Fira Code NF).
    Download from: https://www.nerdfonts.com/
    After installation, configure in Windows Terminal: Settings > Defaults > Appearance > Font face
    
    PowerShell Execution Policy:
    If you encounter execution policy errors, you can change it with one of these commands:
    - Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    - Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
    For more information: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies
    
    Zone.Identifier (Downloaded Files):
    If the script was downloaded from the internet, it may have a Zone.Identifier that blocks execution.
    The script will detect this and offer to unblock it automatically.
    To manually unblock the file, run:
    - Unblock-File -Path .\New-ArchWSL.ps1
    To check if a file has Zone.Identifier:
    - Get-Item -Path .\New-ArchWSL.ps1 -Stream *
#>

# ============================================================================
# MAIN SCRIPT PARAMETERS
# ============================================================================

param (
    [string]$VmName = "archbox",
    [Parameter(Mandatory=$false)]
    [string]$Username,
    [Parameter(Mandatory=$false)]
    [string]$WslBasePath,
    [int]$VHDSizeGB = 10,
    [string]$UserPassword = "changeme",
    [ValidateSet("lite", "base", "warchy")]
    [string]$OsType = "warchy",
	[string]$WarchyBranch = "",
    [string]$WarchyPath = "",
    [switch]$WarchySkipBase,
    [switch]$WarchySkipOptional
)

# ============================================================================
# SHOW HELP IF REQUIRED PARAMETERS ARE MISSING
# ============================================================================

if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($WslBasePath)) {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Arch Linux WSL2 Installation Script" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "`nUSAGE:" -ForegroundColor Yellow
    Write-Host "  .\New-ArchWSL.ps1 -Username <username> -WslBasePath <path> [OPTIONS]`n" -ForegroundColor White
    
    Write-Host "REQUIRED PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Username      The username to create in the WSL distro" -ForegroundColor White
    Write-Host "  -WslBasePath   Base directory for WSL VMs (e.g., C:\WSL\VMs)`n" -ForegroundColor White
    
    Write-Host "OPTIONAL PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -VmName               Name of the distro (default: archbox)" -ForegroundColor White
    Write-Host "  -VHDSizeGB            VHD size in GB (default: 10)" -ForegroundColor White
    Write-Host "  -UserPassword         User password (default: changeme)" -ForegroundColor White
    Write-Host "  -OsType               Installation type: lite, base, warchy (default: warchy)" -ForegroundColor White
    Write-Host "  -WarchyBranch         Git branch for warchy install (default: main)" -ForegroundColor White
    Write-Host "  -WarchyPath           Local path to warchy files (just for local testing)" -ForegroundColor White
    Write-Host "  -WarchySkipBase       Skip warchy base packages installation" -ForegroundColor White
    Write-Host "  -WarchySkipOptional   Skip warchy optional packages installation`n" -ForegroundColor White
    
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  # Basic installation with warchy" -ForegroundColor Gray
    Write-Host "  .\New-ArchWSL.ps1 -Username john -WslBasePath C:\WSL -OsType warchy" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    Write-Host "  # Lite installation (no systemd)" -ForegroundColor Gray
    Write-Host "  .\New-ArchWSL.ps1 -Username john -WslBasePath C:\WSL -OsType lite" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    Write-Host "  # Warchy without optional packages (faster)" -ForegroundColor Gray
    Write-Host "  .\New-ArchWSL.ps1 -Username john -WslBasePath C:\WSL -OsType warchy -WarchySkipOptional" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    Write-Host "  # Warchy configuration only (no packages)" -ForegroundColor Gray
    Write-Host "  .\New-ArchWSL.ps1 -Username john -WslBasePath C:\WSL -OsType warchy -WarchySkipBase -WarchySkipOptional" -ForegroundColor Gray
    Write-Host "" -ForegroundColor Gray
    Write-Host "  # Custom VHD size and distro name" -ForegroundColor Gray
    Write-Host "  .\New-ArchWSL.ps1 -Username john -WslBasePath C:\WSL -VmName myarch -VHDSizeGB 20`n" -ForegroundColor Gray
    
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "  - Windows 11 or Windows 10 version 2004 or later" -ForegroundColor White
    Write-Host "  - WSL2 installed (run: wsl --install)" -ForegroundColor White
    Write-Host "  - PowerShell execution policy allowing script execution`n" -ForegroundColor White
    
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host "  Execution Policy Restricted:" -ForegroundColor White
    Write-Host "    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
    Write-Host "  Or" -ForegroundColor White
    Write-Host "  Downloaded File Blocked (Zone.Identifier):" -ForegroundColor White
    Write-Host "    Unblock-File -Path .\New-ArchWSL.ps1" -ForegroundColor Gray
    Write-Host "    Get-Item -Path .\New-ArchWSL.ps1 -Stream *  # Verify no Zone.Identifier`n" -ForegroundColor Gray
    
    Write-Host "For detailed help, run:" -ForegroundColor Yellow
    Write-Host "  Get-Help .\New-ArchWSL.ps1 -Full`n" -ForegroundColor White
    
    exit 0
}

# ============================================================================
# MAIN SCRIPT CONSTANTS
# ============================================================================

# Packages to install
$PACKAGES = @("sudo", "openssl", "vim", "less", "htop", "curl", "git", "fastfetch")

# Locale configuration
$LOCALE = "en_US.UTF-8"

# WSL Configuration - Read from .wslconfig if it exists
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
$WSL_INIT_TIMEOUT = 120000  # 2 minutes in milliseconds
$WSL_PROCESSORS = 4          # Default fallback
$WSL_MEMORY = "8GB"          # Default fallback
$WSL_SWAP = "0"              # Default fallback

if (Test-Path $wslConfigPath) {
    $wslConfigContent = Get-Content $wslConfigPath -Raw
    
    # Parse processors
    if ($wslConfigContent -match 'processors\s*=\s*(\d+)') {
        $WSL_PROCESSORS = [int]$matches[1]
    }
    
    # Parse memory
    if ($wslConfigContent -match 'memory\s*=\s*([^\r\n]+)') {
        $WSL_MEMORY = $matches[1].Trim()
    }
    
    # Parse swap
    if ($wslConfigContent -match 'swap\s*=\s*([^\r\n]+)') {
        $WSL_SWAP = $matches[1].Trim()
    }
}

# Systemd wait time (seconds)
$SYSTEMD_WAIT_TIME = 2

# WSL shutdown wait time (seconds)
$WSL_SHUTDOWN_WAIT = 3



# ============================================================================
# HELPER FUNCTION: Send-WindowsNotification
# Sends native Windows toast notifications with customizable title, message, and icons
# Supports critical alerts and automatic expiration
# ============================================================================
function Send-WindowsNotification {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Normal", "Critical")]
        [string]$Level = "Normal",
        
        [Parameter(Mandatory=$false)]
        [string]$Status = "",
        
        [Parameter(Mandatory=$false)]
        [int]$ExpireMinutes = 0,
        
        [Parameter(Mandatory=$false)]
        [string]$IconPath = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AppLogo = ""
    )
    
    # Load Windows Runtime assemblies
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]
    }
    catch {
        Write-Error "Failed to load Windows Runtime assemblies: $($_.Exception.Message)"
        return
    }
    
    # Use Windows PowerShell AppID - pre-installed, automation-related
    $AppId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
    
    # Configure notification style based on level
    $buttonStyle = "Success"
    $priority = "Default"
    $scenario = "default"
    
    if ($Level -eq "Critical") {
        $Title = "CRITICAL: $Title"
        $buttonStyle = "Critical"
        $priority = "High"
        $scenario = "reminder"
    }
    
    # Determine icon path
    if ([string]::IsNullOrWhiteSpace($IconPath)) {
        # Default to Windows Security icon
        $IconPath = "C:\Windows\System32\SecurityHealthService.exe"
    } elseif (-not (Test-Path $IconPath)) {
        Write-Warning "Icon path not found: $IconPath. Using default icon."
        $IconPath = "C:\Windows\System32\SecurityHealthService.exe"
    } else {
        # Convert to full path if relative
        $IconPath = (Resolve-Path $IconPath).Path
    }
    
    # Determine app logo path (if provided)
    $AppLogoSrc = ""
    if (-not [string]::IsNullOrWhiteSpace($AppLogo)) {
        if (Test-Path $AppLogo) {
            $AppLogoSrc = "file:///" + (Resolve-Path $AppLogo).Path.Replace("\", "/")
        } else {
            Write-Warning "AppLogo path not found: $AppLogo. Skipping app logo overlay."
        }
    }
    
    # Create base toast XML
    $toastXml = @"
<toast useButtonStyle='true' scenario='$scenario'>
    <visual>
        <binding template='ToastGeneric'>
            <text id='1'></text>
            <text id='2' hint-wrap='true' hint-maxLines='4'></text>
            <image placement='appLogoOverride' src='' />
        </binding>
    </visual>
    <actions>
        <action content='Acknowledge' arguments='dismiss' activationType='background' />
    </actions>
</toast>
"@
    
    # Load XML document
    try {
        $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xmlDoc.LoadXml($toastXml)
    }
    catch {
        Write-Error "Failed to create XML document: $($_.Exception.Message)"
        return
    }
    
    # Safely inject custom values to prevent XML escaping issues
    $xmlDoc.SelectSingleNode("//text[@id='1']").InnerText = $Title
    $xmlDoc.SelectSingleNode("//text[@id='2']").InnerText = $Message
    
    # Set app logo if provided, otherwise use icon
    if (-not [string]::IsNullOrWhiteSpace($AppLogoSrc)) {
        $xmlDoc.SelectSingleNode("//image").SetAttribute("src", $AppLogoSrc)
    } else {
        $xmlDoc.SelectSingleNode("//image").SetAttribute("src", $IconPath)
    }
    
    # Configure button style
    $action = $xmlDoc.SelectSingleNode("//action")
    $action.SetAttribute("hint-buttonStyle", $buttonStyle)
    
    # Add progress bar if status is provided
    if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $progress = $xmlDoc.CreateElement("progress")
        $progress.SetAttribute("status", $Status)
        $progress.SetAttribute("value", "indeterminate")
        $null = $xmlDoc.SelectSingleNode("//binding").AppendChild($progress)
    }
    
    # Create and show notification
    try {
        $toast = New-Object Windows.UI.Notifications.ToastNotification($xmlDoc)
        $toast.Priority = [Windows.UI.Notifications.ToastNotificationPriority]::$priority
        
        if ($ExpireMinutes -gt 0) {
            $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes($ExpireMinutes)
        }
        
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppId)
        $notifier.Show($toast)
        
        Write-Verbose "Notification sent successfully!"
    }
    catch {
        Write-Error "Failed to send notification: $($_.Exception.Message)"
    }
}

# ============================================================================
# HELPER FUNCTION: Write-Section
# Displays a formatted section header with a box border
# ============================================================================
function Write-Section($title) {
    $box = ("=" * ($title.Length + 4))
    Write-Host "`n$box" -ForegroundColor Cyan
    Write-Host "= $title =" -ForegroundColor Cyan
    Write-Host "$box`n" -ForegroundColor Cyan
}

# ============================================================================
# HELPER FUNCTION: Show-FontWarning
# Displays a warning message with instructions when Nerd Fonts are not detected
# ============================================================================
function Show-FontWarning {
    Write-Host "[WARNING] No Nerd Fonts or highly compatible fonts detected!" -ForegroundColor Yellow
    Write-Host "          Some visual elements may not display correctly." -ForegroundColor Yellow
    Write-Host "          Recommended fonts: Cascadia Code NF, JetBrains Mono NF, Fira Code NF" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "          To install Nerd Fonts in Windows:" -ForegroundColor Cyan
    Write-Host "          1. Download from: https://www.nerdfonts.com/" -ForegroundColor White
    Write-Host "          2. Extract the .zip file" -ForegroundColor White
    Write-Host "          3. Right-click on .ttf files > 'Install for all users'" -ForegroundColor White
    Write-Host "          4. Restart Windows Terminal if already open" -ForegroundColor White
    Write-Host ""
    Write-Host "          To configure in Windows Terminal:" -ForegroundColor Cyan
    Write-Host "          1. Open Windows Terminal Settings (Ctrl+,)" -ForegroundColor White
    Write-Host "          2. Go to Defaults > Appearance > Font face" -ForegroundColor White
    Write-Host "          3. Select a Nerd Font (e.g., 'CaskaydiaCove Nerd Font')" -ForegroundColor White
    Write-Host "          Docs: https://learn.microsoft.com/windows/terminal/customize-settings/profile-appearance" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# HELPER FUNCTION: Exit-Script
# Performs cleanup and exits with specified exit code
# Ensures transcript is properly closed to prevent file locks
# ============================================================================
function Exit-Script {
    param(
        [int]$ExitCode = 1
    )
    
    # Stop transcript if running (prevents file locks)
    try {
        Stop-Transcript -ErrorAction Stop | Out-Null
    }
    catch {
        # Transcript not running, continue
    }
    
    # Add other cleanup tasks here as needed in the future
    
    exit $ExitCode
}

# ============================================================================



# ============================================================================
# MAIN LOGIC STARTS HERE
# ============================================================================

# Use VmName as distro name and folder
$InstallPath = Join-Path $WslBasePath $VmName
$IconPath = Join-Path -Path $InstallPath -ChildPath "shortcut.ico"

# Create distro folder (before transcript so log can be written there)
if (-not (Test-Path -Path $InstallPath)) {
    New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
}

# ASCII Art Banner
$ansi_art = @"
  ___  ______  _____  _   _  _     _____ _   _ _   ___   __
 / _ \ | ___ \/  __ \| | | || |   |_   _| \ | | | | \ \ / /
/ /_\ \| |_/ /| /  \/| |_| || |     | | |  \| | | | |\ V / 
|  _  ||    / | |    |  _  || |     | | | . ` | | | |/   \ 
| | | || |\ \ | \__/\| | | || |_____| |_| |\  | |_| / /^\ \
\_| |_/\_| \_| \____/\_| |_/\_____/\___/\_| \_/\___/\/   \/
                                                           
"@

Clear-Host

# Set console encoding to UTF-8 for proper Unicode display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Start transcript logging (after Clear-Host to prevent buffer clearing)
$LogPath = Join-Path $env:TEMP "New-ArchWSL-$VmName-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $LogPath -Append

Write-Host "`n$ansi_art`n" -ForegroundColor Cyan
Write-Host "[LOG] Transcript started: $LogPath`n" -ForegroundColor Gray

# Start timing
$StartTime = Get-Date

# Initialize windows system variables
$osVersion = [System.Environment]::OSVersion.Version
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
$skipExecutionPolicyCheck = $false

# Detect terminal information
$isWindowsTerminal = $env:WT_SESSION -or $env:WT_PROFILE_ID
$terminalType = if ($isWindowsTerminal) { 
    "Windows Terminal" 
} elseif ($env:TERM_PROGRAM) { 
    $env:TERM_PROGRAM 
} elseif ($host.Name -match "ConsoleHost") { 
    "PowerShell Console" 
} else { 
    $host.Name 
}
$consoleWidth = try { $host.UI.RawUI.WindowSize.Width } catch { "Unknown" }
$consoleEncoding = [Console]::OutputEncoding.EncodingName

# Detect installed fonts
$installedFonts = @()
try {
    Add-Type -AssemblyName System.Drawing
    $fontCollection = New-Object System.Drawing.Text.InstalledFontCollection
    $installedFonts = $fontCollection.Families.Name
} catch {
    $installedFonts = @()
}

# Check for common monospace/Nerd Fonts
$commonMonoFonts = @('Cascadia', 'JetBrains', 'Fira', 'Hack', 'Consolas', 'Courier', 'Menlo', 'Monaco', 'Nerd')
$detectedFonts = $installedFonts | Where-Object { 
    $font = $_
    $commonMonoFonts | Where-Object { $font -match $_ }
} | Select-Object -First 5

# Check specifically for Nerd fonts or highly compatible fonts
$nerdFonts = $installedFonts | Where-Object { $_ -match 'Nerd|Cascadia|JetBrains|Fira' }
$hasCompatibleFonts = $nerdFonts.Count -gt 0

if ($detectedFonts) {
    $fontInfo = ($detectedFonts -join ', ')
} else {
    $fontInfo = "Standard fonts"
}

# Display configuration summary
Write-Section "WSL Setup Start"
Write-Host "=== System Information ===" -ForegroundColor Cyan
Write-Host "Start Time    : $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Windows Build : $($osVersion.Build)" -ForegroundColor White
Write-Host "Administrator : " -NoNewline -ForegroundColor White
if ($isAdmin) {
    Write-Host "$($isAdmin)" -ForegroundColor Red
} else {
    Write-Host "$($isAdmin)" -ForegroundColor White
}
if ($skipExecutionPolicyCheck) {
    Write-Host "Exec Policy   : Skipped (file was unblocked)" -ForegroundColor White
} else {
    Write-Host "Exec Policy   : $executionPolicy" -ForegroundColor White
}
Write-Host ""
Write-Host "=== Terminal Information ===" -ForegroundColor Cyan
Write-Host "Type         : " -NoNewline -ForegroundColor White
if ($isWindowsTerminal) {
    Write-Host "$terminalType" -ForegroundColor Green
} else {
    Write-Host "$terminalType" -ForegroundColor Yellow
}
Write-Host "Width        : $consoleWidth columns" -ForegroundColor White
Write-Host "Encoding     : $consoleEncoding" -ForegroundColor White
Write-Host "Mono Fonts   : $fontInfo" -ForegroundColor White

if (-not $isWindowsTerminal) {
    Write-Host "Note         : " -NoNewline -ForegroundColor White
    Write-Host "Windows Terminal recommended for best font support" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "=== Distro Configuration ===" -ForegroundColor Cyan
Write-Host "Distro Name  : $VmName"
Write-Host "Install Path : $InstallPath"
Write-Host "Username     : $Username"
Write-Host "Password     : $UserPassword"
Write-Host "VHD Size     : ${VHDSizeGB}G"
Write-Host "Base Path    : $WslBasePath"
Write-Host "Locale       : $LOCALE"
Write-Host "Packages     : $($PACKAGES -join ', ')"
Write-Host "OS Type      : " -NoNewline
Write-Host "$OsType" -ForegroundColor Cyan
Write-Host ""
Write-Host "=== WSL Configuration ===" -ForegroundColor Cyan
Write-Host "Processors   : " -NoNewLine
Write-Host "$WSL_PROCESSORS (.wslconfig)" -ForegroundColor Yellow
Write-Host "Memory       : " -NoNewLine
Write-Host "$WSL_MEMORY (.wslconfig)" -ForegroundColor Yellow
Write-Host "Swap         : " -NoNewLine
Write-Host "$WSL_SWAP (.wslconfig)" -ForegroundColor Yellow

if ($OsType -eq "warchy" -or (-not [string]::IsNullOrWhiteSpace($WarchyBranch)) -or (-not [string]::IsNullOrWhiteSpace($WarchyPath))) {
    Write-Host ""
    Write-Host "=== Warchy Configuration ===" -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($WarchyPath)) {
        Write-Host "Local Path   : " -NoNewLine
        Write-Host "$WarchyPath" -ForegroundColor Magenta
        Write-Host "Install Mode : " -NoNewLine
        Write-Host "Local testing" -ForegroundColor Magenta
    } else {
        Write-Host "Install Mode : " -NoNewLine
        Write-Host "Git clone" -ForegroundColor Magenta
        
        if (-not [string]::IsNullOrWhiteSpace($WarchyBranch)) {
            Write-Host "Branch       : " -NoNewLine
            Write-Host "$WarchyBranch" -ForegroundColor Magenta
        } else {
            Write-Host "Branch       : " -NoNewLine
            Write-Host "main (default)" -ForegroundColor Magenta
        }
    }
    
    # Display package installation flags
    Write-Host "Base Packages: " -NoNewLine
    if ($WarchySkipBase) {
        Write-Host "Skip" -ForegroundColor Yellow
    } else {
        Write-Host "Install" -ForegroundColor Green
    }
    
    Write-Host "Optional Pkgs: " -NoNewLine
    if ($WarchySkipOptional) {
        Write-Host "Skip" -ForegroundColor Yellow
    } else {
        Write-Host "Install" -ForegroundColor Green
    }
}
Write-Host ""

# ============================================================================
# GUARDS - Pre-installation checks
# ============================================================================

Write-Host "`n[GUARDS] Checking prerequisites..." -ForegroundColor Cyan

# Guard 1: Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "[WARNING] Running as Administrator" -ForegroundColor Yellow
    Write-Host "Running with elevated privileges can be dangerous. If something goes wrong, it may affect your system." -ForegroundColor Yellow
    $response = Read-Host "`nDo you want to continue? (y/n)"
    if ($response -notmatch '^[Yy]') {
        Write-Host "`nExiting. Please restart PowerShell without Administrator privileges.`n" -ForegroundColor Yellow
        Exit-Script
    }
    Write-Host ""
} else {
    Write-Host "[OK] Not running as Administrator" -ForegroundColor Green
}

# Guard 2: Check Zone.Identifier and PowerShell execution policy

$skipExecutionPolicyCheck = $false

# Check if script has Zone.Identifier (downloaded from internet) - offer to unblock but don't exit
if ($PSCommandPath) {
    try {
        $streams = Get-Item -Path $PSCommandPath -Stream * -ErrorAction SilentlyContinue
        $hasZoneIdentifier = $streams | Where-Object { $_.Stream -eq "Zone.Identifier" }
        
        if ($hasZoneIdentifier) {
            Write-Host "[WARNING] This script has a Zone.Identifier (downloaded from internet)" -ForegroundColor Yellow
            Write-Host "The file may be blocked and could cause execution issues." -ForegroundColor Yellow
            $response = Read-Host "`nDo you want to unblock this file? (y/n)"
            if ($response -match '^[Yy]') {
                Unblock-File -Path $PSCommandPath
                Write-Host "[OK] File unblocked successfully" -ForegroundColor Green
                $skipExecutionPolicyCheck = $true
            } else {
                Write-Host "[INFO] File not unblocked. If you encounter issues, run: Unblock-File '$PSCommandPath'" -ForegroundColor Yellow
            }
        }
    }
    catch {
        # Silently continue if we can't check streams
    }
}

# Check execution policy - exit if too restrictive (skip if file was just unblocked)
if (-not $skipExecutionPolicyCheck) {
    $executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
    $allowedPolicies = @("RemoteSigned", "Unrestricted", "Bypass")

    if ($executionPolicy -notin $allowedPolicies) {
        Write-Host "[ERROR] PowerShell script execution is restricted" -ForegroundColor Red
        Write-Host "Current execution policy: $executionPolicy" -ForegroundColor Yellow
        Write-Host "`nTo allow script execution, run one of these commands in PowerShell as Administrator:" -ForegroundColor Yellow
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor White
        Write-Host "  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser" -ForegroundColor White
        Write-Host "`nFor more information, see: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies`n" -ForegroundColor Cyan
        Exit-Script
    }
    Write-Host "[OK] PowerShell execution policy: $executionPolicy" -ForegroundColor Green
} else {
    Write-Host "[OK] Execution policy check skipped (file was unblocked)" -ForegroundColor Green
}

# Guard 3: Check if WSL is installed
try {
    $wslVersion = wsl --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed"
    }
    Write-Host "[OK] WSL is installed" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] WSL is not installed or not accessible" -ForegroundColor Red
    Write-Host "Please install WSL2 by running: wsl --install" -ForegroundColor Yellow
    Write-Host "For more information, visit: https://learn.microsoft.com/en-us/windows/wsl/install`n" -ForegroundColor Cyan
    Exit-Script
}

# Guard 4: Check if running on Windows 11 or Windows 10 with WSL2 support
$osVersion = [System.Environment]::OSVersion.Version
$isWin11OrNewer = $osVersion.Major -ge 10 -and $osVersion.Build -ge 22000
$isWin10WithWSL2 = $osVersion.Major -eq 10 -and $osVersion.Build -ge 19041

if (-not ($isWin11OrNewer -or $isWin10WithWSL2)) {
    Write-Host "[ERROR] This script requires Windows 11 or Windows 10 version 2004 or later" -ForegroundColor Red
    Write-Host "Current Windows version: $($osVersion.Major).$($osVersion.Minor) (Build $($osVersion.Build))" -ForegroundColor Yellow
    Write-Host "Please update Windows to continue`n" -ForegroundColor Yellow
    Exit-Script
}
Write-Host "[OK] Windows version compatible: Build $($osVersion.Build)" -ForegroundColor Green

# Guard 5: Check for Nerd Font compatibility
if (-not $hasCompatibleFonts) {
    Write-Host "" 
    Show-FontWarning
} else {
    Write-Host "[OK] Compatible fonts detected for best visual experience" -ForegroundColor Green
}

Write-Host "[GUARDS] All prerequisite checks passed!`n" -ForegroundColor Green


# ============================================================================
# Parameter Validations
# ============================================================================

$WarchyPathWSL = ""
if (-not [string]::IsNullOrWhiteSpace($WarchyPath)) {
    # Normalize path separators to forward slashes
    $normalizedPath = $WarchyPath -replace '\\', '/'
    
    # Check if it's already in WSL format
    if ($normalizedPath -match '^/mnt/[a-z]/') {
        $WarchyPathWSL = $normalizedPath
    }
    # Check if it's a Windows absolute path (C:/ or C:\)
    elseif ($normalizedPath -match '^([a-zA-Z]):(/|\\)(.*)') {
        $driveLetter = $matches[1].ToLower()
        $pathRemainder = $matches[3]
        $WarchyPathWSL = "/mnt/$driveLetter/$pathRemainder"
    }
    else {
        Write-Host "`n[ERROR] Invalid WarchyPath format: $WarchyPath" -ForegroundColor Red
        Write-Host "Expected format: 'C:\path\to\warchy' or 'C:/path/to/warchy'`n" -ForegroundColor Yellow
        Exit-Script
    }
    
    Write-Host "[INFO] Converted Warchy path: $WarchyPath -> $WarchyPathWSL" -ForegroundColor Cyan
}

# Validate WarchyPath file exists if provided
if (-not [string]::IsNullOrWhiteSpace($WarchyPath)) {
    # Verify install.warchy.sh exists (this implicitly verifies the directory exists too)
    $windowsCheckPath = $WarchyPath -replace '/', '\'
    $installScriptPath = Join-Path $windowsCheckPath "install.warchy.sh"
    
    if (-not (Test-Path -Path $installScriptPath)) {
        Write-Host "`n[ERROR] install.warchy.sh not found at: $installScriptPath" -ForegroundColor Red
        Write-Host "Please ensure the Warchy directory exists with install.warchy.sh inside`n" -ForegroundColor Yellow
        Exit-Script
    }
    
    Write-Host "[OK] install.warchy.sh verified" -ForegroundColor Green
}

# Check if distro already exists
$existingDistros = wsl --list --quiet
if ($existingDistros -contains $VmName) {
    Write-Host "`n[ERROR] A WSL distro named '$VmName' already exists. Aborting to prevent overwrite.`n" -ForegroundColor Red
    Write-Host "To remove the existing distro, run:" -ForegroundColor Yellow
    Write-Host "  wsl --unregister $VmName`n" -ForegroundColor White
    Exit-Script
}

# Ensure base path exists
if (-not (Test-Path -Path $WslBasePath)) {
    Write-Host "`n[INFO] Base path '$WslBasePath' does not exist. Creating..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $WslBasePath | Out-Null
}


# ============================================================================
# Installing Arch Linux
# ============================================================================

Write-Section "Installing Arch Linux"

wsl --install archlinux --name $VmName --location $InstallPath --vhd-size ${VHDSizeGB}G --no-launch
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to install Arch Linux. WSL installation command failed." -ForegroundColor Red
    Write-Host "Please check if WSL2 is properly installed and try again.`n" -ForegroundColor Yellow
    Exit-Script
}

wsl --shutdown

wsl --manage $VmName --set-sparse $true --allow-unsafe
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to configure sparse VHD for '$VmName'" -ForegroundColor Red
    Write-Host "The distro was installed but VHD configuration failed.`n" -ForegroundColor Yellow
    Exit-Script
}

wsl -d $VmName -u root -- bash -c "sed -i 's/^command = /# command = /' /etc/wsl-distribution.conf"
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[WARNING] Failed to modify wsl-distribution.conf" -ForegroundColor Yellow
    Write-Host "This may affect distro behavior but installation will continue.`n" -ForegroundColor Yellow
}

Write-Host "[OK] Arch Linux Installed" -ForegroundColor Green


# ============================================================================
# Configuring Arch Linux
# ============================================================================

Write-Section "Configuring Locale"
wsl -d $VmName --user root -- sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
wsl -d $VmName --user root -- locale-gen
wsl -d $VmName --user root -- localectl set-locale LANG=$LOCALE
Write-Host "[OK] Locale configured ($LOCALE)" -ForegroundColor Green

Write-Section "Updating System & Installing Essentials"
$packageList = $PACKAGES -join ", "
Write-Host "[INFO] Updating system packages and installing: $packageList" -ForegroundColor Yellow
wsl -d $VmName --user root -- pacman -Syu --noconfirm
wsl -d $VmName --user root -- pacman-key --init
wsl -d $VmName --user root -- pacman-key --populate archlinux
wsl -d $VmName --user root -- bash -c "pacman -S $($PACKAGES -join ' ') --noconfirm"

Write-Section "Creating User with Sudo Privileges"
wsl -d $VmName --user root -- bash -c "useradd -m -G wheel $Username && echo '${Username}:${UserPassword}' | chpasswd"
wsl -d $VmName --user root -- bash -c "mkdir -p /etc/sudoers.d && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd && chmod 0440 /etc/sudoers.d/wheel-nopasswd"
Write-Host "[OK] User '$Username' created and sudo configured" -ForegroundColor Green


# ============================================================================
# Configuring wsl.conf and Hostname
# ============================================================================

Write-Section "Configuring wsl.conf and Hostname"

# Determine if systemd should be enabled based on OsType
$enableSystemd = if ($OsType -eq "lite") { "false" } else { "true" }

# Build wsl.conf content (per-distro settings only)
$wslConfContent = @"
[boot]
systemd=$enableSystemd
initTimeout=$WSL_INIT_TIMEOUT

[user]
default=$Username

[automount]
enabled = true
mountFsTab=true
options = "metadata"

[network]
hostname=$VmName

[interop]
enabled=true
appendWindowsPath=true
"@

# Note: [wsl2] settings (processors, memory, swap) belong in .wslconfig, not wsl.conf
# They are read from .wslconfig and displayed for information only

# Create temporary file on Windows side (UTF8 without BOM)
$tempWslConf = [System.IO.Path]::GetTempFileName()
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($tempWslConf, $wslConfContent, $utf8NoBom)

# Convert Windows path to WSL path
$windowsPath = $tempWslConf -replace '\\', '/'
$wslPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(2)

# Copy to WSL
wsl -d $VmName --user root -- cp $wslPath /etc/wsl.conf

# Clean up temp file
Remove-Item $tempWslConf

# Set hostname
wsl -d $VmName --user root -- bash -c "echo '$VmName' > /etc/hostname"

# Update /etc/hosts
wsl -d $VmName --user root -- bash -c "grep -q '127.0.1.1' /etc/hosts && sed -i 's/127.0.1.1.*/127.0.1.1 $VmName/' /etc/hosts || echo '127.0.1.1 $VmName' >> /etc/hosts"

Write-Host "[OK] wsl.conf and hostname configured" -ForegroundColor Green


# ============================================================================
# Configuring .bash_profile
# ============================================================================

Write-Section "Configuring .bash_profile"

# Append user bin directory to PATH
$pathLogic = 'if [ -d \"\$HOME/.local/bin\" ] && [[ \":\$PATH:\" != *\":\$HOME/.local/bin:\"* ]]; then PATH=\"\$HOME/.local/bin:\$PATH\"; fi\n'
wsl -d $VmName --user $Username -- bash -c "echo -e '$pathLogic\n' >> ~/.bash_profile"
Write-Host "[OK] $HOME/.local/bin appended to ~/.bash_profile" -ForegroundColor Green

# Configure WARCHY_LOCAL_TEST environment variable if is set and not empty
if ($OsType -eq "warchy") {
	if (-not [string]::IsNullOrWhiteSpace($WarchyPathWSL)) {
		wsl -d $VmName --user $Username -- bash -c "echo -e 'export WARCHY_LOCAL_TEST=$WarchyPathWSL' >> ~/.bash_profile"
		Write-Host "[OK] WARCHY_LOCAL_TEST appended to ~/.bash_profile" -ForegroundColor Green
	}
}

wsl -d $VmName --user $Username -- bash -c "echo -e 'cd ~' >> ~/.bash_profile"

# Append WARCHY_PATH
#echo "export WARCHY_PATH=\"$WARCHY_PATH\"" >>"$HOME/.bash_profile"

# ============================================================================
# Finalizing Archlinux Setup
# ============================================================================

Write-Section "Finalizing Setup"

# Set default user
wsl --manage $VmName --set-default-user $Username

# Restart WSL to apply wsl.conf changes (especially systemd for default and warchy)
if ($OsType -ne "lite") {
    Write-Host "Shutting down WSL to apply systemd configuration..." -ForegroundColor Yellow
    wsl --shutdown
    Start-Sleep -Seconds $WSL_SHUTDOWN_WAIT

    # Verify systemd is working
    Write-Host "Starting distro and verifying systemd..." -ForegroundColor Yellow
    wsl -d $VmName --user $Username -- bash -c "echo 'Waiting for systemd...' && sleep $SYSTEMD_WAIT_TIME"
    $systemdCheck = wsl -d $VmName --user $Username -- bash -c "systemctl is-system-running 2>/dev/null || echo 'not-running'"

    if ($systemdCheck -match "running|degraded") {
        Write-Host "[OK] Systemd is running" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Systemd may not be running properly" -ForegroundColor Yellow
		Send-WindowsNotification -Title "New-ArchWSL" -Message "Archlinux Systemd may not be running properly" -IconPath $IconPath -Level "Critical"
    }
}

# Verify sudo access
wsl -d $VmName --user $Username -- sudo -l

# Get IP address
Write-Host "Getting IP address..." -ForegroundColor Yellow
$ipAddress = wsl -d $VmName --user $Username -- bash -c "ip addr show eth0 | grep 'inet ' | awk '{print \`$2}' | cut -d/ -f1"
$ipAddress = $ipAddress.Trim()

Send-WindowsNotification -Title "New-ArchWSL" -Message "WSL Archlinux installation complete" -IconPath $IconPath -ExpireMinutes 5


# ============================================================================
# Install Warchy in archlinux (only for warchy OsType)
# ============================================================================

if ($OsType -eq "warchy") {
    Write-Section "Installing Warchy Configuration"
    
	if (-not [string]::IsNullOrWhiteSpace($WarchyPathWSL)) {  
		Write-Host "Validating WARCHY_LOCAL_TEST environment variable..." -ForegroundColor Yellow
		$envCheck = wsl -d $VmName --user $Username -- bash -l -c "echo \`$WARCHY_LOCAL_TEST"
		$envCheck = $envCheck.Trim()
		
		if ([string]::IsNullOrWhiteSpace($envCheck) -or $envCheck -ne $WarchyPathWSL) {
			Write-Host "[ERROR] Failed to set WARCHY_LOCAL_TEST environment variable" -ForegroundColor Red
			Write-Host "Expected: $WarchyPathWSL" -ForegroundColor Yellow
			Write-Host "Got: $envCheck" -ForegroundColor Yellow
			Exit-Script
		}
		
		Write-Host "[OK] WARCHY_LOCAL_TEST verified: $envCheck" -ForegroundColor Green
		Write-Host "[INFO] install.warchy.sh will copy from local directory" -ForegroundColor Cyan
	} else {
		Write-Host "[INFO] No WARCHY_LOCAL_TEST set - install.warchy.sh will clone from git" -ForegroundColor Cyan
	}
    
    # Run Warchy installation script
    Write-Host "Running Warchy installation script..." -ForegroundColor Yellow
    $warchyLogFileWSL = "/tmp/warchy-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    $warchyLogFileWindows = Join-Path $InstallPath "Warchy-Install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    
    # Build environment variables for warchy installation control
    $warchyInstallBase = if ($WarchySkipBase) { "0" } else { "1" }
    $warchyInstallOptional = if ($WarchySkipOptional) { "0" } else { "1" }
    $warchyEnvVars = "WARCHY_INSTALL_BASE=$warchyInstallBase WARCHY_INSTALL_OPTIONAL=$warchyInstallOptional"
    
	if (-not [string]::IsNullOrWhiteSpace($WarchyPathWSL)) {
		Write-Host "Note: install.warchy.sh will copy files from: $WarchyPathWSL" -ForegroundColor Cyan
		wsl -d $VmName --user $Username -- bash -ilc "chmod 744 $WarchyPathWSL/install.warchy.sh"
		wsl -d $VmName --user $Username -- bash -ilc "($warchyEnvVars $WarchyPathWSL/install.warchy.sh) 2>&1 | tee $warchyLogFileWSL; exit \`${PIPESTATUS[0]}"
	} else {
		Write-Host "Note: install.warchy.sh will clone from GitHub repository" -ForegroundColor Cyan
		$branch = if ([string]::IsNullOrWhiteSpace($WarchyBranch)) { "main" } else { $WarchyBranch }
		wsl -d $VmName --user $Username -- bash -ilc "cd ~; (curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/$branch/install.warchy.sh | $warchyEnvVars WARCHY_BRANCH=$branch bash) 2>&1 | tee $warchyLogFileWSL; exit \`${PIPESTATUS[0]}"
	}

	if ($LASTEXITCODE -ne 0) {
		Write-Host "[ERROR] Warchy installation failed" -ForegroundColor Red
        Write-Host "[INFO] Warchy installation log available at: wsl -d $VmName -- cat $warchyLogFileWSL" -ForegroundColor Yellow
		Exit-Script
	}
    
    # Display warchy log content in transcript and copy to Windows
    Write-Host "`n--- Warchy Installation Log ---" -ForegroundColor Cyan
    $warchyLogContent = wsl -d $VmName -- cat $warchyLogFileWSL 2>&1
    $warchyLogContent | Write-Host
    Write-Host "--- End of Warchy Installation Log ---`n" -ForegroundColor Cyan
    
    # Save warchy log to InstallPath alongside PowerShell transcript
    $warchyLogContent | Out-File -FilePath $warchyLogFileWindows -Encoding UTF8
    Write-Host "[LOG] Warchy log saved to: $warchyLogFileWindows" -ForegroundColor Gray
    
    Write-Host "[OK] Warchy configuration completed successfully" -ForegroundColor Green
    
    # Source bash_profile to trigger first-run post-installation tasks
    Write-Host "`nRunning post-installation tasks..." -ForegroundColor Yellow
    wsl -d $VmName --user $Username -- bash -ilc 'true'
    Write-Host "[OK] Post-installation setup initiated" -ForegroundColor Green
}

# Calculate duration
$EndTime = Get-Date
$Duration = $EndTime - $StartTime

# Summary Section
Write-Section "Installation Summary"
Write-Host "Distro Name : $VmName" -ForegroundColor White
Write-Host "Username    : $Username" -ForegroundColor White
Write-Host "Hostname    : $VmName" -ForegroundColor White
Write-Host "IP Address  : $ipAddress" -ForegroundColor White
Write-Host "Install Path: $InstallPath" -ForegroundColor White
Write-Host "VHD Size    : ${VHDSizeGB}G" -ForegroundColor White
Write-Host "OS Type     : $OsType" -ForegroundColor White
if ($OsType -eq "warchy") {
    if (-not [string]::IsNullOrWhiteSpace($WarchyPath)) {
        Write-Host "Warchy Path : $WarchyPath" -ForegroundColor White
        Write-Host "Warchy WSL  : $WarchyPathWSL" -ForegroundColor White
        Write-Host "Install Mode: Local copy" -ForegroundColor White
    } else {
        Write-Host "Install Mode: Git clone" -ForegroundColor White
    }
}

Write-Host "`n[SUCCESS] WSL setup for '$VmName' completed successfully!" -ForegroundColor Green

Write-Host "`nStart Time  : $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "End Time    : $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "Duration    : $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s" -ForegroundColor Yellow

Write-Host "`n$("=" * 50)" -ForegroundColor Cyan
Write-Host "To connect via SSH:" -ForegroundColor Yellow
Write-Host "  ssh ${Username}@${ipAddress}" -ForegroundColor Green
Write-Host "`nTo connect via WSL:" -ForegroundColor Yellow
Write-Host "  wsl -d $VmName" -ForegroundColor Green
Write-Host "$("=" * 50)" -ForegroundColor Cyan

# Stop transcript logging
Stop-Transcript

Write-Host "`n[LOG] Transcript saved: $LogPath" -ForegroundColor Gray

# Copy log to WSL distro
Write-Host "[LOG] Copying log to WSL distro..." -ForegroundColor Gray
$wslLogDir = "~/.local/state/warchy"
$wslLogPath = "$wslLogDir/New-ArchWSL-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Create directory in WSL if it doesn't exist
wsl -d $VmName --user $Username -- bash -c "mkdir -p $wslLogDir"

# Convert Windows log path to WSL format and copy
$windowsLogPath = $LogPath -replace '\\', '/'
$wslTempPath = "/mnt/" + $windowsLogPath.Substring(0,1).ToLower() + $windowsLogPath.Substring(2)
wsl -d $VmName --user $Username -- bash -c "cp '$wslTempPath' '$wslLogPath'"

if ($LASTEXITCODE -eq 0) {
    Write-Host "[LOG] Log copied to WSL: $wslLogPath" -ForegroundColor Gray
} else {
    Write-Host "[WARNING] Failed to copy log to WSL distro" -ForegroundColor Yellow
}
