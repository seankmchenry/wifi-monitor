#!/bin/bash

# Define the sound to play
SOUND_FILE="$HOME/Scripts/wifi-monitor/hip-to-be-square.aiff"

# Log file location
LOG_FILE="$HOME/Scripts/wifi-monitor/wifi-monitor.log"

# Function to play sound
play_sound() {
    # Try multiple methods to play sound
    afplay "$SOUND_FILE"

    # Also try AppleScript as a backup method
    osascript -e "play sound \"$SOUND_FILE\""

    # Add a notification with sound as another fallback
    osascript -e 'display notification "WiFi Disconnected" with title "Network Status" sound name "Basso"'

    echo "$(date): WiFi disconnection detected - Sound played" >> "$LOG_FILE"
}

# Keep track of previous state
PREVIOUS_STATE="unknown"

# Function to check WiFi status
check_wifi() {
    # Get the current WiFi interface (usually en0, but can be different)
    WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device" | awk '{print $2}')

    # Check if WiFi is enabled
    WIFI_POWER=$(networksetup -getairportpower "$WIFI_INTERFACE" | awk '{print $4}')

    # Check if WiFi is connected to a network
    WIFI_NETWORK=$(airport -I | grep " SSID" | awk '{print $2}')

    # Check actual connection status with ping
    ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1
    PING_RESULT=$?

    CURRENT_STATE="connected"

    # Determine the current state
    if [ "$WIFI_POWER" == "Off" ]; then
        CURRENT_STATE="off"
    elif [ -z "$WIFI_NETWORK" ]; then
        CURRENT_STATE="no_network"
    elif [ $PING_RESULT -ne 0 ]; then
        CURRENT_STATE="no_internet"
    fi

    # If state changed from connected to any other state, play sound
    if [ "$PREVIOUS_STATE" == "connected" ] && [ "$CURRENT_STATE" != "connected" ]; then
        echo "WiFi state changed from connected to $CURRENT_STATE at $(date)" >> "$LOG_FILE"
        play_sound
    fi

    # Update the previous state
    PREVIOUS_STATE="$CURRENT_STATE"
}

# Create the airport command symlink if it doesn't exist
if [ ! -f /usr/local/bin/airport ]; then
    sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/local/bin/airport
fi

echo "WiFi monitoring started at $(date)" >> "$LOG_FILE"

# Check WiFi status every 5 seconds
while true; do
    check_wifi
    sleep 5
done
