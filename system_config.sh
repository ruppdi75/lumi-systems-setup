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

    local city="$WEATHER_LOCATION"
    local latitude="48.20849"
    local longitude="16.37208"
    
    # Set coordinates based on city
    case "$city" in
        "Vienna"|"Wien")
            # Vienna coordinates
            latitude="48.2083537"
            longitude="16.3725042"
            city="Wien" # Use German name for consistency
            ;;
        # Add more cities here as needed with their coordinates
        *)
            log_message "WARNING" "Unknown city for weather location: $city. Using default coordinates for Vienna."
            city="Wien"
            ;;
    esac

    # Check if gsettings is available
    if ! command -v gsettings &> /dev/null; then
        log_message "ERROR" "gsettings command not found, cannot set weather location"
        return 1
    fi

    # Check if bc is available (needed for coordinate conversion)
    if ! command -v bc &> /dev/null; then
        log_message "INFO" "Installing bc for coordinate calculations."
        apt-get update && apt-get install -y bc
    fi

    # Check if org.gnome.Weather schema is available
    if ! gsettings list-schemas | grep -q 'org.gnome.Weather'; then
        log_message "WARNING" "GNOME Weather schema not found. Attempting to install GNOME Weather."
        # Try apt first
        if command -v apt &> /dev/null; then
            log_message "INFO" "Installing GNOME Weather via apt."
            apt-get update && apt-get install -y gnome-weather
        fi
        # Try Flatpak as fallback
        if ! gsettings list-schemas | grep -q 'org.gnome.Weather' && command -v flatpak &> /dev/null; then
            if ! flatpak list | grep -q org.gnome.Weather; then
                log_message "INFO" "Installing GNOME Weather via Flatpak."
                flatpak install -y flathub org.gnome.Weather
            fi
        fi
        # Re-check schema after install attempts
        if ! gsettings list-schemas | grep -q 'org.gnome.Weather'; then
            log_message "ERROR" "GNOME Weather schema still not found after attempted installation. Skipping weather location configuration."
            return 1
        fi
    fi

    # Get current user
    if [ "$SUDO_USER" ]; then
        CURRENT_USER="$SUDO_USER"
    else
        CURRENT_USER="$(whoami)"
    fi

    # Convert coordinates from degrees to radians
    local lat_rad=$(echo "scale=17; ${latitude} / (180 / 3.141592653589793)" | bc 2>/dev/null)
    local lon_rad=$(echo "scale=17; ${longitude} / (180 / 3.141592653589793)" | bc 2>/dev/null)
    
    # If bc failed or returned empty, use the degree values
    if [ -z "$lat_rad" ] || [ -z "$lon_rad" ]; then
        log_message "WARNING" "Failed to convert coordinates to radians. Using degree values."
        lat_rad="$latitude"
        lon_rad="$longitude"
    else
        log_message "INFO" "Converted coordinates to radians: Lat=${lat_rad}, Lon=${lon_rad}"
    fi

    # Try multiple different methods to set the weather location
    log_message "INFO" "Attempting to set weather location with multiple methods"
    
    # Method 1: Try setting timezone first (which may help with GNOME Weather)
    if timedatectl set-timezone Europe/Vienna &>/dev/null; then
        log_message "INFO" "Timezone set to Europe/Vienna"
    else
        log_message "WARNING" "Failed to set timezone to Europe/Vienna"
    fi
    
    # Method 2: Disable automatic location detection
    if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather automatic-location false" &>/dev/null; then
        log_message "INFO" "Disabled automatic location detection for Weather"
    fi

    # Method 3: Try to set an empty location list first (reset)
    if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather locations '[]'" &>/dev/null; then
        log_message "INFO" "Reset weather locations list"
    fi
    
    # Method 4: Try several GVariant formats - one might work
    local success=false
    
    # Create a GVariant string based on user example (using coordinates in radians)
    local gvariant_string="[<(uint32 2, <('$city', '', false, [($lat_rad, $lon_rad)], @a(dd))>)>]"
    
    # Try with GNOME Weather
    if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather locations \"$gvariant_string\"" &>/dev/null; then
        log_message "INFO" "Weather location set to $city using GVariant format"
        success=true
    fi
    
    # Also try with GNOME Shell weather (often needed for panel integration)
    if su - "$CURRENT_USER" -c "gsettings set org.gnome.shell.weather locations \"$gvariant_string\"" &>/dev/null; then
        log_message "INFO" "GNOME Shell weather location set to $city"
        success=true
    fi
    
    # Try with simplified format
    if ! $success; then
        log_message "INFO" "Trying simplified format for weather location"
        if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather locations \"[{'name': <'$city'>, 'latitude': <$latitude>, 'longitude': <$longitude>, 'code': <'geonames:2761369'>}]\"" &>/dev/null; then
            log_message "INFO" "Weather location set to $city using simplified format"
            success=true
            # Also try with GNOME Shell weather
            su - "$CURRENT_USER" -c "gsettings set org.gnome.shell.weather locations \"[{'name': <'$city'>, 'latitude': <$latitude>, 'longitude': <$longitude>, 'code': <'geonames:2761369'>}]\"" &>/dev/null
        fi
    fi

    # Try with basic format
    if ! $success; then
        log_message "INFO" "Trying basic format for weather location"
        if su - "$CURRENT_USER" -c "gsettings set org.gnome.Weather locations '[]'" &>/dev/null && \
           su - "$CURRENT_USER" -c "dconf write /org/gnome/Weather/locations \"[]\"" &>/dev/null; then
            log_message "INFO" "Reset weather locations to empty list as fallback"
            success=true
        fi
    fi

    if $success; then
        log_message "INFO" "Successfully configured weather location settings"
        SUCCESSFUL_INSTALLS=$((SUCCESSFUL_INSTALLS + 1))
        return 0
    else
        log_message "WARNING" "Automatic weather location configuration failed. User may need to set it manually."
        # This is non-critical, so we'll continue with installation
        log_message "INFO" "Continuing with setup despite weather location configuration issue"
        return 0
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
