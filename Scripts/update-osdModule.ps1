<#
.SYNOPSIS
Update the OSD module to the latest version.

.DESCRIPTION
This function updates the OSD module to the latest version. If the module is not installed, it will be installed. If an older version is installed, it will be updated, and the old version will be uninstalled.

.NOTES
Author: Matthew Miles
Created: August 11, 2023
Version: 1.0

.EXAMPLE
Update-OSDModule
# Checks the OSD module, installs if not present, updates if outdated, and uninstalls old versions.
#>

function Update-OSDModule {
    [CmdletBinding()]
    param ()

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Throw "This function requires administrator privileges."
    }

    $ModuleName = "OSD"

    Write-Host "Checking OSD module status..." -ForegroundColor Green

    $IsInstalled = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
    if (-not $IsInstalled) {
        Write-Host "OSD module is not installed. Installing the latest version..." -ForegroundColor Green
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
        Write-Host "OSD module is now installed." -ForegroundColor Green
        return
    }

    $InstalledVersion = $IsInstalled.Version

    $LatestVersion = (Find-Module -Name $ModuleName -AllVersions | Sort-Object Version -Descending)[0].Version

    if ($InstalledVersion -lt $LatestVersion) {
        Write-Host "The installed version of OSD module ($InstalledVersion) is outdated. Updating to the latest version ($LatestVersion)..." -ForegroundColor Green
        Update-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop

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

Update-OSDModule
