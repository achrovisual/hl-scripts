#!/bin/bash

TEMP_DIR="/tmp/minecraft_backups" 
DATE=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="/tmp/minecraft_scp_backup.log" 

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

if [ "$#" -lt 5 ]; then
    log "ERROR: Missing required arguments. Expected 5, got $#."
    echo "Usage: $0 <SERVER_DIR> <REMOTE_USER> <REMOTE_HOST> <REMOTE_PORT> <REMOTE_PATH>" | tee -a "$LOG_FILE"
    echo "Example: $0 /opt/minecraft/server myuser 192.168.1.1 22 /backups/minecraft/" | tee -a "$LOG_FILE"
    exit 1
fi

SERVER_DIR="$1"
REMOTE_USER="$2"
REMOTE_HOST="$3"
REMOTE_PORT="$4"
REMOTE_PATH="$5"

BACKUP_FILENAME="minecraft_backup_$(basename "$SERVER_DIR")_$DATE.zip"

log "--- Starting Minecraft Server Backup (SCP Push) ---"
log "Target directory to backup: $SERVER_DIR"
log "Remote destination: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH (Port $REMOTE_PORT)"


if [ ! -d "$SERVER_DIR" ]; then
    log "ERROR: Minecraft directory '$SERVER_DIR' not found. Exiting."
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

log "Pushing $BACKUP_FILENAME to $REMOTE_HOST (Port $REMOTE_PORT) at $REMOTE_PATH"

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
