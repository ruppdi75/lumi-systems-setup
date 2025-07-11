#!/bin/bash
#
# Software Installation Functions for Lumi-Systems Setup
#

# Function to add Microsoft Edge repository
add_edge_repository() {
    log_message "INFO" "Adding Microsoft Edge repository"
    
    # Download and install the Microsoft signing key
    if wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg; then
        if mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg; then
            log_message "INFO" "Microsoft signing key installed"
        else
            log_message "ERROR" "Failed to install Microsoft signing key"
            return 1
        fi
    else
        log_message "ERROR" "Failed to download Microsoft signing key"
        return 1
    fi
    
    # Add the Edge repository
    if echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list; then
        log_message "INFO" "Microsoft Edge repository added"
        return 0
    else
        log_message "ERROR" "Failed to add Microsoft Edge repository"
        return 1
    fi
}

# Function to add OnlyOffice repository
add_onlyoffice_repository() {
    log_message "INFO" "Adding OnlyOffice repository"
    
    # Download and install the OnlyOffice signing key
    if wget -qO- https://download.onlyoffice.com/repo/onlyoffice.key | gpg --dearmor > onlyoffice.gpg; then
        if mv onlyoffice.gpg /etc/apt/trusted.gpg.d/onlyoffice.gpg; then
            log_message "INFO" "OnlyOffice signing key installed"
        else
            log_message "ERROR" "Failed to install OnlyOffice signing key"
            return 1
        fi
    else
        log_message "ERROR" "Failed to download OnlyOffice signing key"
        return 1
    fi
    
    # Add the OnlyOffice repository
    if echo "deb https://download.onlyoffice.com/repo/debian squeeze main" > /etc/apt/sources.list.d/onlyoffice.list; then
        log_message "INFO" "OnlyOffice repository added"
        return 0
    else
        log_message "ERROR" "Failed to add OnlyOffice repository"
        return 1
    fi
}

# Function to install RustDesk
install_rustdesk() {
    show_progress "rustdesk" "Installing RustDesk $RUSTDESK_VERSION"
    
    log_message "INFO" "Installing RustDesk version $RUSTDESK_VERSION"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    log_message "INFO" "Created temporary directory: $temp_dir"
    
    # Download RustDesk - try multiple URL formats and fallback options
    local architecture=$(dpkg --print-architecture)
    local download_success=false
    
    # Try different URL patterns
    local url_patterns=(
        "https://github.com/rustdesk/rustdesk/releases/download/$RUSTDESK_VERSION/rustdesk-$RUSTDESK_VERSION-$architecture.deb"
        "https://github.com/rustdesk/rustdesk/releases/download/$RUSTDESK_VERSION/rustdesk-$RUSTDESK_VERSION.deb"
        "https://github.com/rustdesk/rustdesk/releases/download/$RUSTDESK_VERSION/rustdesk_$RUSTDESK_VERSION-1_$architecture.deb"
        "https://github.com/rustdesk/rustdesk/releases/download/$RUSTDESK_VERSION/rustdesk_$RUSTDESK_VERSION-1.deb"
    )
    
    for url in "${url_patterns[@]}"; do
        log_message "INFO" "Trying to download RustDesk from: $url"
        if wget --spider -q "$url" 2>/dev/null; then
            log_message "INFO" "Found valid download URL: $url"
            if wget -q "$url" -O "$temp_dir/rustdesk.deb"; then
                log_message "INFO" "RustDesk downloaded successfully from $url"
                download_success=true
                break
            else
                log_message "WARNING" "Download started but failed for: $url"
            fi
        else
            log_message "WARNING" "URL not accessible: $url"
        fi
    done
    
    # If all direct downloads fail, try using apt if a repository is available
    if [ "$download_success" = false ]; then
        log_message "WARNING" "Direct download failed, trying alternative installation methods"
        
        # Try to add RustDesk repository and install via apt
        if command -v add-apt-repository &>/dev/null; then
            log_message "INFO" "Attempting to install RustDesk via package manager"
            
            # Try installing from official repositories first
            if apt-get install -y rustdesk; then
                log_message "INFO" "RustDesk installed successfully from repositories"
                SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
                rm -rf "$temp_dir"
                return 0
            else
                log_message "WARNING" "RustDesk not available in standard repositories"
            fi
        fi
        
        # If we get here, all download attempts failed
        log_message "ERROR" "All download attempts for RustDesk failed"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Install RustDesk
    log_message "INFO" "Installing RustDesk package"
    if dpkg -i "$temp_dir/rustdesk.deb"; then
        log_message "INFO" "RustDesk installed successfully"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
    else
        log_message "ERROR" "Failed to install RustDesk package"
        # Try to fix dependencies and retry
        log_message "INFO" "Attempting to fix dependencies and retry installation"
        apt-get -f install -y
        if dpkg -i "$temp_dir/rustdesk.deb"; then
            log_message "INFO" "RustDesk installed successfully after fixing dependencies"
            SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        else
            log_message "ERROR" "Failed to install RustDesk package after fixing dependencies"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    log_message "INFO" "Temporary directory removed"
    
    return 0
}

