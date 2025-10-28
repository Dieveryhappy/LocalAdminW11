#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 25H2 - Lokales Konto Einrichtung
    
.DESCRIPTION
    Dieses Skript richtet ein lokales Administrator-Konto auf Windows 11 25H2 ein
    und konfiguriert Registry-Einstellungen für OOBE (Out-of-Box Experience).
    
.NOTES
    Autor: Daniel Bollig
    Version: 1.0
    Erfordert: Administrator-Rechte
    
.EXAMPLE
    .\Setup-LocalAccount.ps1
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Name des neuen Administrator-Kontos")]
    [string]$Username = "Install",
    
    [Parameter(HelpMessage="Überspringe Neustart am Ende")]
    [switch]$NoRestart
)

# Farben für Output
$SuccessColor = "Green"
$ErrorColor = "Red"
$WarningColor = "Yellow"
$InfoColor = "Cyan"

function Write-Step {
    param([string]$Message)
    Write-Host "`n[INFO] $Message" -ForegroundColor $InfoColor
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor $SuccessColor
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[FEHLER] $Message" -ForegroundColor $ErrorColor
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Host "[WARNUNG] $Message" -ForegroundColor $WarningColor
}

# Banner
Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║   Windows 11 25H2 - Lokales Konto Setup                 ║
║   Version 1.0                                            ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Prüfung: Administrator-Rechte
Write-Step "Überprüfe Administrator-Rechte..."
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ErrorMsg "Dieses Skript muss mit Administrator-Rechten ausgeführt werden!"
    Write-Host "Bitte starte PowerShell als Administrator und führe das Skript erneut aus." -ForegroundColor Yellow
    pause
    exit 1
}
Write-Success "Administrator-Rechte bestätigt"

# Schritt 1: Benutzer erstellen
Write-Step "Erstelle Benutzer '$Username'..."
try {
    # Passwort abfragen
    $SecurePassword = Read-Host "Bitte Passwort für Benutzer '$Username' eingeben" -AsSecureString
    
    # Benutzer erstellen
    net user "$Username" * /add 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Falls interaktive Eingabe fehlschlägt, nutze PowerShell-Methode
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        net user "$Username" "$PlainPassword" /add
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    Write-Success "Benutzer '$Username' erstellt"
} catch {
    Write-ErrorMsg "Fehler beim Erstellen des Benutzers: $_"
    pause
    exit 1
}

# Schritt 2: Zur Administrator-Gruppe hinzufügen
Write-Step "Füge '$Username' zur Administrator-Gruppe hinzu..."
try {
    net localgroup administrators "$Username" /add
    Write-Success "'$Username' ist jetzt Administrator"
} catch {
    Write-ErrorMsg "Fehler beim Hinzufügen zur Administrator-Gruppe: $_"
    pause
    exit 1
}

# Schritt 3: Konto aktivieren
Write-Step "Aktiviere Benutzer '$Username'..."
try {
    net user "$Username" /active:yes
    Write-Success "Benutzer '$Username' aktiviert"
} catch {
    Write-ErrorMsg "Fehler beim Aktivieren des Benutzers: $_"
}

# Schritt 4: Passwort läuft nie ab
Write-Step "Setze Passwort auf 'läuft nie ab'..."
try {
    net user "$Username" /expires:never
    Write-Success "Passwort für '$Username' läuft nie ab"
} catch {
    Write-ErrorMsg "Fehler beim Setzen der Passwort-Richtlinie: $_"
}

# Schritt 5: Standard-Administrator deaktivieren
Write-Step "Deaktiviere Standard-Administrator-Konto..."
try {
    net user "Administrator" /active:no
    Write-Success "Standard-Administrator deaktiviert"
} catch {
    Write-WarningMsg "Konnte Standard-Administrator nicht deaktivieren (möglicherweise nicht vorhanden)"
}

