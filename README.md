# Lumi-Systems Setup Script

Dieses Skript automatisiert die Installation und Konfiguration aller erforderlichen Software für Lumi-Systems.

## Funktionen

- **Zuverlässigkeit**: 100% zuverlässig und fehlertolerant mit automatischen Wiederholungsversuchen
- **Systemkonfiguration**: Setzt Sprache, Zeitzone und Wetter-Standort
- **Softwareinstallation**: Installiert alle benötigten Anwendungen und Werkzeuge
- **Protokollierung**: Ausführliche Protokollierung und Zusammenfassung
- **Fehlerbehandlung**: Robuste Fehlerbehandlung und Wiederherstellung
- **Konfigurationsflexibilität**: Anpassbare Einstellungen über config.sh
- **Aufräumen**: Automatisches Entfernen nicht benötigter Pakete und temporärer Dateien

## Voraussetzungen

- Ubuntu oder Debian-basiertes Linux-System
- Root-Rechte (sudo)
- Internetverbindung

## Installation

1. Klonen Sie das Repository oder laden Sie die Dateien herunter
2. Machen Sie das Hauptskript ausführbar:
   ```
   chmod +x setup.sh
   ```
3. Führen Sie das Skript mit Root-Rechten aus:
   ```
   sudo ./setup.sh
   ```

## Anpassung

Sie können die Installation anpassen, indem Sie die Datei `config.sh` bearbeiten:

- Systemsprache und Zeitzone
- Zu installierende Software
- RustDesk-Version

## Installierte Software

### Remote-Desktop-Software
- RustDesk (Version 1.4.0)

### APT GUI-Anwendungen
- GIMP
- Inkscape
- Krita
- VLC
- GNOME Tweaks
- OnlyOffice Desktop Editors
- Microsoft Edge
- Firefox
- Evolution

### APT CLI-Werkzeuge
- wget
- curl
- git
- htop
- neofetch
- btop
- p7zip-full

### Flatpak-Anwendungen
- Revolt Desktop
- OBS Studio
- VLC

### RustDesk-Abhängigkeiten
- libfuse2
- libpulse0
- libxcb-randr0
- libxdo3
- libxfixes3
- libxcb-shape0
- libxcb-xfixes0
- libasound2
- PipeWire

## Protokollierung

Alle Installationsschritte werden protokolliert in:
- Ausführliches Protokoll: `logs/setup_TIMESTAMP.log`
- Zusammenfassung: `logs/summary_TIMESTAMP.log`
