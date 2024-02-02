<#Manual Update Pull
Sam 06/22
#>
<#Version 7#>

#Restarts update service
Stop-Service wuauserv
Start-Service wuauserv

#Sets Update Requirement
$SearchQuery = "IsAssigned=1 and IsHidden=0 and IsInstalled=0"
#Creates Object
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
$SearchResults = $UpdateSearcher.Search($SearchQuery)

#Checks for updates multiple times
while ($SearchResults.Updates.Count -gt 0 -and $x -lt 4) {
    $x++
    $Downloader = $UpdateSession.CreateUpdateDownloader()
    $Downloader.Updates = $SearchResults.Updates 
    $Downloader.Download()
    $Installer = $UpdateSession.CreateUpdateInstaller()
    $Installer.Updates = $SearchResults.Updates 
    $Results = $Installer.Install()
    $Results.RebootRequired
    $SearchResults = $UpdateSearcher.Search($SearchQuery)
}

#Checks for a required reboot
try {
    Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction Stop
    Write-Host "REBOOT REQUIRED"
}
catch [System.Management.Automation.ItemNotFoundException] { 
    Write-Host "NO REBOOT REQUIRED"
}
