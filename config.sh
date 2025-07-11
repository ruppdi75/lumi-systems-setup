#!/bin/bash
#
# Configuration File for Lumi-Systems Setup
# Edit this file to customize the installation
#

# System configuration
SYSTEM_LANGUAGE="de_AT.UTF-8"
SYSTEM_TIMEZONE="Europe/Vienna"
WEATHER_LOCATION="Vienna"

# RustDesk version
RUSTDESK_VERSION="1.4.0"

# Software lists
# APT GUI applications
APT_GUI_APPS=(
    "gimp"
    "inkscape"
    "krita"
    "vlc"
    "gnome-tweaks"
    "onlyoffice-desktopeditors"
    "microsoft-edge-stable"
    "firefox"
    "evolution"
)

# APT CLI tools
APT_CLI_TOOLS=(
    "wget"
    "curl"
    "git"
    "htop"
    "neofetch"
    "btop"
    "p7zip-full"
)

# Flatpak applications
FLATPAK_APPS=(
    "chat.revolt.RevoltDesktop"
    "com.obsproject.Studio"
    "org.videolan.VLC"
)

# RustDesk dependencies
RUSTDESK_DEPENDENCIES=(
    "libfuse2"
    "libpulse0"
    "libxcb-randr0"
    "libxdo3"
    "libxfixes3"
    "libxcb-shape0"
    "libxcb-xfixes0"
    "libasound2t64"
    "pipewire"
)
