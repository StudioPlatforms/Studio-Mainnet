#!/bin/bash

#############################################################
# Studio Blockchain Validator Setup - Backup Configuration
# 
# This script sets up automatic backups for the validator node.
#############################################################

# Source common functions and variables
source "$(dirname "$0")/common.sh"

# Function to setup automatic backups
setup_auto_backup() {
    if [ "$AUTO_BACKUP" != true ]; then
        log "INFO" "Automatic backup setup skipped"
        return
    fi
    
    log "STEP" "Setting up automatic backups"
    
    # Create backup directories
    mkdir -p "$BACKUP_DIR/daily"
    mkdir -p "$BACKUP_DIR/weekly"
    
    # Create backup script
    local backup_script="$SCRIPTS_DIR/backup.sh"
    
    log "INFO" "Creating backup script at $backup_script"
    cat > "$backup_script" << EOF
#!/bin/bash

# Studio Blockchain Validator Backup Script

# Configuration
DATADIR="$DATADIR"
BACKUP_DIR="$BACKUP_DIR"
DATE=\$(date +%Y%m%d)
BACKUP_TYPE=\$1
BACKUP_FILE="\$BACKUP_DIR/\$BACKUP_TYPE/blockchain-data-\$DATE.tar.gz"

# Function to log messages
log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1"
    logger -t "validator-backup" "\$1"
}

# Check if backup type is provided
if [ -z "\$BACKUP_TYPE" ]; then
    log "Error: Backup type not specified (daily/weekly)"
    echo "Usage: \$0 {daily|weekly}"
    exit 1
fi

# Check if backup directory exists
if [ ! -d "\$BACKUP_DIR/\$BACKUP_TYPE" ]; then
    log "Creating backup directory \$BACKUP_DIR/\$BACKUP_TYPE"
    mkdir -p "\$BACKUP_DIR/\$BACKUP_TYPE"
fi

# Check if geth is running
if pgrep -f "geth.*--datadir \$DATADIR" > /dev/null; then
    log "Geth is running, stopping it for backup"
    
    # Get the PID of the geth process
    GETH_PID=\$(pgrep -f "geth.*--datadir \$DATADIR")
    
    # Stop geth service if systemd service is used
    if systemctl --user status studio-validator.service &>/dev/null; then
        log "Stopping geth service"
        systemctl --user stop studio-validator.service
    else
        # Otherwise, send SIGINT to geth process
        log "Sending SIGINT to geth process \$GETH_PID"
        kill -INT \$GETH_PID
    fi
    
    # Wait for geth to stop
    log "Waiting for geth to stop"
    for i in {1..30}; do
        if ! pgrep -f "geth.*--datadir \$DATADIR" > /dev/null; then
            break
        fi
        sleep 1
    done
    
    # Force kill if still running
    if pgrep -f "geth.*--datadir \$DATADIR" > /dev/null; then
        log "Geth still running after 30 seconds, force killing"
        pkill -9 -f "geth.*--datadir \$DATADIR"
        sleep 2
    fi
    
    # Set flag to restart geth after backup
    RESTART_GETH=true
else
    log "Geth is not running, no need to stop it"
    RESTART_GETH=false
fi

# Create backup
log "Creating backup at \$BACKUP_FILE"
tar --exclude="\$DATADIR/geth/chaindata/ancient" \
    --exclude="\$DATADIR/geth/lightchaindata/ancient" \
    -czf "\$BACKUP_FILE" -C "\$(dirname "\$DATADIR")" "\$(basename "\$DATADIR")"

# Check if backup was successful
if [ \$? -eq 0 ]; then
    log "Backup created successfully"
    
    # Calculate backup size
    BACKUP_SIZE=\$(du -h "\$BACKUP_FILE" | cut -f1)
    log "Backup size: \$BACKUP_SIZE"
    
    # Verify backup integrity
    log "Verifying backup integrity"
    if tar -tzf "\$BACKUP_FILE" > /dev/null 2>&1; then
        log "Backup integrity verified"
    else
        log "Error: Backup integrity check failed"
    fi
    
    # Cleanup old backups
    if [ "\$BACKUP_TYPE" = "daily" ]; then
        # Keep last 7 daily backups
        log "Cleaning up old daily backups"
        find "\$BACKUP_DIR/daily" -name "blockchain-data-*.tar.gz" -type f -mtime +7 -delete
    elif [ "\$BACKUP_TYPE" = "weekly" ]; then
        # Keep last 4 weekly backups
        log "Cleaning up old weekly backups"
        find "\$BACKUP_DIR/weekly" -name "blockchain-data-*.tar.gz" -type f -mtime +28 -delete
    fi
else
    log "Error: Backup creation failed"
fi

