
<#
.SYNOPSIS
Automated Deployment Script for OSD Module Update and Configuration.

.DESCRIPTION
This script is designed to facilitate the automated update and configuration of the OSD (Operating System Deployment) module. It ensures that the module is up-to-date, properly configured, and provides a seamless deployment experience. The script handles the installation of the OSD module, updates if necessary, and configures various components related to deployment.

.NOTES
Author: Matthew Miles
Created: August 11, 2023
Version: 1.0

.EXAMPLE
.\create-OSDCloudWinPEImage.ps1
# Prompts the user to check and update the OSD module, then proceeds to configure OSDCloud templates, workspaces, and boot images.
#>

$brand = 'Sight & Sound Theatres'
$wallpaperPath = "E:\SSWallpaper2017_1920x1080.jpg"

function Update-OSDModule {
    [CmdletBinding()]
    param ()

    # Check admin privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Throw "This function requires administrator privileges."
    }

    $ModuleName = "OSD"

    Write-Host "Checking OSD module status..." -ForegroundColor Green

    # Check if OSD module is installed
    $IsInstalled = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $IsInstalled) {
        Write-Host "OSD module is not installed. Installing the latest version..." -ForegroundColor Green
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
        Write-Host "OSD module is now installed." -ForegroundColor Green
        return
    }

    # Get the installed version of OSD module
    $InstalledVersion = $IsInstalled.Version

    # Get the latest version of OSD module
    $LatestVersion = (Find-Module -Name $ModuleName -AllVersions | Sort-Object Version -Descending)[0].Version

    # Check if the installed version is outdated
    if ($InstalledVersion -lt $LatestVersion) {
        Write-Host "The installed version of OSD module ($InstalledVersion) is outdated. Updating to the latest version ($LatestVersion)..." -ForegroundColor Green
        Update-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop

        # Uninstall old versions
        $OldVersions = Get-InstalledModule -Name $ModuleName | Where-Object { $_.Version -ne $LatestVersion }
        foreach ($OldVersion in $OldVersions) {
            Write-Host "Uninstalling old version $($OldVersion.Version) of OSD module..." -ForegroundColor Gray
            Uninstall-Module -Name $ModuleName -Version $OldVersion.Version -Force -ErrorAction SilentlyContinue
        }

        Write-Host "OSD module has been updated to version $LatestVersion. Old versions have been uninstalled." -ForegroundColor Green
    } else {
        Write-Host "OSD module is up to date ($InstalledVersion)." -ForegroundColor Gray
    }
}


function Remove-template_worspace {
    [CmdletBinding()]
    param ()

# Delete the old OSDCloud template and workspace

$directoriesToDelete = @("C:\ProgramData\OSDCloud", "C:\OSDCloud")

foreach ($dir in $directoriesToDelete) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host -ForegroundColor Cyan "Deleting directory: $dir"
        Remove-Item -Path $dir -Recurse -Force
        Write-Host -ForegroundColor DarkGreen "Directory deleted: $dir"
    } else {
        Write-Host -ForegroundColor Yellow "Directory not found: $dir"
    }
}
}



function Update-WDSBootImage {
    # Import the WDS module if not already loaded
    Import-Module WDS

    # Name of the boot image to remove and add
    $bootImageName = "OSDCloud"
    $bootImagePath = "C:\OSDCloud\Media\sources\boot.wim"
    $bootImageDescription = "Updated OSDCloud Boot Image $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Get the boot image to remove
    $existingBootImage = Get-WdsBootImage | Where-Object { $_.ImageName -eq $bootImageName }

    # Remove the existing boot image if found
    if ($existingBootImage -ne $null) {
        Remove-WdsBootImage -ImageName $bootImageName -Architecture x64
        Write-Host -ForegroundColor DarkGray "Boot image '$bootImageName' has been removed."
    }

    # Import the new boot image
    $importedBootImage = Import-WdsBootImage -Path $bootImagePath -NewImageName $bootImageName -NewDescription $bootImageDescription -DisplayOrder 1
    if ($importedBootImage -ne $null) {
        Write-Host -ForegroundColor Cyan "Boot image '$bootImageName' has been imported."
    }    
}


$choice = Read-Host "Would you like to check for and update the OSD module? (y/n/c)"

if ($choice -eq "y" -or $choice -eq "yes") {
    Update-OSDModule
} elseif ($choice -eq "n" -or $choice -eq "no") {
    Write-Host "Continuing with the rest of the script..."
} elseif ($choice -eq "c" -or $choice -eq "cancel") {
    Write-Host "Script execution canceled."
    Exit
} else {
    Write-Host "Invalid choice. Please select 'y'/'yes', 'n'/'no', or 'c'/'cancel'."
}

Remove-template_worspace

# Create new OSDCloud template
New-OSDCloudTemplate

# Create new OSDCloud Workspace
New-OSDCloudWorkspace

# Edit the WinPE image with branding and drivers
Edit-OSDCloudWinPE -StartOSDCloudGUI -Brand $brand -CloudDriver * -Wallpaper $wallpaperPath

Update-WDSBootImage