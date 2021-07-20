<#
.SYNOPSIS

Connect to Site and set PnP Site template

.PARAMETER Url
Site URL
Mandatory

.PARAMETER Path
Path of the XML with the Site template schema
Mandatory

.PARAMETER UseWebLogin
Switch parameter that allows connect to site using Web Login instead of Windows Credentials

.EXAMPLE

PS> .\Apply-Schema.ps1 -Url http://contoso.sharepoint.com/sites/intranet -UseWebLogin
PS> .\Apply-Schema.ps1 -Url http://contoso.sharepoint.com/sites/intranet 

.NOTES

Author: Yamil Braccelarghe
Date:   July 20, 2021
Requires: PnP.PowerShell Module 

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $Url,
    [Parameter(Mandatory=$true)]
    [string]
    $Path,
    [Parameter(Mandatory=$false)]
    [Switch]
    $UseWebLogin
)

if (-not (Get-Module | Where-Object { $_.Name -eq "PnP.PowerShell" })) {
    Import-Module -Name PnP.PowerShell
}

$params = @{
    Url = $Url
    UseWebLogin = $UseWebLogin
}

try {
    $connection = Get-PnPConnection
    if($connection.Url -ne $Url) {
        Disconnect-PnPOnline
        Connect-PnPOnline @params
    }
}
catch {
    Connect-PnPOnline @params
}

Invoke-PnPSiteTemplate -Path $Path