# Restart geth if it was running before
if [ "\$RESTART_GETH" = true ]; then
    log "Restarting geth"
    
    # Start geth service if systemd service is used
    if systemctl --user status studio-validator.service &>/dev/null; then
        log "Starting geth service"
        systemctl --user start studio-validator.service
    else
        # Otherwise, start geth with the same command line
        log "Starting geth process"
        cd "\$(dirname "\$DATADIR")" && nohup ./start.sh > /dev/null 2>&1 &
    fi
fi

log "Backup process completed"
EOF
    
    chmod +x "$backup_script"
    
    # Create cron jobs
    log "INFO" "Setting up cron jobs for backups"
    
    # Remove existing cron jobs for backups
    crontab -l 2>/dev/null | grep -v "$backup_script" | crontab -
    
    # Add new cron jobs
    (crontab -l 2>/dev/null ; echo "0 2 * * * $backup_script daily") | crontab -
    (crontab -l 2>/dev/null ; echo "0 3 * * 0 $backup_script weekly") | crontab -
    
    log "INFO" "Automatic backup setup completed"
}

# Function to create a manual backup
create_backup() {
    local backup_type="$1"
    
    if [ -z "$backup_type" ]; then
        backup_type="manual"
    fi
    
    log "STEP" "Creating $backup_type backup"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR/$backup_type"
    
    # Create backup file
    local date=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/$backup_type/blockchain-data-$date.tar.gz"
    
    log "INFO" "Creating backup at $backup_file"
    
    # Check if geth is running
    if pgrep -f "geth.*--datadir $DATADIR" > /dev/null; then
        log "WARN" "Geth is running. It's recommended to stop it before creating a backup."
        log "INFO" "You can stop it with: systemctl --user stop studio-validator.service"
        log "INFO" "Or continue with the backup, but it may not be consistent."
        
        read -p "Continue with backup? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Backup aborted"
            return
        fi
    fi
    
    # Create backup
    tar --exclude="$DATADIR/geth/chaindata/ancient" \
        --exclude="$DATADIR/geth/lightchaindata/ancient" \
        -czf "$backup_file" -C "$(dirname "$DATADIR")" "$(basename "$DATADIR")"
    
    # Check if backup was successful
    if [ $? -eq 0 ]; then
        log "INFO" "Backup created successfully"
        
        # Calculate backup size
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log "INFO" "Backup size: $backup_size"
        
        # Verify backup integrity
        log "INFO" "Verifying backup integrity"
        if tar -tzf "$backup_file" > /dev/null 2>&1; then
            log "INFO" "Backup integrity verified"
        else
            log "ERROR" "Backup integrity check failed"
        fi
    else
        log "ERROR" "Backup creation failed"
    fi
}

# Function to restore from a backup
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log "ERROR" "Backup file not specified"
        echo "Usage: $0 restore <backup-file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    log "STEP" "Restoring from backup: $backup_file"
    
    # Check if geth is running
    if pgrep -f "geth.*--datadir $DATADIR" > /dev/null; then
        log "WARN" "Geth is running. It must be stopped before restoring a backup."
        log "INFO" "You can stop it with: systemctl --user stop studio-validator.service"
        return 1
    fi
    
    # Create a backup of the current data directory
    local date=$(date +%Y%m%d-%H%M%S)
    local current_backup="$BACKUP_DIR/pre-restore/blockchain-data-$date.tar.gz"
    
    log "INFO" "Creating backup of current data directory at $current_backup"
    mkdir -p "$BACKUP_DIR/pre-restore"
    tar --exclude="$DATADIR/geth/chaindata/ancient" \
        --exclude="$DATADIR/geth/lightchaindata/ancient" \
        -czf "$current_backup" -C "$(dirname "$DATADIR")" "$(basename "$DATADIR")"
    
    # Remove current data directory
    log "INFO" "Removing current data directory"
    rm -rf "$DATADIR"
    
    # Extract backup
    log "INFO" "Extracting backup"
    mkdir -p "$(dirname "$DATADIR")"
    tar -xzf "$backup_file" -C "$(dirname "$DATADIR")"
    
    # Check if restore was successful
    if [ $? -eq 0 ]; then
        log "INFO" "Backup restored successfully"
    else
        log "ERROR" "Backup restoration failed"
        
        # Restore from pre-restore backup
        log "INFO" "Restoring from pre-restore backup"
        rm -rf "$DATADIR"
        tar -xzf "$current_backup" -C "$(dirname "$DATADIR")"
        
        return 1
    fi
    
    log "INFO" "You can now start geth with: systemctl --user start studio-validator.service"
}

# Run the functions if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If no arguments are provided, setup automatic backups
    if [ $# -eq 0 ]; then
        setup_auto_backup
    else
        # Otherwise, parse arguments
        case "$1" in
            setup)
                setup_auto_backup
                ;;
            create)
                create_backup "$2"
                ;;
            restore)
                restore_backup "$2"
                ;;
            *)
                log "ERROR" "Unknown command: $1"
                echo "Usage: $0 [setup|create [backup-type]|restore <backup-file>]"
                exit 1
                ;;
        esac
    fi
fi
