<#
.SYNOPSIS
    Creates and configures a Arch Linux distribution on Windows 11 Linux Subsystem (WSL2).

.DESCRIPTION
    This script automates the installation and configuration of an Arch Linux WSL2 distribution.
    It supports three installation types: lite (no systemd), default (with systemd), and warchy (enhanced configuration).

.PARAMETER DistroName
    The name of the WSL distro to create. This will also be used as the hostname.
    Default: "warchy"

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
    Default: "base"

.PARAMETER WarchyBranch
    The git branch to use when cloning the Warchy repository. Only applies when OsType is "warchy" and WarchyPath is not specified.
    If not specified, defaults to "main".
    Example: "develop" or "feature-branch"

.PARAMETER WarchyPath
    The path to the Warchy configuration directory in Windows format. This parameter is required when OsType is set to "warchy".
    The path will be automatically converted to WSL format.
    Example: "C:\Projects\warchy" or "C:/Projects/warchy"

.EXAMPLE
    iwr -useb https://raw.githubusercontent.com/rjdinis-nos/warchy/main/New-ArchWSL.ps1 | iex -Command {& $([ScriptBlock]::Create($input)) -Username "john" -WslBasePath "C:\WSL" -OsType warchy}
    One-liner to download and execute with parameters directly from GitHub, creating a WSL distro with Warchy configuration.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL"
    Creates a default WSL distro with systemd enabled.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -DistroName "myarch" -VHDSizeGB 10 -OsType lite
    Creates a lite WSL distro named "myarch" with a 10GB VHD and no systemd.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy
    Creates a WSL distro with Warchy configuration cloned from GitHub (main branch).

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchyBranch "develop"
    Creates a WSL distro with Warchy configuration cloned from the "develop" branch.

.EXAMPLE
    .\New-ArchWSL.ps1 -Username "john" -WslBasePath "C:\WSL" -OsType warchy -WarchyPath "C:\Projects\warchy"
    Creates a WSL distro with Warchy configuration using local files for testing.

.NOTES
    - Requires Windows 11 with WSL2 enabled
    - The script will configure en_US.UTF-8 locale
    - For warchy type, WarchyPath parameter is required
    - The script will display connection information including wsl cli command to access distro and SSH connection at completion
#>

# ============================================================================
# MAIN SCRIPT PARAMETERS
# ============================================================================

param (
    [string]$DistroName = "warchy",
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [Parameter(Mandatory=$true)]
    [string]$WslBasePath,
    [int]$VHDSizeGB = 10,
    [string]$UserPassword = "changeme",
    [ValidateSet("lite", "base", "warchy")]
    [string]$OsType = "base",
	[string]$WarchyBranch = "",
    [string]$WarchyPath = ""
)

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
# HELPER FUNCTION
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
# MAIN LOGIC STARTS HERE
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
        exit 1
    }
    
    Write-Host "[INFO] Converted Warchy path: $WarchyPath -> $WarchyPathWSL" -ForegroundColor Cyan
    
    # Verify install.warchy.sh exists (this implicitly verifies the directory exists too)
    $windowsCheckPath = $WarchyPath -replace '/', '\'
    $installScriptPath = Join-Path $windowsCheckPath "install.warchy.sh"
    
    if (-not (Test-Path -Path $installScriptPath)) {
        Write-Host "`n[ERROR] install.warchy.sh not found at: $installScriptPath" -ForegroundColor Red
        Write-Host "Please ensure the Warchy directory exists with install.warchy.sh inside`n" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "[OK] install.warchy.sh verified" -ForegroundColor Green
}


# ============================================================================

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
Write-Host "`n$ansi_art`n" -ForegroundColor Cyan

# Start timing
$StartTime = Get-Date

function Write-Section($title) {
    $box = ("=" * ($title.Length + 4))
    Write-Host "`n$box" -ForegroundColor Cyan
    Write-Host "= $title =" -ForegroundColor Cyan
    Write-Host "$box`n" -ForegroundColor Cyan
}

# Use DistroName as distro name and folder
$InstallPath = Join-Path $WslBasePath $DistroName
$IconPath = Join-Path -Path $InstallPath -ChildPath "shortcut.ico"

