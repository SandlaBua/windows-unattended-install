📘 Windows Post-Install Wizard
🚀 Übersicht

Dieses Projekt enthält einen vollautomatisierten Windows Post-Install Wizard, der nach einer Windows-Installation ausgeführt wird und per GUI folgende Aufgaben ermöglicht:

Rechnername festlegen (optional, mit Validierung)

Programmlisten auswählen

Programme automatisch installieren

über winget import

basierend auf JSON-Profilen im Ordner config/

Neustart anbieten, wenn Änderungen vorgenommen wurden

Der Wizard eignet sich perfekt für automatisierte Windows-Setups (z. B. über unattend.xml, Schneegans, $OEM$ oder RunOnce).

📁 Verzeichnisstruktur
windows-postinstall/
├─ README.md
├─ scripts/
│  └─ PostInstall-Wizard.ps1
└─ config/
   ├─ base.json
   ├─ dev.json
   ├─ gaming.json
   └─ office.json

scripts/

Enthält den kompletten GUI-Wizard:

scripts/PostInstall-Wizard.ps1


Dieser lädt Programmlisten aus dem Repository und installiert sie automatisch via winget import.

config/

Alle Programmlisten liegen hier als Winget-Import-JSON.

Beispiele:

base.json — Basissoftware

dev.json — Entwickler-Tools

gaming.json — Gaming-Setup

office.json — Office & Productivity

Du kannst beliebig viele neue Listen hinzufügen.

➕ Neue Programmlisten hinzufügen

Lege eine neue Datei im Ordner config/ an, z. B.:

config/admin.json


Inhalt im Winget-Import-Format:

{
  "Packages": [
    { "PackageIdentifier": "Microsoft.PowerToys" },
    { "PackageIdentifier": "7zip.7zip" }
  ]
}


Im Script in der $Profiles-Liste eintragen:

$Profiles = @(
    [PSCustomObject]@{ Name = 'Admin Tools'; Path = 'config/admin.json' }
)


Fertig — das neue Profil erscheint automatisch als Checkbox im Wizard.

🖥️ Wizard ausführen
Manuell
powershell.exe -ExecutionPolicy Bypass -File "C:\PostInstall\PostInstall-Wizard.ps1"

Automatisch (empfohlen)

in deiner unattend.xml → FirstLogonCommands

oder per SetupComplete.cmd

oder via $OEM$\$1\PostInstall\PostInstall-Wizard.ps1

🔧 Funktionsübersicht
✔ 1. Hostname-GUI

Eingabefeld leer (Benutzer gibt Namen selbst ein)

Aktueller Name wird angezeigt

Validierung:

max. 15 Zeichen

A–Z, 0–9, „-“

Rename-Computer wird ausgeführt

Neuer Name wird nach Neustart aktiv

✔ 2. Programmlisten-GUI

Checkbox-Liste für alle Profile

Mehrfachauswahl möglich

Profile werden aus $Profiles generiert

JSON wird direkt aus GitHub geladen

Installation per:

winget import -i <config.json> --accept-package-agreements --accept-source-agreements

✔ 3. Neustart-Angebot

Wenn:

Rechnername geändert wurde

oder Programme installiert wurden

→ bietet der Wizard einen Neustart an.

⚙ Voraussetzungen

Windows 10 oder 11

Windows PowerShell 5.1

Administratorrechte (werden automatisch angefordert)

Internetverbindung für GitHub

Winget (App Installer)

🔧 Konfiguration im Script

Oben im Script einfach anpassen:

$Title     = "Post-install"
$RepoOwner = "DEINUSER"
$RepoName  = "windows-postinstall"
$Branch    = "main"


Und die Profile:

$Profiles = @(
    [PSCustomObject]@{ Name = 'Base-System'; Path = 'config/base.json' },
    [PSCustomObject]@{ Name = 'Developer';   Path = 'config/dev.json'  },
    [PSCustomObject]@{ Name = 'Gaming';      Path = 'config/gaming.json' },
    [PSCustomObject]@{ Name = 'Office';      Path = 'config/office.json' }
)


Mehr Profile? → Einfach neue Zeile + neue JSON-Datei.

📦 Beispiel-JSON (Winget Import)

config/base.json:

{
  "Packages": [
    { "PackageIdentifier": "Google.Chrome" },
    { "PackageIdentifier": "7zip.7zip" },
    { "PackageIdentifier": "Microsoft.PowerToys" }
  ]
}
