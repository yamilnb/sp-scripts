. .\Logger.ps1

$ProccesName = "Helper"

function Connect {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SiteUrl,
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $Credentials

    )

    if (-not (Get-Module | Where-Object { $_.Name -eq "SharePointPnPPowerShellOnline" })) {
        Import-Module "SharePointPnPPowerShellOnline" -DisableNameChecking
    }
    
    Write-Log -Message "Connectando con sitio $SiteUrl" -LogProcess $MyInvocation.MyCommand
    try {
        $connection = Get-PnPConnection
        if($connection.Url) {
            Disconnect-PnPOnline
            Connect-PnPOnline $SiteUrl -Credentials $Credentials
        }
    }
    catch {
        Connect-PnPOnline $SiteUrl -Credentials $Credentials
    } finally {
        $connection = Get-PnPConnection
        Write-Log -Message "Conectado con sitio $SiteUrl" -LogProcess $MyInvocation.MyCommand
    }
    return $connection
}

function Add-Folder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    if(-not (Test-Path $Path)) {
        return New-Item $Path -ItemType Directory
    } else {
        return Get-Item $Path
    }
}

function Backup-Files {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $FolderUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Path #current_path\$FolderXML\Backup
    ) 

    try {
        $items = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderUrl
    
        Write-Log -Message "Descargando archivos de $FolderUrl" -LogProcess $MyInvocation.MyCommand
        #current_path\$FolderXML\Backup\$FolderUrl
        $targetFolder = Add-Folder -Path  "$Path\$FolderUrl"
        $files = $items | Where-Object {$_.GetType().Name -eq "File"}
        foreach ($file in $files) {
            $name = $file.Name
            Write-Log -Message "Descargando archivo $name" -LogProcess $MyInvocation.MyCommand
            Get-PnPFile -Url $file.ServerRelativeUrl -Path $targetFolder.FullName -Filename $file.Name -AsFile -Force
            Write-Log -Message "Descargando archivo $name" -LogProcess $MyInvocation.MyCommand
        }
        Write-Log -Message "Archivos descargados en carpeta $FolderUrl" -LogProcess $MyInvocation.MyCommand
    
        Write-Log -Message "Procesando carpetas de $FolderUrl" -LogProcess $MyInvocation.MyCommand
        $folders = $items | Where-Object {$_.GetType().Name -eq "Folder"}
        foreach ($folder in $folders) {
            if($folder.Name -ne "Forms") {                
                $name = $folder.Name
                $relativeFolderPath = "$FolderUrl/$name"                
                Write-Log -Message "Procesando carpeta $name" -LogProcess $MyInvocation.MyCommand
                Backup-Files -FolderUrl $relativeFolderPath -Path $Path
                Write-Log -Message "Carpeta $name procesada" -LogProcess $MyInvocation.MyCommand
            }
        }
        Write-Log -Message "Carpetas creadas en $FolderUrl" -LogProcess $MyInvocation.MyCommand
    } catch {
        $Message = "Error al descargar los archivos"
        Write-Log -Message $Message -LogProcess "Backup-Files" -ErrorMessage $_.Exception.Message -Path $LogPath -Level Error
        Throw $Message
    }
}

function Add-SPFiles {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string] $Path,

        [Parameter(Mandatory=$true)]
        [string] $FolderRelativeUrl
    )

    try {
        Write-Log -Message "Cargando archivos de carpeta $Path" -LogProcess $MyInvocation.MyCommand
        $files = Get-ChildItem -Path $Path -File
        foreach ($file in $files) {
            $name = $file.Name
            Write-Log -Message "Agregando archivo $name en $FolderRelativeUrl" -LogProcess $MyInvocation.MyCommand
            Add-PnPFile -Path $file.FullName -Folder $FolderRelativeUrl
        }
        Write-Log -Message "Archivos cargados en carpeta $Path" -LogProcess $MyInvocation.MyCommand

        $folders = Get-ChildItem -Path $Path -Directory
        foreach ($folder in $folders) {
            $name = $folder.Name
            Add-SPFiles -Path $folder.FullName -FolderRelativeUrl "$FolderRelativeUrl/$name"
        }
        Write-Log -Message "Fin del proceso de carga de archivos en carpeta $FolderRelativeUrl" -LogProcess $MyInvocation.MyCommand
    } catch {
        $Message = "Error al subir los archivos"
        Write-Log -Message $Message -LogProcess $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message -Level Error
        Throw $Message
    }

}

<#
.SYNOPSIS
    Get items from all lists
.DESCRIPTION
    Get-Items loops all lists, non Document Library, and retrieve all list items
.OUTPUTS
    Return a HashTable where keys are the lists and values are an array of items.
    Each row of this array contains a hash of no hidden and no ReadOnly field values
    Example: {"Lista A"=[{"Title"="Item Title","Description"="Description of item"}]}
#>
function Get-Items {
    try {
        Write-Log -Message "Obteniendo elementos de listas" -LogProcess $MyInvocation.MyCommand
        $targetListsItems = @{}
        $soruceLists = Get-PnPList | Where-Object {$_.BaseType -ne "DocumentLibrary" -and -not ($_.Hidden)}
        foreach ($list in $soruceLists) {
            $listTitle = $list.Title
            Write-Log -Message "Procesando lista $listTitle" -LogProcess $MyInvocation.MyCommand
            $fields = Get-PnPField -List $listTitle | Where-Object { -not  $_.Hidden -and -not $_.ReadOnlyField} | Foreach {"$($_.InternalName)"}
            $fields = $fields | Where-Object {$_ -ne "Attachments"}
            $items = Get-PnPListItem -List $listTitle -Fields $fields
            $targetItems = [System.Collections.ArrayList]@()
            foreach ($item in $items) {
                $newItem = @{}
                foreach ($field in $fields) {
                    $value = $item.FieldValues[$field]
                    if ($value -ne $null) {
                        $newItem.Add($field, $value)
                    }
                }
                $out = $targetItems.Add($newItem)
            }
            $targetListsItems.Add($listTitle, $targetItems)
        }
        Write-Log -Message "Copia de elementos finalizada" -LogProcess $MyInvocation.MyCommand
        return $targetListsItems
    } catch {
        $Message = "Error al subir los archivos"
        Write-Log -Message $Message -LogProcess $MyInvocation.MyCommand -ErrorMessage $_.Exception.Messag -Level Error
        Throw $Message
    }
    
}

function Add-ListItems {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        $Data
    )

    try {
        Write-Log -Message "Inicio de copia de elementos" -LogProcess $MyInvocation.MyCommand
        foreach ($list in $Data.Keys) {
            Write-Log -Message "Copiando elementos de $list" -LogProcess $MyInvocation.MyCommand
            $listItems = $Data[$list]
            foreach ($item in $listItems) {
                Add-PnPListItem -List $list -Values $item
            }
            Write-Log -Message "Fin de copia de elementos en $list" -LogProcess $MyInvocation.MyCommand
        }
    } catch {
        $Message = "Error al copiar los elementos"
        Write-Log -Message $Message -LogProcess $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message -Level Error
        Throw $Message
    }
}