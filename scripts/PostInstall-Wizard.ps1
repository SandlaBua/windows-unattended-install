# PostInstall-Wizard.ps1
# 1) Rechnername setzen (optional)
# 2) Programmlisten auswählen
# 3) Winget-Profile aus GitHub-Repo installieren

# --------------------------
#   KONFIGURATION
# --------------------------
$Title      = "Post-install"
$RepoOwner  = "DEINUSER"          # TODO: GitHub-Benutzer/Org
$RepoName   = "windows-postinstall" # TODO: Repo-Name
$Branch     = "main"              # TODO: Branch (z.B. main/master)

# Definiere deine Profile: Anzeigename + Pfad zur winget-Import-JSON im Repo
$Profiles = @(
    [PSCustomObject]@{ Name = 'Base-System';   Path = 'config/base.json'   },
    [PSCustomObject]@{ Name = 'Developer';     Path = 'config/dev.json'    },
    [PSCustomObject]@{ Name = 'Gaming';        Path = 'config/gaming.json' },
    [PSCustomObject]@{ Name = 'Office';        Path = 'config/office.json' }
)

$ErrorActionPreference = 'Stop'

# --------------------------
#   Admin + STA erzwingen
# --------------------------
$needsRestart = $false

# STA?
if ($host.Runspace.ApartmentState -ne 'STA') {
    $needsRestart = $true
}

# Admin?
$currId    = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currId)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    $needsRestart = $true
}

