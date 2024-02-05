$LogPref = "$env:TEMP\SMT.log"

# Logging Function
##################
Function Write-Log
{
 
    PARAM(
        [String]$Message,
        [int]$Severity,
        [string]$Component,
        [string]$LogPath=$LogPref
    )
        $ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        $ThreadIdHex = "0x{0:X}" -f $ThreadId
        $ThreadOutput = "$ThreadId($ThreadIdHex)"
        $TimeZoneBias = Get-WMIObject -Query "Select Bias from Win32_TimeZone"
        $Date= Get-Date -Format "HH:mm:ss.fff"
        $Date2= Get-Date -Format "MM-dd-yyyy"
        $Type=1
         
        "<![LOG[$Message]LOG]!><time=$([char]34)$Date$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$Component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$Severity$([char]34) thread=$([char]34)$ThreadOutput$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$LogPath" -Append -NoClobber -Encoding default
}
##################

# Get Windows Info Function
Function Get-WindowsInfo {
    <#
    .DESCRIPTION
        Function to get information about a local or target computer

    .PARAMETER ComputerName
        Target Computer Names. Defaults to Local Host if not passed

    .PARAMETER OutPath
        Error Log location. Defaults to C:\Users\$env:USERNAME\AppData\Local\Temp\SMT.log

    .EXAMPLE
        # To run on remote host
        Get-WindowsInfo -ComputerName RemoteComputer01

    .EXAMPLE
        # To run on remote hosts
        Get-WindowsInfo -ComputerName RemoteComputer01,RemoteComputer02  
        
    .EXAMPLE
        # To specify log location
        Get-WindowsInfo -OutPath "C:\NewErrorLogLocation.txt"  

    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(ValueFromPipeline=$True,
                   HelpMessage="Computer name or IP address")]
        [Alias('hostname')]
        [String[]]$ComputerName=$env:COMPUTERNAME,
        
        [Parameter()]
        [String]$ErrorLog=$LogPref,

        [Parameter()]
        [Switch]$LogErrors 
    )
    BEGIN {
        Write-Verbose "Start BEGIN block"
        Write-Verbose "Error log located at $ErrorLog"
        $ScriptBlock = { # Proper Build Number ScriptBlock SSTART
                $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name UBR).UBR
                return $UBR
            } # Proper Build Number ScriptBlock END
    }
    PROCESS {
        Write-Verbose "Start PROCESS block"
        $ComputerName | ForEach-Object -Begin {
            
            
        } -Process {
            Write-Verbose "HealthCheck on $_"
            # Check to continue process on $_
            $HealthCheck = $True
            try { 
                $OS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $_ -ErrorAction Stop
            }
            catch {
                $ErrorMessage = "$(Get-Date)          ERROR          $ComputerName          $_"
                $HealthCheck = $False
                Write-Warning "$ComputerName query failed with Exception Message:"
                Write-Warning $_.Exception.Message
                if ($LogErrors) {
                    Write-Log -Message "$ComputerName failed with error $_" -Severity 3 -Component "GetWindowsInfo" -LogPath $ErrorLog
                    Write-Log -Message $_ -Severity 3 -Component "GetWindowsInfo" -LogPath $ErrorLog
                    Write-Warning "Error logged to $ErrorLog"
                }
            }
            
            # WMI Calls
            if ($HealthCheck) {
                Write-Verbose "Query WMI on $_"
                $OS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $_
                $BIOS = Get-WmiObject -Class Win32_BIOS -ComputerName $_
                $Version = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $_ 
                Write-Verbose "Querying WMI on $_ COMPLETE"
                # Get admin pass status
                switch ($os.AdminPasswordStatus) {
                    1 {$AdminPass = 'Disabled'}
                    2 {$AdminPass = 'Enabled'}
                    3 {$AdminPass = 'NA'}
                    4 {$AdminPass = 'Unknown'}
                    default {$AdminPass = 'Unknown'}
                }
            
                # Invoke Command for UBR
                Write-Verbose "Querying UBR on $_"
                if ($_ -eq $env:COMPUTERNAME) {
                    $UBR = Invoke-Command -ScriptBlock $ScriptBlock
                }
                else {
                    $UBR = Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $_
                }
                $OSVersion = $Version.Version + '.' + $UBR
                Write-Verbose "Querying UBR on $_ COMPLETE"
            
                # Output Properties
                $Properties = @{
                                'ComputerName'=$env:COMPUTERNAME.Trim();
                                'Domain'=$OS.Domain.Trim();
                                'OSBuild'=$Version.Caption.Trim();
                                'OSBuildNumber'=$OSVersion.Trim();
                                'AdminPass'=$AdminPass.Trim();
                                'Model'=$OS.Model.Trim();
                                'Manufacturer'=$OS.Manufacturer.Trim();
                                'BIOSSerial'=$BIOS.SerialNumber.Trim();
                               }
                $OutputObject = New-Object -TypeName PSObject -Property $Properties
                $OutputObject.PSObject.TypeNames.Insert(0,'SMT.GetWindowsInfo')
                Write-Output $OutputObject
            }
        } -End {
        }
    }
    END {

    }
}