# Schritt 6: defaultUser0 löschen
Write-Step "Lösche temporären Benutzer 'defaultUser0'..."
try {
    net user "defaultUser0" /delete 2>$null
    Write-Success "Benutzer 'defaultUser0' gelöscht"
} catch {
    Write-WarningMsg "Benutzer 'defaultUser0' nicht gefunden (möglicherweise bereits gelöscht)"
}

# Schritt 7: Benutzerliste anzeigen
Write-Step "Aktuelle Benutzerliste:"
net user

# Schritt 8: Registry-Anpassungen
Write-Step "Passe Registry-Einstellungen an (OOBE)..."
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"

try {
    # Prüfe ob Registry-Pfad existiert
    if (-not (Test-Path $RegistryPath)) {
        Write-ErrorMsg "Registry-Pfad existiert nicht: $RegistryPath"
        throw "Registry-Pfad nicht gefunden"
    }
    
    # Lösche die drei Values
    $ValuesToDelete = @("DefaultAccountAction", "DefaultAccountSAMName", "DefaultAccountSID")
    foreach ($Value in $ValuesToDelete) {
        try {
            Remove-ItemProperty -Path $RegistryPath -Name $Value -ErrorAction SilentlyContinue
            Write-Success "Registry-Wert gelöscht: $Value"
        } catch {
            Write-WarningMsg "Registry-Wert '$Value' nicht gefunden (möglicherweise bereits gelöscht)"
        }
    }
    
    # Benenne LaunchUserOOBE zu SkipMachineOOBE um
    Write-Step "Bearbeite OOBE-Einstellungen..."
    try {
        # Prüfe ob LaunchUserOOBE existiert
        $LaunchUserOOBE = Get-ItemProperty -Path $RegistryPath -Name "LaunchUserOOBE" -ErrorAction SilentlyContinue
        if ($LaunchUserOOBE) {
            # Lösche LaunchUserOOBE
            Remove-ItemProperty -Path $RegistryPath -Name "LaunchUserOOBE" -ErrorAction Stop
            Write-Success "LaunchUserOOBE gelöscht"
        }
    } catch {
        Write-WarningMsg "LaunchUserOOBE nicht gefunden"
    }
    
    # Erstelle/Setze SkipMachineOOBE auf 1
    Set-ItemProperty -Path $RegistryPath -Name "SkipMachineOOBE" -Value 1 -Type DWord -ErrorAction Stop
    Write-Success "SkipMachineOOBE auf 1 gesetzt"
    
} catch {
    Write-ErrorMsg "Fehler bei Registry-Anpassungen: $_"
    Write-WarningMsg "Möglicherweise müssen Registry-Änderungen manuell durchgeführt werden"
}

# Zusammenfassung
Write-Host "`n" -NoNewline
Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║   SETUP ABGESCHLOSSEN                                    ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host "`nDurchgeführte Änderungen:" -ForegroundColor Cyan
Write-Host "  ✓ Benutzer '$Username' erstellt und aktiviert" -ForegroundColor Green
Write-Host "  ✓ '$Username' zur Administrator-Gruppe hinzugefügt" -ForegroundColor Green
Write-Host "  ✓ Passwort läuft nie ab" -ForegroundColor Green
Write-Host "  ✓ Standard-Administrator deaktiviert" -ForegroundColor Green
Write-Host "  ✓ Registry-Einstellungen angepasst (OOBE)" -ForegroundColor Green

# Neustart
if (-not $NoRestart) {
    Write-Host "`n" -NoNewline
    Write-WarningMsg "Das System wird in 10 Sekunden neu gestartet..."
    Write-Host "Drücke STRG+C zum Abbrechen" -ForegroundColor Yellow
    
    Start-Sleep -Seconds 10
    
    Write-Step "Starte System neu..."
    shutdown /r /t 0
} else {
    Write-Host "`n" -NoNewline
    Write-WarningMsg "Neustart übersprungen. Bitte starte das System manuell neu, um die Änderungen zu übernehmen."
    Write-Host "Befehl: shutdown /r /t 0" -ForegroundColor Yellow
}

# Verhindere Auto-Close
pause