if ($needsRestart -and $PSCommandPath) {
    $args = "-sta -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe $args -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework

# --------------------------
#   Hilfsfunktionen
# --------------------------

function Show-ComputerNameDialog {
    param(
        [string]$CurrentName
    )

    $window = New-Object System.Windows.Window
    $window.Title = $Title
    $window.Width = 350
    $window.SizeToContent = 'Height'
    $window.WindowStartupLocation = 'CenterScreen'
    $window.Topmost = $true

    $main = New-Object System.Windows.Controls.StackPanel
    $main.Margin = '10'
    $main.Orientation = 'Vertical'
    $window.Content = $main

    # Info-Text
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Neuen Rechnernamen festlegen:"
    $label.Margin = '0,0,0,5'
    $main.Children.Add($label)

    # Aktueller Name nur zur Info
    $currentLabel = New-Object System.Windows.Controls.TextBlock
    $currentLabel.Text = "Aktueller Name: $CurrentName"
    $currentLabel.Margin = '0,0,0,10'
    $currentLabel.FontSize = 11
    $main.Children.Add($currentLabel)

    # Eingabefeld (leer)
    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Margin = '0,0,0,10'
    $tb.Width = 250
    $main.Children.Add($tb)

    # Hinweis
    $hint = New-Object System.Windows.Controls.TextBlock
    $hint.Text = "Nur A–Z, 0–9 und '-' erlaubt, max. 15 Zeichen."
    $hint.FontSize = 10
    $hint.Margin = '0,0,0,10'
    $main.Children.Add($hint)

    # Buttons
    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.HorizontalAlignment = 'Right'
    $main.Children.Add($btnPanel)

    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Width = 70
    $okButton.Margin = '0,0,5,0'
    $btnPanel.Children.Add($okButton)

    $skipButton = New-Object System.Windows.Controls.Button
    $skipButton.Content = "Überspringen"
    $skipButton.Width = 90
    $btnPanel.Children.Add($skipButton)

    # OK-Click
    $okButton.Add_Click({
        $newName = $tb.Text.Trim()

        if ([string]::IsNullOrWhiteSpace($newName)) {
            [System.Windows.MessageBox]::Show(
                "Der Rechnername darf nicht leer sein.",
                "Fehler",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
            return
        }

        if ($newName.Length -gt 15 -or $newName -notmatch '^[A-Za-z0-9\-]+$') {
            [System.Windows.MessageBox]::Show(
                "Ungültiger Rechnername. Nur A–Z, 0–9 und '-' erlaubt, max. 15 Zeichen.",
                "Fehler",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
            return
        }

        $window.Tag = $newName
        $window.DialogResult = $true
        $window.Close()
    })

    # Skip-Click
    $skipButton.Add_Click({
        $window.Tag = $null
        $window.DialogResult = $false
        $window.Close()
    })

    $null = $window.ShowDialog()
    return $window.Tag
}

function Show-ProfileSelector {
    param([array]$Profiles)

    $window = New-Object System.Windows.Window
    $window.Title = $Title
    $window.Width = 260
    $window.SizeToContent = "Height"
    $window.WindowStartupLocation = 'CenterScreen'
    $window.Topmost = $true

    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = 10
    $window.Content = $panel

    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Wähle die Listen aus:"
    $label.Margin = "0,0,0,10"
    $panel.Children.Add($label)

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.Height = 180
    $scroll.VerticalScrollBarVisibility = "Auto"
    $panel.Children.Add($scroll)

    $checkPanel = New-Object System.Windows.Controls.StackPanel
    $scroll.Content = $checkPanel

    foreach ($p in $Profiles) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $p.Name
        $cb.Tag     = $p
        $cb.Margin  = "5,2,5,2"
        $checkPanel.Children.Add($cb)
    }

    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = "Horizontal"
    $btnPanel.HorizontalAlignment = "Right"
    $btnPanel.Margin = "0,10,0,0"
    $panel.Children.Add($btnPanel)

    $okButton = New-Object System.Windows.Controls.Button
    $okButton.Content = "OK"
    $okButton.Width   = 70
    $okButton.Margin  = "0,0,5,0"
    $btnPanel.Children.Add($okButton)

    $cancelButton = New-Object System.Windows.Controls.Button
    $cancelButton.Content = "Abbrechen"
    $cancelButton.Width   = 90
    $btnPanel.Children.Add($cancelButton)

    $okButton.Add_Click({
        $selected = @()
        foreach ($c in $checkPanel.Children) {
            if ($c.IsChecked) { $selected += $c.Tag }
        }

        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show(
                "Bitte mindestens eine Liste auswählen.",
                "Hinweis",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
            return
        }

        $window.Tag = $selected
        $window.DialogResult = $true
        $window.Close()
    })

    $cancelButton.Add_Click({
        $window.DialogResult = $false
        $window.Close()
    })

    $dialog = $window.ShowDialog()
    if ($dialog -ne $true) { return @() }

    return $window.Tag
}

function Show-RestartPrompt {
    param(
        [bool]$NameChanged,
        [bool]$AppsInstalled
    )

    $msg = "Post-Install abgeschlossen."
    if ($NameChanged)   { $msg += "`n- Rechnername wurde geändert (wirksam nach Neustart)." }
    if ($AppsInstalled) { $msg += "`n- Programme wurden installiert." }
    $msg += "`n`nMöchtest du den Rechner jetzt neu starten?"

    $result = [System.Windows.MessageBox]::Show(
        $msg,
        $Title,
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )

    return $result -eq [System.Windows.MessageBoxResult]::Yes
}

# --------------------------
#   Ablauf
# --------------------------

$rawBaseUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"

# 1. Rechnername
$currentName = $env:COMPUTERNAME
$newName     = Show-ComputerNameDialog -CurrentName $currentName
$hostnameChanged = $false

if ($newName -and $newName -ne $currentName) {
    try {
        Rename-Computer -NewName $newName -Force -ErrorAction Stop
        $hostnameChanged = $true
        [System.Windows.MessageBox]::Show(
            "Rechnername wurde auf '$newName' geändert.`nDer neue Name wird nach einem Neustart vollständig aktiv.",
            $Title,
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "Fehler beim Ändern des Rechnernamens:`n$($_.Exception.Message)",
            "Fehler",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

# 2. Winget verfügbar?
$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    [System.Windows.MessageBox]::Show(
        "winget.exe wurde nicht gefunden. Installiere zuerst 'App Installer' aus dem Microsoft Store.",
        "Fehler",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

# 3. Profile auswählen
$selectedProfiles = Show-ProfileSelector -Profiles $Profiles
if ($selectedProfiles.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "Keine Programmlisten ausgewählt. Post-Install wird beendet.",
        $Title,
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
    $appsInstalled = $false
}
else {
    # 4. Installation
    $appsInstalled = $false

    foreach ($profile in $selectedProfiles) {
        $configUrl      = "$rawBaseUrl/$($profile.Path)"
        $tempConfigPath = Join-Path $env:TEMP ("winget_" + ($profile.Name -replace '\s+','_') + ".json")

        try {
            Invoke-WebRequest -Uri $configUrl -OutFile $tempConfigPath -UseBasicParsing
        }
        catch {
            [System.Windows.MessageBox]::Show(
                "Konnte Konfigurationsdatei für Profil '$($profile.Name)' nicht laden:`n$configUrl`n`n$($_.Exception.Message)",
                "Download-Fehler",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
            continue
        }

        # winget import aufrufen
        $arguments = @(
            "import",
            "-i", "`"$tempConfigPath`"",
            "--accept-package-agreements",
            "--accept-source-agreements"
        )

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = $winget.Source
        $psi.Arguments              = $arguments -join ' '
        $psi.UseShellExecute        = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi

        $null   = $proc.Start()
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        # Optional: nur für Debug, kannst du später rauswerfen
        if ($stdout) { Write-Host $stdout }
        if ($stderr) { Write-Host $stderr }

        if ($proc.ExitCode -ne 0) {
            [System.Windows.MessageBox]::Show(
                "Installation für Profil '$($profile.Name)' ist mit ExitCode $($proc.ExitCode) fehlgeschlagen.",
                "Installationsfehler",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
        }
        else {
            $appsInstalled = $true
        }
    }
}

# 5. Neustart anbieten
if (Show-RestartPrompt -NameChanged:$hostnameChanged -AppsInstalled:$appsInstalled) {
    Restart-Computer -Force
}
