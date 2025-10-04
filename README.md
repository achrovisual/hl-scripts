# hl-scripts

[![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry_Pi-A22846?style=for-the-badge&logo=raspberry-pi&logoColor=white)](https://www.raspberrypi.com/)
[![K3s](https://img.shields.io/badge/K3s-FF0000?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![Minecraft](https://img.shields.io/badge/Minecraft-7C5D4B?style=for-the-badge&logo=minecraft&logoColor=white)](https://www.minecraft.net/)
[![Networking](https://img.shields.io/badge/Networking-0078D4?style=for-the-badge&logo=microsoftexcel&logoColor=white)](https://en.wikipedia.org/wiki/Computer_network)

---

## 🚀 Overview

This repository is a collection of essential **Shell Scripts** designed for the setup, management, and maintenance of a **Home Lab** environment. It covers a range of utilities, from managing **K3s** (lightweight Kubernetes) clusters and service-specific tasks like **Minecraft server management**, to low-level network and security configurations for devices like **EdgeOS** and **RouterOS**.

The goal is to provide **reproducible** and **convenient** automation for common system administration and homelab operations.

---

## ✨ Key Sections & Features

The repository is structured logically to separate scripts by their function:

### 🎮 `games`
Automation scripts for managing various game servers and related services.
- **`minecraft`**: Contains scripts for **backing up** world data and handling **service startup** for the Minecraft server to ensure data integrity and uptime.

### 💾 `k3s`
Scripts dedicated to the installation, configuration, and management of a **K3s (Kubernetes)** cluster.
- **`agent`**: Scripts for setting up **K3s worker nodes**.
- **`server`**: Scripts for initializing the **K3s master node**.
- **`utility`**: General scripts for K3s maintenance or monitoring.

### 🌐 `networking`
Scripts and configuration files for automating changes on networking hardware, particularly routers and firewalls.
- **`edgeos`**: Scripts for quickly **enabling and disabling firewall rules** on **Ubiquiti EdgeRouter** devices.
- **`routeros`**: Configuration resources for **MikroTik RouterOS** devices, focusing on WAN status and notification features.

### ⚙️ `setup`
General-purpose setup scripts for base operating system configuration.
- Contains scripts for configuring a **desktop environment** or related graphical utilities.

### 🔨 `utility`
Essential system-level utility scripts for security and system management.
- Scripts to configure a system as a **bastion host** (jump server).
- Scripts to enhance security by **changing the default SSH port**.

---

## 🛠️ Usage

To use any script, navigate to its respective directory and execute it. **Always** review the contents of a script before executing it, especially those requiring elevated permissions.

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/achrovisual/hl-scripts.git](https://github.com/achrovisual/hl-scripts.git)
    cd hl-scripts
    ```

2.  **Make the script executable (if necessary):**
    ```bash
    chmod +x <path-to-script>/<script-name>
    ```

3.  **Run the script:**
    ```bash
    ./<path-to-script>/<script-name>
    ```

***

## ⚠️ Prerequisites

-   A machine running a Linux distribution, preferably a Debian-based system.
-   **Bash** shell environment.
-   **`sudo`** access for system-level configuration scripts.
-   Basic knowledge of **Linux commands** and **Shell Scripting** is recommended.