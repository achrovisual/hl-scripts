#!/bin/bash

# --- Configuration ---

REMOTE_USER="PLACEHOLDER_REMOTE_USERNAME" 
REMOTE_HOST="PLACEHOLDER_REMOTE_HOST_IP_OR_HOSTNAME" 
REMOTE_PORT="PLACEHOLDER_REMOTE_SSH_PORT"
REMOTE_PATH="/home/$REMOTE_USER/backups/minecraft/" 

SERVER_DIR="PLACEHOLDER_SERVER_MINECRAFT_PATH" 
TEMP_DIR="/tmp/minecraft_backups" 
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_FILENAME="minecraft_backup_$DATE.zip"
LOG_FILE="/home/$REMOTE_USER/minecraft_scp_backup.log" 

# --- Functions ---

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Script Start ---

log "--- Starting Minecraft Server Backup (SCP Push) ---"

if [ ! -d "$SERVER_DIR" ]; then
    log "ERROR: Minecraft directory not found. Exiting."
    exit 1
fi

mkdir -p "$TEMP_DIR"

ZIP_PATH="$TEMP_DIR/$BACKUP_FILENAME"

log "Creating ZIP archive: $BACKUP_FILENAME"
if ! zip -r -q "$ZIP_PATH" "$SERVER_DIR" &>> "$LOG_FILE"; then
    log "ERROR: ZIP creation failed."
    exit 1
fi
log "ZIP created successfully."

log "Pushing $BACKUP_FILENAME to $REMOTE_HOST (Port $REMOTE_PORT)"

if ! scp -P "$REMOTE_PORT" -o BatchMode=yes "$ZIP_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" &>> "$LOG_FILE"; then
    log "ERROR: SCP upload failed. Check port, keys, and network."
fi
SCP_STATUS=$?

if [ $SCP_STATUS -eq 0 ]; then
    log "Upload successful."
else
    log "Upload failed with status code $SCP_STATUS."
fi

log "Cleaning up local temporary file."
rm -f "$ZIP_PATH"

log "--- Backup Finished ---"

exit $SCP_STATUS