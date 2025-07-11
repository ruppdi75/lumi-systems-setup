#!/bin/bash
#
# System Configuration Functions for Lumi-Systems Setup
#

# Function to configure system language
configure_system_language() {
    show_progress "system_language" "Setting system language to $SYSTEM_LANGUAGE"
    
    log_message "INFO" "Configuring system language to $SYSTEM_LANGUAGE"
    
    # Install language pack
    if apt-get install -y language-pack-de; then
        log_message "INFO" "German language pack installed"
    else
        log_message "ERROR" "Failed to install German language pack"
        return 1
    fi
    
    # Generate the locale
    if locale-gen "$SYSTEM_LANGUAGE"; then
        log_message "INFO" "Locale generated: $SYSTEM_LANGUAGE"
    else
        log_message "ERROR" "Failed to generate locale: $SYSTEM_LANGUAGE"
        return 1
    fi
    
    # Set the locale
    if update-locale LANG="$SYSTEM_LANGUAGE" LC_ALL="$SYSTEM_LANGUAGE"; then
        log_message "INFO" "System language set to $SYSTEM_LANGUAGE"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        return 0
    else
        log_message "ERROR" "Failed to set system language to $SYSTEM_LANGUAGE"
        return 1
    fi
}

# Function to configure system timezone
configure_system_timezone() {
    show_progress "system_timezone" "Setting system timezone to $SYSTEM_TIMEZONE"
    
    log_message "INFO" "Configuring system timezone to $SYSTEM_TIMEZONE"
    
    if timedatectl set-timezone "$SYSTEM_TIMEZONE"; then
        log_message "INFO" "System timezone set to $SYSTEM_TIMEZONE"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        return 0
    else
        log_message "ERROR" "Failed to set system timezone to $SYSTEM_TIMEZONE"
        return 1
    fi
}

# Function to configure weather location
configure_weather_location() {
    show_progress "weather_location" "Setting weather location to $WEATHER_LOCATION"
    
    log_message "INFO" "Configuring weather location to $WEATHER_LOCATION"
    
    # Check if gsettings is available
    if command -v gsettings &> /dev/null; then
        # Get current user
        if [ "$SUDO_USER" ]; then
            CURRENT_USER="$SUDO_USER"
        else
            CURRENT_USER="$(whoami)"
        fi
        
        # Set weather location for the current user
        if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather locations \"[<(uint32 2, <('$WEATHER_LOCATION', '', false, [(0.83975781321986481, 0.28539839653791525)], [(0.83719456862904465, 0.28764822453133844)])>)>]\""; then
            log_message "INFO" "Weather location set to $WEATHER_LOCATION"
            SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
            return 0
        else
            log_message "ERROR" "Failed to set weather location to $WEATHER_LOCATION"
            return 1
        fi
    else
        log_message "ERROR" "gsettings command not found, cannot set weather location"
        return 1
    fi
}

# Main system configuration function
configure_system() {
    log_message "INFO" "Starting system configuration"
    
    # Configure system language
    if ! configure_system_language; then
        handle_error "Failed to configure system language" configure_system_language
    fi
    
    # Configure system timezone
    if ! configure_system_timezone; then
        handle_error "Failed to configure system timezone" configure_system_timezone
    fi
    
    # Configure weather location
    if ! configure_weather_location; then
        handle_error "Failed to configure weather location" configure_weather_location
    fi
    
    log_message "INFO" "System configuration completed"
}