# Check if distro already exists
$existingDistros = wsl --list --quiet
if ($existingDistros -contains $DistroName) {
    Write-Host "`n[ERROR] A WSL distro named '$DistroName' already exists. Aborting to prevent overwrite.`n" -ForegroundColor Red
    Write-Host "To remove the existing distro, run:" -ForegroundColor Yellow
    Write-Host "  wsl --unregister $DistroName`n" -ForegroundColor White
    exit 1
}

# Ensure base path exists
if (-not (Test-Path -Path $WslBasePath)) {
    Write-Host "`n[INFO] Base path '$WslBasePath' does not exist. Creating..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $WslBasePath | Out-Null
}

Write-Section "WSL Setup Start"
Write-Host "Start Time   : $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host "Distro Name  : $DistroName"
Write-Host "Install Path : $InstallPath"
Write-Host "Username     : $Username"
Write-Host "Password     : $UserPassword"
Write-Host "VHD Size     : ${VHDSizeGB}G"
Write-Host "Base Path    : $WslBasePath"
Write-Host "Locale       : $LOCALE"
Write-Host "Packages     : $($PACKAGES -join ', ')"
Write-Host "Processors   : " -NoNewLine
Write-Host "$WSL_PROCESSORS (.wslconfig)" -ForegroundColor Yellow
Write-Host "Memory       : " -NoNewLine
Write-Host "$WSL_MEMORY (.wslconfig)" -ForegroundColor Yellow
Write-Host "Swap         : " -NoNewLine
Write-Host "$WSL_SWAP (.wslconfig)" -ForegroundColor Yellow
Write-Host "OS Type      : " -NoNewline
Write-Host "$OsType" -ForegroundColor Red

if (-not [string]::IsNullOrWhiteSpace($WarchyBranch)) {
    Write-Host "Warchy Branch : " -NoNewLine
	Write-Host "$WarchyBranch" -ForegroundColor Magenta
}
if (-not [string]::IsNullOrWhiteSpace($WarchyPath)) {
    Write-Host "Warchy Path : " -NoNewLine
	Write-Host "$WarchyPath" -ForegroundColor Magenta
    Write-Host "Warchy WSL  : " -NoNewLine
	Write-Host "$WarchyPathWSL" -ForegroundColor Magenta
}

# Create distro folder
#TODO: Remove trailing / from path if exists
Write-Section "Creating WSL VM Directory"
if (Test-Path -Path $InstallPath) {
    Write-Host "[INFO] Directory already exists: $InstallPath" -ForegroundColor Yellow
} else {
    New-Item -ItemType Directory -Force -Path $InstallPath | Out-Null
    Write-Host "[OK] Directory created: $InstallPath" -ForegroundColor Green
}


# ============================================================================
# Installing Arch Linux
# ============================================================================

Write-Section "Installing Arch Linux"

wsl --install archlinux --name $DistroName --location $InstallPath --vhd-size ${VHDSizeGB}G --no-launch
wsl --shutdown
wsl --manage $DistroName --set-sparse $true --allow-unsafe
wsl -d $DistroName -u root -- bash -c "sed -i 's/^command = /# command = /' /etc/wsl-distribution.conf"

Write-Host "[OK] Arch Linux Installed" -ForegroundColor Green

Write-Section "Configuring Locale"
wsl -d $DistroName --user root -- sed -i "s/^#$LOCALE/$LOCALE/" /etc/locale.gen
wsl -d $DistroName --user root -- locale-gen
wsl -d $DistroName --user root -- localectl set-locale LANG=$LOCALE
Write-Host "[OK] Locale configured ($LOCALE)" -ForegroundColor Green

Write-Section "Updating System & Installing Essentials"
$packageList = $PACKAGES -join ", "
Write-Host "[INFO] Updating system packages and installing: $packageList" -ForegroundColor Yellow
wsl -d $DistroName --user root -- pacman -Syu --noconfirm
wsl -d $DistroName --user root -- pacman-key --init
wsl -d $DistroName --user root -- pacman-key --populate archlinux
wsl -d $DistroName --user root -- bash -c "pacman -S $($PACKAGES -join ' ') --noconfirm"

