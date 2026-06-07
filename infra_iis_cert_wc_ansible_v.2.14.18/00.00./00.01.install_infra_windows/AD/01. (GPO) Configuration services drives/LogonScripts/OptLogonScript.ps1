<#
.SYNOPSIS
    Script de mappage reseau universel base sur les droits d'acces.
.DESCRIPTION
    - Attend la stabilisation du reseau (indispensable pour Windows 11/RDS).
    - Verifie la disponibilite du serveur avant de tenter les mappages.
    - Teste l'acces a chaque dossier : si l'utilisateur a le droit, le lecteur est monte.
.NOTES
    AUTHOR: Driss BENELKAID - optimedit.fr@gmail.ocm
    DATE: 28/12/2025
    VERSION: 0.1
#>

# -----------------------------------------------------------------------------
# 1. PARAMETRES GENERIQUES - A ADAPTER POUR AUTRE CLIENT
# -----------------------------------------------------------------------------
$ServerFQDN  = "opt-dc01"
$UNCBase     = "\\$ServerFQDN"
$PathToTest  = "$UNCBase\OPT_Commun" # Dossier utilise pour valider la presence du serveur
$LogFile     = "$env:TEMP\LogonDrives_OptimedIt.log"
$NetworkObj  = New-Object -ComObject WScript.Network

# Liste exhaustive des partages - A ADAPTER POUR AUTRE CLIENT
$DrivesToTest = @(
    @{ Letter = "K:"; Path = "$UNCBase\OPT_Commun" }
    @{ Letter = "T:"; Path = "$UNCBase\OPT_Direction" }
    @{ Letter = "R:"; Path = "$UNCBase\OPT_RH" }
    @{ Letter = "M:"; Path = "$UNCBase\OPT_Compta" }
    @{ Letter = "V:"; Path = "$UNCBase\OPT_Dev" }
    @{ Letter = "W:"; Path = "$UNCBase\OPT_Prod" }
    @{ Letter = "I:"; Path = "$UNCBase\OPT_IT" }
)

# -----------------------------------------------------------------------------
# 2. FONCTIONS DE SUPPORT
# -----------------------------------------------------------------------------
function Write-Log {
    param([string]$Message)
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

# -----------------------------------------------------------------------------
# 3. INITIALISATION ET ATTENTE RESEAU
# -----------------------------------------------------------------------------
# Nettoyage du vieux log pour repartir sur un fichier propre
if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

Write-Log "--- DEBUT DE SESSION : $env:USERNAME ---"
Write-Log "Execution script netlogon : OptLogonScript.ps1"

# Pause initiale pour laisser Windows 11 stabiliser la pile reseau
Write-Log "Stabilisation reseau : Pause de 20 secondes..."
Start-Sleep -Seconds 20

# Boucle de verification intelligente de la disponibilite du service de fichiers
$RetryCount = 0
$MaxRetries = 10

while (!(Test-Path $PathToTest) -and ($RetryCount -lt $MaxRetries)) {
    Write-Log "ATTENTE : Serveur ou partage test invisible (Tentative $($RetryCount + 1)/$MaxRetries)..."
    Start-Sleep -Seconds 5
    $RetryCount++
}

# Arret si le reseau est definitivement indisponible
if (!(Test-Path $PathToTest)) {
    Write-Log "FATAL : Reseau ou serveur injoignable apres $MaxRetries tentatives. Arret."
    # Ouverture du log meme en cas d'echec pour diagnostic
    notepad.exe $LogFile
    exit
}

# -----------------------------------------------------------------------------
# 4. NETTOYAGE ET MAPPAGE BASE SUR LES DROITS REELS
# -----------------------------------------------------------------------------

# Nettoyage global initial
Write-Log "Nettoyage des anciennes connexions reseau..."
net use * /delete /y >$null 2>&1
Start-Sleep -Seconds 2

foreach ($Drive in $DrivesToTest) {
    # On teste si l'utilisateur a reellement acces au dossier
    if (Test-Path $Drive.Path) {
        try {
            # Nettoyage specifique de la lettre avant montage pour eviter les doublons
            $letter = $Drive.Letter
            net use $letter /delete /y >$null 2>&1
            
            # Mappage avec persistance
            $NetworkObj.MapNetworkDrive($Drive.Letter, $Drive.Path, $true)
            Write-Log "SUCCES : $($Drive.Letter) monte sur $($Drive.Path)"
        } catch {
            Write-Log "ERREUR : $($Drive.Letter) ($($_.Exception.Message))"
        }
    } else {
        Write-Log "INFO : Acces non autorise ou dossier inexistant pour $($Drive.Path)"
    }
}

Write-Log "--- FIN DU SCRIPT POUR $env:USERNAME ---"

# -----------------------------------------------------------------------------
# 5. OUVERTURE DU LOG POUR VERIFICATION (A commenter avant mise en GPO)
# -----------------------------------------------------------------------------
notepad.exe $LogFile