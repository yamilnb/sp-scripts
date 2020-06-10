<#
.SYNOPSIS

Build and add SPFx app in App Catalog

.PARAMETER SiteUrl
App Catalog URL

.PARAMETER User
App Catalog admin credentials

.PARAMETER Apps
App Catalog URL

.PARAMETER Path
App Catalog admin credentials

.EXAMPLE

PS> .\Add-App.ps1 -SiteUrl http://contoso.sharepoint.com/sites/AppCatalog -User (Get-Credentials) -Apps App1,App2 -Path C:\Apps

.NOTES

Author: Yamil Braccelarghe
Date:   June 10, 2020 
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $SiteUrl,
    [Parameter(Mandatory=$true)]
    $User,
    [Parameter(Mandatory=$true)]
    [String[]]
    $Apps,
    [Parameter(Mandatory=$true)]
    [string]
    $Path
)

try {
    $connection = Get-PnPConnection
    if($connection.Url -ne $SiteUrl) {
        Disconnect-PnPOnline
        Connect-PnPOnline $SiteUrl -Credentials $User
    }
}
catch {
    Connect-PnPOnline $SiteUrl -Credentials $User
}

try {
    $package_path="sharepoint\solution\"
    
    foreach ($app in $Apps) {
        Write-Host "Adding app $app in App Catalog"
        $path = Resolve-Path "$Path\$app\$package_path"    
        $file = Get-ChildItem -Path $path -File | Select-Object -First 1
        $solution_path = $path + "\" + $file.Name
        Add-PnPApp -Path $solution_path -Overwrite -Publish
        Write-Host "App $app was added successfully" -BackgroundColor Green
    }
} catch {
    throw $_.Exception
}