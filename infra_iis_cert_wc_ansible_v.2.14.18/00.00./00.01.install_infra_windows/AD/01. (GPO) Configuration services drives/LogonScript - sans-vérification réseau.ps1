<#
Fichier : \\optimedit.eu\NETLOGON\LogonScript.ps1
Configuration GPO : Configuration utilisateur > Parametres Windows > Scripts > Ouverture de session.
Parametres : -ExecutionPolicy Bypass -WindowStyle Hidden
Note : Verifier que le fichier est "Debloque" dans les proprietes du fichier.
#>
# 1. ATTENTE RESEAU (Securite pour les sessions standards/Wi-Fi)
Start-Sleep -Seconds 2

# --- CONFIGURATION OPTIMEDIT.EU ---
$FileServer = "\\OPT.DC01.optimedit.eu"
$LogFile    = "$env:TEMP\LogonDrives.log" # log sur la machine : notepad $env:TEMP\LogonDrives.log
$net        = New-Object -ComObject WScript.Network

# Noms des groupes AD
$GroupAdm = "Gr_RDS_ADM"
$GroupMgt = "Gr_RDS_MGT"

# Fonction pour ecrire les logs
function Write-Log {
    param($Message)
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append
}

# Fonction pour mapper les lecteurs proprement
function Map-Drive($Letter, $Path) {
    $FullPath = $Path.Trim()
    
    # Detachement si la lettre est deja utilisee
    if (Test-Path "$Letter") {
        try { 
            $net.RemoveNetworkDrive("$Letter", $true, $true)
            Start-Sleep -Milliseconds 500 
        } catch { 
            Write-Log "INFO : Impossible de detacher $Letter (Disque local ?)"
        }
    }

    # Tentative de mappage
    try {
        $net.MapNetworkDrive("$Letter", $FullPath)
        Write-Log "SUCCES : $Letter mappe vers $FullPath"
    } catch {
        Write-Log "ERREUR : Echec sur $Letter ($($_.Exception.Message))"
    }
}

Write-Log "--- Debut de session pour : $env:USERNAME ---"

# 2. RECUPERATION DES GROUPES DE L'UTILISATEUR (ADSI)
try {
    $searcher = [ADSISEARCHER]"samaccountname=$($env:USERNAME)"
    $Groups = $searcher.FindOne().Properties.memberof
} catch {
    Write-Log "ERREUR CRITIQUE : Impossible de lire les groupes AD"
}

# 3. MAPPAGES DES LECTEURS

# Lecteur Commun pour tous
Map-Drive -Letter "Y:" -Path "$FileServer\Commun"

# Groupe Direction / Compta (Management)
if ($Groups -like "*CN=$GroupMgt*") {
    Write-Log "Groupe $GroupMgt detecte."
    Map-Drive -Letter "V:" -Path "$FileServer\Direction"
    Map-Drive -Letter "W:" -Path "$FileServer\Compta"
}

# Groupe Admin / Informatique
if ($Groups -like "*CN=$GroupAdm*" -or $Groups -like "*CN=Admins du domaine*") {
    Write-Log "Groupe Admin detecte."
    Map-Drive -Letter "Z:" -Path "$FileServer\IT"
}

Write-Log "--- Fin du script pour $env:USERNAME ---"