Write-Section "Creating User with Sudo Privileges"
wsl -d $DistroName --user root -- bash -c "useradd -m -G wheel $Username && echo '${Username}:${UserPassword}' | chpasswd"
wsl -d $DistroName --user root -- bash -c "mkdir -p /etc/sudoers.d && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel-nopasswd && chmod 0440 /etc/sudoers.d/wheel-nopasswd"
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
hostname=$DistroName

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
wsl -d $DistroName --user root -- cp $wslPath /etc/wsl.conf

# Clean up temp file
Remove-Item $tempWslConf

# Set hostname
wsl -d $DistroName --user root -- bash -c "echo '$DistroName' > /etc/hostname"

# Update /etc/hosts
wsl -d $DistroName --user root -- bash -c "grep -q '127.0.1.1' /etc/hosts && sed -i 's/127.0.1.1.*/127.0.1.1 $DistroName/' /etc/hosts || echo '127.0.1.1 $DistroName' >> /etc/hosts"

Write-Host "[OK] wsl.conf and hostname configured" -ForegroundColor Green


# ============================================================================
# Configuring .bash_profile
# ============================================================================

Write-Section "Configuring .bash_profile"

# Append user bin directory to PATH
$pathLogic = 'if [ -d \"\$HOME/.local/bin\" ] && [[ \":\$PATH:\" != *\":\$HOME/.local/bin:\"* ]]; then PATH=\"\$HOME/.local/bin:\$PATH\"; fi\n'
wsl -d $DistroName --user $Username -- bash -c "echo -e '$pathLogic\n' >> ~/.bash_profile"
Write-Host "[OK] $HOME/.local/bin appended to ~/.bash_profile" -ForegroundColor Green

wsl -d $DistroName --user $Username -- bash -c "echo -e '\ncd ~\n' >> ~/.bash_profile"

# Configure WARCHY_LOCAL_TEST environment variable if is set and not empty
if ($OsType -eq "warchy") {
	if ([string]::IsNullOrWhiteSpace($WarchyPathWSL)) {
		$branch = if ([string]::IsNullOrWhiteSpace($WarchyBranch)) { "main" } else { $WarchyBranch }
		wsl -d $DistroName --user $Username -- bash -c "echo 'export WARCHY_BRANCH=$branch' >> ~/.bash_profile"
		Write-Host "[OK] WARCHY_BRANCH appended to ~/.bash_profile" -ForegroundColor Green
	} else {
		wsl -d $DistroName --user $Username -- bash -c "echo -e 'export WARCHY_LOCAL_TEST=$WarchyPathWSL' >> ~/.bash_profile"
		Write-Host "[OK] WARCHY_LOCAL_TEST appended to ~/.bash_profile" -ForegroundColor Green
	}
}

# Append WARCHY_PATH
echo "export WARCHY_PATH=\"$WARCHY_PATH\"" >>"$HOME/.bash_profile"

# ============================================================================
# Finalizing Archlinux Setup
# ============================================================================

Write-Section "Finalizing Setup"

# Set default user
wsl --manage $DistroName --set-default-user $Username

# Restart WSL to apply wsl.conf changes (especially systemd for default and warchy)
if ($OsType -ne "lite") {
    Write-Host "Shutting down WSL to apply systemd configuration..." -ForegroundColor Yellow
    wsl --shutdown
    Start-Sleep -Seconds $WSL_SHUTDOWN_WAIT

    # Verify systemd is working
    Write-Host "Starting distro and verifying systemd..." -ForegroundColor Yellow
    wsl -d $DistroName --user $Username -- bash -c "echo 'Waiting for systemd...' && sleep $SYSTEMD_WAIT_TIME"
    $systemdCheck = wsl -d $DistroName --user $Username -- bash -c "systemctl is-system-running 2>/dev/null || echo 'not-running'"

    if ($systemdCheck -match "running|degraded") {
        Write-Host "[OK] Systemd is running" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Systemd may not be running properly" -ForegroundColor Yellow
		Send-WindowsNotification -Title "New-ArchWSL" -Message "Archlinux Systemd may not be running properly" -IconPath $IconPath -Level "Critical"
    }
}

# Verify sudo access
wsl -d $DistroName --user $Username -- sudo -l

# Get IP address
Write-Host "Getting IP address..." -ForegroundColor Yellow
$ipAddress = wsl -d $DistroName --user $Username -- bash -c "ip addr show eth0 | grep 'inet ' | awk '{print \`$2}' | cut -d/ -f1"
$ipAddress = $ipAddress.Trim()

