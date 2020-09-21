<#
.Synopsis
   Write-Log writes a message to a specified log file with the current time stamp.
.DESCRIPTION
   The Write-Log function is designed to add logging capability to other scripts.
   In addition to writing output and/or verbose you can write to a log file for
   later debugging.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 11/24/2015 09:30:19 AM  

   Changelog:
    * Code simplification and clarification - thanks to @juneb_get_help
    * Added documentation.
    * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks
    * Revised the Force switch to work as it should - thanks to @JeffHicks

   To Do:
    * Add error handling if trying to create a log file in a inaccessible location.
    * Add ability to write $Message to $Verbose or $Error pipelines to eliminate
      duplicates.
.PARAMETER Message
   Message is the content that you wish to add to the log file. 
.PARAMETER Level
   Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational)
.EXAMPLE
   Write-Log -Message 'Log message' 
   Writes the message to c:\Logs\PowerShellLog.log.
.EXAMPLE
   Write-Log -Message 'Restarting Server.' -Path c:\Logs\Scriptoutput.log
   Writes the content to the specified log file and creates the path and file specified.
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0
#>
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('ProcessName')]
        [string]$LogProcess = '',

        [Parameter(Mandatory = $false)]
        [Alias('Exception')]
        [string]$ErrorMessage = '',

        [Parameter(Mandatory = $false)]
        [Alias('LogPath')]
        [string]$Path = 'C:\Logs\PowerShellLog.log',
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info"
    )

    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                $LevelText = 'ERROR'
                $Background = 'Red'
            }
            'Warn' {
                $LevelText = 'WARNING'
                $Background = 'Yellow'
            }
            'Info' {
                $LevelText = 'INFO'
                $Background = 'Blue'
            }
        }
        
        # Write log entry to $Path
        Write-Host -BackgroundColor $Background "$FormattedDate $LogProcess $Message $ErrorMessage"
        "$FormattedDate`t$LevelText`t$LogProcess`t$Message`t$ErrorMessage" | Out-File -FilePath $Global:LOG_PATH -Append
    }
    End {
    }
}

function Start-Log {
    try {
        $Global:LOG_PATH = ""
        $start_datetime =  Get-Date      
        $logName = "LOG_" + $start_datetime.Year + ($start_datetime.Month + 1) + $start_datetime.Day + $start_datetime.Hour + $start_datetime.Minute + $start_datetime.Second + ".log"        
        $logFile = New-Item "$logName" -Force -ItemType File
        $Global:LOG_PATH = $logFile.FullName
        Write-Log -Message "Archivo LOG inicializado" -LogProcess $MyInvocation.MyCommand
    }
    catch {
        Write-Host $_.Exception.Message
        throw "Error al inicializar archivo LOG"
    }    
}

Start-Log