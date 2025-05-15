#!/bin/bash

CONFIG_DIR="$(dirname "$(realpath "$0")")"
CONFIG_FILE="{secret file path}"
OATHTOOL_CMD=$(which oathtool)

if [ -z "$OATHTOOL_CMD" ]; then
    echo "Error: oathtool is required. Install with: sudo apt install oathtool"
    exit 1
fi

touch "$CONFIG_FILE"
chmod 600 "$CONFIG_FILE"

generate_totp() {
    $OATHTOOL_CMD --totp -b "$1"
}

show_codes() {
    echo -e "\nTOTP Codes:"
    echo "----------------------------------------------------------------------------"
    printf "%-25s | %-30s | %-6s\n" "Service" "Username" "Code"
    echo "----------------------------------------------------------------------------"
    sort "$CONFIG_FILE" | while IFS='|' read -r service username secret; do
        if [ -n "$secret" ]; then
            code=$(generate_totp "$secret")
            printf "%-25s | %-30s | %-6s\n" "$service" "$username" "$code"
        fi
    done
    echo -e ""
}

edit_config() {
    nano "$CONFIG_FILE"
}

if [ "$1" = "edit" ]; then
    edit_config
else
    show_codes
fi
