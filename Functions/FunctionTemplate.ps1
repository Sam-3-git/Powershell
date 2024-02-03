# Get OS Info Function
Function Get-WindowsInfo {
    <#
    .DESCRIPTION
        Function to get information about a local or target computer

    .PARAMETER ComputerName
        Target Computer Names. Defaults to Local Host if not passed

    .PARAMETER OutPath
        Error Log location. Defaults to .\SMT.log

    .EXAMPLE
        # To run on remote host
        Get-WindowsInfo -ComputerName RemoteComputer01

    .EXAMPLE
        # To run on remote hosts
        Get-WindowsInfo -ComputerName RemoteComputer01,RemoteComputer02  
        
    .EXAMPLE
        # To specify log location
        Get-WindowsInfo -OutPath "C:\Logs\NewErrorLogLocation.txt"  

    #>
    PARAM(
        [Parameter()]
        [Sttring[]]$ComputerName=(Get-WmiObject -Class Win32_ComputerSystem).Name,
        
        [Parameter()]
        [String]$OutPath="$PSScriptRoot\SMT.log"     
    )

    # Logging Function
    ##################
    Function Write-Log
    {
 
        PARAM(
            [String]$Message,
            [int]$Severity,
            [string]$Component
        )
            $LogPath = $OutPath
            $TimeZoneBias = Get-WMIObject -Query "Select Bias from Win32_TimeZone"
            $Date= Get-Date -Format "HH:mm:ss.fff"
            $Date2= Get-Date -Format "MM-dd-yyyy"
            $Type=1
         
            "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$LogPath" -Append -NoClobber -Encoding default
    }
    ##################
    Write-Log -Message "$env:USERNAME started Function" -Severity 1 -Component "START" # Start Log

}
