write-host 'AIB Customization: Downloading FsLogix'
New-Item -Path C:\\ -Name fslogix -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = 'C:\\fslogix'

set-Location $LocalPath

$fsLogixURL="https://aka.ms/fslogix_download"
$installerFile="fslogix_download.zip"


$start_time = Get-Date
$wc = New-Object System.Net.WebClient
$output=$LocalPath+'\'+ $installerFile
$wc.DownloadFile($fsLogixURL, $output)

Write-Output "Time taken to download: $((Get-Date).Subtract($start_time).Seconds) second(s)"


Expand-Archive $LocalPath\$installerFile -DestinationPath $LocalPath -Force -Verbose
write-host 'AIB Customization: Download Fslogix installer finished'

#    FSLogix Install    #
$start_time = Get-Date
Write-Host "Fslogix install process kicked off at $start_time"
Start-Process -FilePath "$LocalPath\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait -Passthru
Write-Output "Time taken to install FsLogix: $((Get-Date).Subtract($start_time).Seconds) second(s)"
write-host 'AIB Customization: Finished Fslogix installer' 
