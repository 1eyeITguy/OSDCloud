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
    Write-Host "Boot image '$bootImageName' has been removed."
}

# Import the new boot image
$importedBootImage = Import-WdsBootImage -Path $bootImagePath -NewImageName $bootImageName -NewDescription $bootImageDescription -DisplayOrder 1
if ($importedBootImage -ne $null) {
    Write-Host "Boot image '$bootImageName' has been imported."
}
