[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [string]
    $SiteUrl,
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [string]
    $Domain,
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline=$true)]
    [string]
    $ThemeName,
    [Parameter(
        Mandatory=$false,
        ValueFromPipeline=$true)]
    [bool]
    $IsInverted=$false
)

if (-not (Get-Module | Where-Object { $_.Name -eq "PnP.PowerShell" })) {
    Import-Module PnP.PowerShell -DisableNameChecking
}

Connect-PnPOnline "https://$Domain-admin.sharepoint.com/" -UseWebLogin

$jsonObject = Get-Content ".\Theme.json" | ConvertFrom-Json
$themeHash = @{}
$jsonObject.psobject.properties | Foreach { $themeHash[$_.Name] = $_.Value }

Add-PnPTenantTheme -Overwrite -Identity $ThemeName -Palette $themeHash -IsInverted $IsInverted

Set-PnPWebTheme -Theme $ThemeName -WebUrl $SiteUrl