# Function to install a single APT package
install_apt_package() {
    local package="$1"
    
    log_message "INFO" "Installing package: $package"
    
    # First try normal installation
    if apt-get install -y "$package"; then
        log_message "INFO" "Package installed successfully: $package"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        return 0
    else
        # Check if it's a virtual package
        local apt_cache_output=$(apt-cache policy "$package" 2>&1)
        
        if echo "$apt_cache_output" | grep -q "is a virtual package"; then
            log_message "WARNING" "$package is a virtual package. Attempting to find a suitable provider."
            
            # Try to extract the first provider
            local provider=$(echo "$apt_cache_output" | grep -oP '\s+\K[^\s]+(?=\s+[0-9])' | head -1)
            
            if [ -n "$provider" ]; then
                log_message "INFO" "Trying to install $provider as a replacement for $package"
                
                if apt-get install -y "$provider"; then
                    log_message "SUCCESS" "Successfully installed $provider as a replacement for $package"
                    SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
                    return 0
                else
                    log_message "ERROR" "Failed to install $provider as a replacement for $package"
                fi
            else
                log_message "ERROR" "Could not determine a provider for virtual package $package"
            fi
        fi
        
        log_message "ERROR" "Failed to install package: $package"
        return 1
    fi
}

# Function to install APT GUI applications
install_apt_gui_apps() {
    log_message "INFO" "Installing APT GUI applications"
    
    # Configure debconf to automatically accept license agreements and prompts
    log_message "INFO" "Configuring automatic acceptance for package installations"
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true" | debconf-set-selections
    echo "msttcorefonts msttcorefonts/accepted-mscorefonts-eula boolean true" | debconf-set-selections
    export DEBIAN_FRONTEND=noninteractive
    
    # Add repositories for special packages
    add_edge_repository
    add_onlyoffice_repository
    
    # Update package lists after adding repositories
    update_package_lists
    
    # Install each GUI application
    for app in "${APT_GUI_APPS[@]}"; do
        show_progress "apt_gui_$app" "Installing $app"
        if ! install_apt_package "$app"; then
            handle_error "Failed to install $app" "install_apt_package $app"
        fi
    done
    
    # Reset DEBIAN_FRONTEND
    export DEBIAN_FRONTEND=dialog
    
    log_message "INFO" "APT GUI applications installation completed"
}

# Function to install APT CLI tools
install_apt_cli_tools() {
    log_message "INFO" "Installing APT CLI tools"
    
    # Install each CLI tool
    for tool in "${APT_CLI_TOOLS[@]}"; do
        show_progress "apt_cli_$tool" "Installing $tool"
        if ! install_apt_package "$tool"; then
            handle_error "Failed to install $tool" "install_apt_package $tool"
        fi
    done
    
    log_message "INFO" "APT CLI tools installation completed"
}

# Function to install RustDesk dependencies
install_rustdesk_dependencies() {
    log_message "INFO" "Installing RustDesk dependencies"
    
    # Install each dependency
    for dep in "${RUSTDESK_DEPENDENCIES[@]}"; do
        show_progress "dep_$dep" "Installing dependency: $dep"
        if ! install_apt_package "$dep"; then
            handle_error "Failed to install dependency: $dep" "install_apt_package $dep"
        fi
    done
    
    log_message "INFO" "RustDesk dependencies installation completed"
}

# Function to setup Flatpak
setup_flatpak() {
    show_progress "flatpak_setup" "Setting up Flatpak"
    
    log_message "INFO" "Installing Flatpak and GNOME Software plugin"
    
    # Install Flatpak and GNOME Software plugin
    if apt-get install -y flatpak gnome-software-plugin-flatpak; then
        log_message "INFO" "Flatpak and GNOME Software plugin installed successfully"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
    else
        log_message "ERROR" "Failed to install Flatpak and GNOME Software plugin"
        return 1
    fi
    
    # Add Flathub repository
    log_message "INFO" "Adding Flathub repository"
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_message "INFO" "Flathub repository added successfully"
        return 0
    else
        log_message "ERROR" "Failed to add Flathub repository"
        return 1
    fi
}

# Function to install Flatpak applications
install_flatpak_apps() {
    log_message "INFO" "Installing Flatpak applications"
    
    # Install each Flatpak application
    for app in "${FLATPAK_APPS[@]}"; do
        # Skip VLC if it's already installed via APT to avoid duplicate icons
        if [ "$app" = "org.videolan.VLC" ] && dpkg -l | grep -q "^ii\s\+vlc\s\+"; then
            log_message "INFO" "Skipping Flatpak VLC installation as it's already installed via APT"
            continue
        fi
        
        show_progress "flatpak_$app" "Installing Flatpak app: $app"
        
        log_message "INFO" "Installing Flatpak application: $app"
        if flatpak install -y flathub "$app"; then
            log_message "INFO" "Flatpak application installed successfully: $app"
            SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        else
            log_message "ERROR" "Failed to install Flatpak application: $app"
            FAILED_INSTALLS=$((FAILED_INSTALLS + 1))
        fi
    done
    
    log_message "INFO" "Flatpak applications installation completed"
}

# Main software installation function
install_software() {
    log_message "INFO" "Starting software installation"
    
    # Install RustDesk dependencies first
    install_rustdesk_dependencies
    
    # Install RustDesk
    if ! install_rustdesk; then
        handle_error "Failed to install RustDesk" install_rustdesk
    fi
    
    # Install APT GUI applications
    install_apt_gui_apps
    
    # Install APT CLI tools
    install_apt_cli_tools
    
    # Setup Flatpak
    if ! setup_flatpak; then
        handle_error "Failed to setup Flatpak" setup_flatpak
    fi
    
    # Install Flatpak applications
    install_flatpak_apps
    
    log_message "INFO" "Software installation completed"
}
