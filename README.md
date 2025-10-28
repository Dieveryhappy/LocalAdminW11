# Windows 11 25H2 - Lokales Konto Setup

PowerShell-Skript zur automatisierten Einrichtung eines lokalen Administrator-Kontos auf Windows 11 25H2 während der Erstinstallation.

## 📋 Beschreibung

Dieses Skript automatisiert die Erstellung eines lokalen Administrator-Kontos auf Windows 11 25H2 und umgeht dabei die Microsoft-Konto-Pflicht. Es führt folgende Aktionen durch:

- ✅ Erstellt ein neues lokales Administrator-Konto
- ✅ Konfiguriert das Konto mit "Passwort läuft nie ab"
- ✅ Deaktiviert das Standard-Administrator-Konto
- ✅ Entfernt temporäre OOBE-Benutzerkonten
- ✅ Passt Registry-Einstellungen für OOBE an
- ✅ Startet das System neu (optional)

## ⚠️ Wichtige Hinweise

> **WARNUNG:** Dieses Skript nimmt systemweite Änderungen vor und erfordert Administrator-Rechte!

- ⚠️ Verwende dieses Skript nur auf frischen Windows 11 Installationen
- ⚠️ Erstelle vor der Ausführung ein Backup wichtiger Daten
- ⚠️ Das Skript ändert Registry-Einstellungen im OOBE-Bereich
- ⚠️ Ein Systemneustart ist nach Ausführung erforderlich

## 🚀 Verwendung

### Methode 1: Während der Windows 11 Installation

1. Drücke während des OOBE-Prozesses `Shift + F10`, um die Eingabeaufforderung zu öffnen
2. Gib `powershell` ein, um PowerShell zu starten
3. Lade das Skript herunter:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/Setup-LocalAccount.ps1" -OutFile "$env:TEMP\Setup-LocalAccount.ps1"
   ```
4. Führe das Skript aus:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   & "$env:TEMP\Setup-LocalAccount.ps1"
   ```

### Methode 2: Nach der Installation

1. Öffne PowerShell **als Administrator**
2. Navigiere zum Verzeichnis mit dem Skript
3. Führe das Skript aus:
   ```powershell
   .\Setup-LocalAccount.ps1
   ```

### Methode 3: Mit benutzerdefiniertem Benutzernamen

```powershell
.\Setup-LocalAccount.ps1 -Username "MeinAdmin"
```

### Methode 4: Ohne automatischen Neustart

```powershell
.\Setup-LocalAccount.ps1 -NoRestart
```

## 📦 Download

### Direkt von GitHub herunterladen

```powershell
# PowerShell-Befehl zum Herunterladen
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DEIN-USERNAME/DEIN-REPO/main/Setup-LocalAccount.ps1" -OutFile "Setup-LocalAccount.ps1"
```

### Oder als ZIP-Datei

1. Klicke auf den grünen Button **"Code"**
2. Wähle **"Download ZIP"**
3. Entpacke die ZIP-Datei
4. Führe `Setup-LocalAccount.ps1` aus

## 🛠️ Voraussetzungen

- **Betriebssystem:** Windows 11 25H2 oder höher
- **PowerShell:** Version 5.1 oder höher
- **Berechtigungen:** Administrator-Rechte erforderlich
- **Execution Policy:** Muss temporär auf `Bypass` oder `RemoteSigned` gesetzt werden

## 📖 Parameter

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `-Username` | String | `"Install"` | Name des zu erstellenden Administrator-Kontos |
| `-NoRestart` | Switch | `$false` | Verhindert den automatischen Neustart nach Abschluss |

### Beispiele

```powershell
# Mit Standard-Benutzername "Install"
.\Setup-LocalAccount.ps1

# Mit benutzerdefiniertem Namen
.\Setup-LocalAccount.ps1 -Username "Admin"

# Ohne Neustart
.\Setup-LocalAccount.ps1 -NoRestart

# Kombination
.\Setup-LocalAccount.ps1 -Username "LocalAdmin" -NoRestart
```

## 🔍 Was macht das Skript im Detail?

### 1. Benutzerverwaltung
- Erstellt neues Benutzerkonto mit selbst gewähltem Passwort
- Fügt Benutzer zur Administrator-Gruppe hinzu
- Aktiviert das Konto
- Setzt Passwort auf "läuft nie ab"
- Deaktiviert Standard-Administrator
- Löscht temporären `defaultUser0` (falls vorhanden)

### 2. Registry-Anpassungen
Bearbeitet folgenden Registry-Pfad:
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE
```

Folgende Werte werden gelöscht:
- `DefaultAccountAction`
- `DefaultAccountSAMName`
- `DefaultAccountSID`

Folgende Werte werden gesetzt:
- `SkipMachineOOBE` = `1` (DWORD)

### 3. Systemabschluss
- Zeigt Zusammenfassung der durchgeführten Änderungen
- Startet System neu (falls nicht deaktiviert)

## 🐛 Fehlerbehebung

### "Skript kann nicht geladen werden" Fehler

**Problem:** PowerShell Execution Policy verhindert Skript-Ausführung

**Lösung:**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### "Administrator-Rechte erforderlich"

**Problem:** Skript wurde ohne Administrator-Rechte gestartet

**Lösung:**
1. Rechtsklick auf PowerShell
2. "Als Administrator ausführen"
3. Skript erneut ausführen

### Registry-Änderungen schlagen fehl

**Problem:** Registry-Pfad existiert nicht oder Zugriff verweigert

**Lösung:**
- Stelle sicher, dass Windows 11 25H2 installiert ist
- Führe das Skript als Administrator aus
- Prüfe, ob der OOBE-Prozess bereits abgeschlossen wurde

## 📝 Manuelle Alternative

Falls das Skript nicht funktioniert, können die Schritte auch manuell durchgeführt werden:

1. Öffne Eingabeaufforderung als Administrator (`Shift + F10` während OOBE)
2. Führe folgende Befehle aus:

```cmd
net user "Install" * /add
net localgroup administrators "Install" /add
net user "Install" /active:yes
net user "Install" /expires:never
net user "Administrator" /active:no
net user "defaultUser0" /delete
```

3. Öffne Registry-Editor:
```cmd
regedit
```

4. Navigiere zu:
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE
```

5. Lösche folgende Werte:
   - `DefaultAccountAction`
   - `DefaultAccountSAMName`
   - `DefaultAccountSID`

6. Benenne `LaunchUserOOBE` zu `SkipMachineOOBE` um und setze Wert auf `1`

7. Starte neu:
```cmd
shutdown /r /t 0
```

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE](LICENSE) Datei für Details.

## 👤 Autor

**Daniel Bollig**

## 🤝 Beiträge

Beiträge, Issues und Feature-Requests sind willkommen!

1. Fork das Projekt
2. Erstelle einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## ⭐ Support

Wenn dir dieses Projekt geholfen hat, gib ihm einen ⭐ auf GitHub!

## 📚 Weitere Ressourcen

- [Microsoft Documentation - Windows OOBE](https://docs.microsoft.com/windows/deployment/oobe/)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Windows 11 Local Account Setup Guide](https://support.microsoft.com/windows)

---

**Haftungsausschluss:** Dieses Skript wird "wie besehen" bereitgestellt. Der Autor übernimmt keine Haftung für eventuelle Schäden oder Datenverluste. Verwende es auf eigene Verantwortung und erstelle immer Backups vor Systemänderungen.
