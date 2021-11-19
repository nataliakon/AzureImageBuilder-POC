Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose -Scope Process
# set regKey
 write-host 'AIB Customization: Set required regKey'
 New-Item -Path HKLM:\SOFTWARE\Microsoft -Name "Teams" 
 New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Teams -Name "IsWVDEnvironment" -Type "Dword" -Value "1"
 write-host 'AIB Customization: Finished Set required regKey'
 
 
 # install vc
 write-host 'AIB Customization: Install the latest Microsoft Visual C++ Redistributable'
 $appName = 'teams'
 $drive = 'C:\'
 New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
 $LocalPath = $drive + '\' + $appName 
 set-Location $LocalPath
 $visCplusURL = 'https://aka.ms/vs/16/release/vc_redist.x64.exe'
 $visCplusURLexe = 'vc_redist.x64.exe'
 $outputPath = $LocalPath + '\' + $visCplusURLexe

 $start_time = Get-Date
 $wc = New-Object System.Net.WebClient
 $wc.DownloadFile($visCplusURL, $outputPath)
 
 Write-Output "Time taken to download: $((Get-Date).Subtract($start_time).Seconds) second(s)"

 write-host 'AIB Customization: Starting Install the latest Microsoft Visual C++ Redistributable'
 Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait -Passthru
 write-host 'AIB Customization: Finished Install the latest Microsoft Visual C++ Redistributable'
 
 
 # install webSoc svc
 write-host 'AIB Customization: Install the Teams WebSocket Service'
 $webSocketsURL = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt'
 $webSocketsInstallerMsi = 'webSocketSvc.msi'
 $outputPath = $LocalPath + '\' + $webSocketsInstallerMsi

 $start_time = Get-Date
 $wc1 = New-Object System.Net.WebClient
 $wc1.DownloadFile($webSocketsURL, $outputPath)
 Write-Output "Time taken to download: $((Get-Date).Subtract($start_time).Seconds) second(s)"
 Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log webSocket.log" -Wait -PassThru
 write-host 'AIB Customization: Finished Install the Teams WebSocket Service'
 
 # install Teams
 write-host 'AIB Customization: Install MS Teams'
 $teamsURL = 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&arch=x64&managedInstaller=true&download=true'
 $teamsMsi = 'teams.msi'
 $outputPath = $LocalPath + '\' + $teamsMsi

 $start_time = Get-Date
 $wc2 = New-Object System.Net.WebClient
 $wc2.DownloadFile($teamsURL, $outputPath)
 Write-Output "Time taken to download: $((Get-Date).Subtract($start_time).Seconds) second(s)"
 Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log teams.log ALLUSER=1 ALLUSERS=1" -Wait
 write-host 'AIB Customization: Finished Install MS Teams' 
 