Send-WindowsNotification -Title "New-ArchWSL" -Message "WSL Archlinux installation complete" -IconPath $IconPath -ExpireMinutes 5

# ============================================================================
# Install Warchy in archlinux (only for warchy OsType)
# ============================================================================

if ($OsType -eq "warchy") {
    Write-Section "Installing Warchy Configuration"
    
	if (-not [string]::IsNullOrWhiteSpace($WarchyPathWSL)) {  
		Write-Host "Validating WARCHY_LOCAL_TEST environment variable..." -ForegroundColor Yellow
		$envCheck = wsl -d $DistroName --user $Username -- bash -l -c "echo \`$WARCHY_LOCAL_TEST"
		$envCheck = $envCheck.Trim()
		
		if ([string]::IsNullOrWhiteSpace($envCheck) -or $envCheck -ne $WarchyPathWSL) {
			Write-Host "[ERROR] Failed to set WARCHY_LOCAL_TEST environment variable" -ForegroundColor Red
			Write-Host "Expected: $WarchyPathWSL" -ForegroundColor Yellow
			Write-Host "Got: $envCheck" -ForegroundColor Yellow
			exit 1
		}
		
		Write-Host "[OK] WARCHY_LOCAL_TEST verified: $envCheck" -ForegroundColor Green
		Write-Host "[INFO] install.warchy.sh will copy from local directory" -ForegroundColor Cyan
	} else {
		Write-Host "[INFO] No WARCHY_LOCAL_TEST set - install.warchy.sh will clone from git" -ForegroundColor Cyan
	}
    
    # Run Warchy installation script
    Write-Host "Running Warchy installation script..." -ForegroundColor Yellow
	if (-not [string]::IsNullOrWhiteSpace($WarchyPathWSL)) {
		Write-Host "Note: install.warchy.sh will copy files from: $WarchyPathWSL" -ForegroundColor Cyan
		wsl -d $DistroName --user $Username -- bash -ilc "chmod 744 $WarchyPathWSL/install.warchy.sh"
		wsl -d $DistroName --user $Username -- bash -ilc "$WarchyPathWSL/install.warchy.sh; if [ \`$? -eq 0 ]; then echo 'success'; else echo 'failed'; fi"
	} else {
		Write-Host "Note: install.warchy.sh will clone from GitHub repository" -ForegroundColor Cyan
		$branch = if ([string]::IsNullOrWhiteSpace($WarchyBranch)) { "main" } else { $WarchyBranch }
		wsl -d $DistroName --user $Username -- bash -ilc "cd ~; curl -LsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/$branch/install.warchy.sh | bash; if [ \`$? -eq 0 ]; then echo 'success'; else echo 'failed'; fi"
		
		#$installResult = iwsl -d $DistroName --user $Username -- bash -l -c "cd ~ && curl -fLsSf https://raw.githubusercontent.com/rjdinis-nos/warchy/refs/heads/$branch/install.warchy.sh | bash && echo success || echo failed"
	}

	if ($LASTEXITCODE -ne 0) {
		Write-Host "[ERROR] Warchy installation failed" -ForegroundColor Red
		exit 1
	}
    
    Write-Host "[OK] Warchy configuration completed successfully" -ForegroundColor Green
}

# Calculate duration
$EndTime = Get-Date
$Duration = $EndTime - $StartTime

# Summary Section
Write-Section "Installation Summary"
Write-Host "Distro Name : $DistroName" -ForegroundColor White
Write-Host "Username    : $Username" -ForegroundColor White
Write-Host "Hostname    : $DistroName" -ForegroundColor White
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

Write-Host "`n[SUCCESS] WSL setup for '$DistroName' completed successfully!" -ForegroundColor Green

Write-Host "`nStart Time  : $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "End Time    : $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "Duration    : $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s" -ForegroundColor Yellow

Write-Host "`n$("=" * 50)" -ForegroundColor Cyan
Write-Host "To connect via SSH:" -ForegroundColor Yellow
Write-Host "  ssh ${Username}@${ipAddress}" -ForegroundColor Green
Write-Host "`nTo connect via WSL:" -ForegroundColor Yellow
Write-Host "  wsl -d $DistroName" -ForegroundColor Green
Write-Host "$("=" * 50)" -ForegroundColor Cyan
