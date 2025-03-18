#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Account Management
# 
# This script handles the creation and management of validator
# accounts.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to create or import validator account
setup_validator_account() {
    log "STEP" "Setting up validator account"
    
    # Create data directory if it doesn't exist
    mkdir -p "$DATADIR/keystore"
    
    # Ask user if they want to create a new account or import an existing one
    if [ -z "$IMPORT_KEY" ]; then
        log "INFO" "Please choose how you want to set up your validator account:"
        echo "1. Create a new account"
        echo "2. Import an existing private key"
        read -r ACCOUNT_CHOICE
        
        if [ "$ACCOUNT_CHOICE" = "2" ]; then
            log "INFO" "Please enter your private key (without 0x prefix):"
            read -s IMPORT_KEY
        fi
    fi
    
    # Check if we're importing a private key
    if [ -n "$IMPORT_KEY" ]; then
        log "INFO" "Importing private key"
        
        # Create a temporary file for the private key
        local key_file=$(mktemp)
        echo "$IMPORT_KEY" > "$key_file"
        
        # Create a temporary file for the password if not provided
        local temp_password_file=""
        if [ -z "$PASSWORD_FILE" ]; then
            if [ -z "$PASSWORD" ]; then
                log "INFO" "Please enter a strong password for your validator account:"
                read -s PASSWORD
                echo
            fi
            
            temp_password_file=$(mktemp)
            echo "$PASSWORD" > "$temp_password_file"
            PASSWORD_FILE="$temp_password_file"
        fi
        
        # Import the private key
        local import_output=$(geth account import --datadir "$DATADIR" --password "$PASSWORD_FILE" "$key_file" 2>&1)
        local import_status=$?
        
        # Clean up temporary files
        rm -f "$key_file"
        if [ -n "$temp_password_file" ]; then
            rm -f "$temp_password_file"
        fi
        
        if [ $import_status -ne 0 ]; then
            log "ERROR" "Failed to import private key: $import_output"
            exit 1
        fi
        
        # Extract the account address
        VALIDATOR_ACCOUNT=$(echo "$import_output" | grep -oE '0x[0-9a-fA-F]{40}')
        log "INFO" "Successfully imported account: $VALIDATOR_ACCOUNT"
    else
        log "INFO" "Creating new account"
        
        # Create a temporary file for the password if not provided
        local temp_password_file=""
        if [ -z "$PASSWORD_FILE" ]; then
            if [ -z "$PASSWORD" ]; then
                log "INFO" "Please enter a strong password for your validator account:"
                read -s PASSWORD
                echo
                
                log "INFO" "Please confirm your password:"
                read -s PASSWORD_CONFIRM
                echo
                
                if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                    log "ERROR" "Passwords do not match"
                    exit 1
                fi
            fi
            
            temp_password_file=$(mktemp)
            echo "$PASSWORD" > "$temp_password_file"
            PASSWORD_FILE="$temp_password_file"
        fi
        
        # Create a new account
        local create_output=$(geth account new --datadir "$DATADIR" --password "$PASSWORD_FILE" 2>&1)
        local create_status=$?
        
        # Clean up temporary password file if we created one
        if [ -n "$temp_password_file" ]; then
            rm -f "$temp_password_file"
        fi
        
        if [ $create_status -ne 0 ]; then
            log "ERROR" "Failed to create account: $create_output"
            exit 1
        fi
        
        # Extract the account address
        VALIDATOR_ACCOUNT=$(echo "$create_output" | grep -oE '0x[0-9a-fA-F]{40}')
        log "INFO" "Successfully created account: $VALIDATOR_ACCOUNT"
    fi
    
    # Save password to a file in the data directory if not already there
    if [ -z "$PASSWORD_FILE" ] || [ ! -f "$PASSWORD_FILE" ]; then
        PASSWORD_FILE="$DATADIR/password.txt"
        echo "$PASSWORD" > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
        log "INFO" "Saved password to $PASSWORD_FILE"
    fi
    
    # Save the validator account address to a file for reference
    echo "$VALIDATOR_ACCOUNT" > "$DATADIR/validator-address.txt"
    log "INFO" "Saved validator address to $DATADIR/validator-address.txt"
    
    # Verify the account exists in the keystore
    if ! ls "$DATADIR/keystore" | grep -q "$(echo "$VALIDATOR_ACCOUNT" | cut -c 3- | tr '[:upper:]' '[:lower:]')"; then
        log "ERROR" "Validator account not found in keystore. This may indicate an issue with account creation."
        exit 1
    fi
    
    log "INFO" "Validator account setup completed"
}

# Function to list accounts
list_accounts() {
    log "STEP" "Listing accounts"
    
    if [ ! -d "$DATADIR/keystore" ]; then
        log "INFO" "No accounts found (keystore directory does not exist)"
        return
    fi
    
    local accounts=$(geth account list --datadir "$DATADIR" 2>/dev/null)
    
    if [ -z "$accounts" ]; then
        log "INFO" "No accounts found"
    else
        log "INFO" "Accounts:"
        echo "$accounts"
    fi
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If no arguments are provided, setup a new validator account
    if [ $# -eq 0 ]; then
        setup_validator_account
    else
        # Otherwise, parse arguments
        case "$1" in
            list)
                list_accounts
                ;;
            setup)
                setup_validator_account
                ;;
            *)
                log "ERROR" "Unknown command: $1"
                echo "Usage: $0 [list|setup]"
                exit 1
                ;;
        esac
    fi
fi
