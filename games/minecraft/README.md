<div align="center">
  <h1>Minecraft Shell Scripts</h1>
</div>

These shell scripts are designed to manage a Minecraft server, including automated backups and server startup configuration. They reside within the `hi-scripts/games/minecraft/` directory.

---

## Setup Scripts

The following scripts are available in this folder to help manage the Minecraft server environment.

### `backup_push.sh`
This script handles the **backup and remote transfer** of the Minecraft server data via **SCP**.

**Key Features:**
* Requires **5 arguments** for server path, remote credentials, and remote path.
* **Logging is optional**, provided as the 6th argument, otherwise it outputs to console only.
* Includes robust **SCP exit status handling** to clearly report upload success or failure.
* Provides a **Configuration Summary** before execution.

**Usage (Expected 5-6 arguments):**
```console
$ ./backup_push.sh <SERVER_DIR> <REMOTE_USER> <REMOTE_HOST> <REMOTE_PORT> <REMOTE_PATH> [LOG_PATH]
```

**Example (with log):**
```console
$ ./backup_push.sh /opt/minecraft/server myuser 192.168.1.1 22 /backups/minecraft/ /var/log/backup.log
```

### `startup_service.sh`
This script **generates a systemd unit file** (`minecraft.service`) to run the Minecraft server as a background service.

**Key Features:**
* Requires **3 arguments** (Server Path, JAR File Name, User Name).
* Allows optional configuration of **maximum (`-Xmx`) and minimum (`-Xms`) Java heap memory**. Default memory is **1024M**.
* Generates a service file configured for security, including `ProtectSystem=full` and `PrivateDevices=true`.
* Prints the final service file content and **step-by-step instructions** for installation.

**Usage (Expected 3-5 arguments):**
```console
$ ./startup_service.sh <SERVER_PATH> <JAR_FILE_NAME> <USER_NAME> [MAX_MEMORY] [MIN_MEMORY]
```

**Example (Custom Memory):**
```console
$ ./startup_service.sh /mnt/server/ fabric-server.jar minecraft 8192M 2048M
```