# Arch Chromebook Homelab(Updating as I go)

This repository documents the architecture, configuration and deployment of a self-hosted Zero-Trust home server built on repurposed Chromebook hardware. The infrastructure is entirely containerized and designed for maximum privacy achieving digital sovereignty through localized, encrypted data management.

## Hardware Modification & Base System

Transforming a locked-down Chromebook into a standalone server required physical hardware modification. The internal battery was disconnected to bypass the hardware write-protect (WP) mechanism, allowing the installation of custom firmware and enabling USB boot capabilities.

The base operating system is a minimal installation of Arch Linux. While configured to operate continuously with the lid closed like a traditional headless server, it retains local keyboard and display access for direct configurations. Remote access to the host is secured exclusively via SSH key-pair authentication, with password authentication disabled. L2 network stability is enforced by binding the static IP directly to the hardware MAC address of the USB Gigabit adapter via NetworkManager (`nmtui`), preventing interface configuration drifts.

## Containerized Architecture

The entire stack is deployed via Docker and Docker Compose, ensuring process isolation alongside easy updates and rapid recovery.

*   **Nginx Proxy Manager (NPM):** Serves as the reverse proxy, handling SSL/TLS termination, enforcing strict Access Control Lists (ACLs) and HTTP Strict Transport Security (HSTS). It routes traffic internally without unnecessarily exposing container ports to the host. Even its own Admin panel (port 81) is completely removed from host mapping, routed exclusively through a secured domain with strict ACLs via internal Docker DNS. All hosted domains have successfully achieved an A+ security rating on SSL Labs testing ensuring enterprise-grade encryption.
*   **Dashy:** A unified, highly customizable operational dashboard acting as the central entry point for the entire Homelab. Engineered with persistent Docker volumes bound directly to the host filesystem, ensuring that all UI layouts, internal routing links and configuration files (`conf.yml`) survive container recreation and ephemeral lifecycle events.
*   **Pi-hole:** Network-wide DNS sinkhole for ad, tracker and malware blocking. Configured with Split-Horizon DNS to ensure local requests resolve to internal IPs, preventing NAT loopback issues and guaranteeing rapid local resolution.
*   **dnsproxy:** Encrypts all upstream DNS queries (via DoH/DoT) and routes them to Quad9. This protects against Man-in-the-Middle (MitM) attacks, eavesdropping on public Wi-Fi and DNS cache poisoning by malicious actors. Additionally, it prevents ISPs from logging browsing habits or hijacking failed domain requests for advertising.
*   **Vaultwarden:** A lightweight, Rust-based Bitwarden-compatible password manager. Public signups are disabled with restricted access only to the local LAN or the VPN subnet. WebSockets are fully enabled to allow seamless Live Sync across all connected client devices.
*   **WireGuard:** A stealth VPN tunnel operating on UDP/51820 providing secure remote access to the internal network. Beyond standard encryption, it is significantly hardened via strict micro-segmentation at the firewall level. Traffic is specifically routed only between the VPN subnet and the internal Docker network.
*   **DuckDNS:** A dynamic DNS updater that maintains routing for infrastructure and application-specific subdomains.
*   **Uptime Kuma:** A self-hosted monitoring tool for zero-trust observability. It monitors backend containers internally via Docker hostnames avoiding public open port domains, checks SSL certificate expirations and verifies external DNS resolution without exposing its port to the public web.

## Security, Zero-Trust Routing & Telemetry

Security is enforced at both the network and application layers, operating on a strict Zero-Trust model.

*   **Micro-Segmented Firewall (UFW) & Behavioral IPS (CrowdSec):** The host firewall (`ufw`) is configured with a default DROP policy. Internal routing is strictly controlled via surgical `ufw route` rules, allowing traffic to pass only between the WireGuard subnet and the internal Docker bridge network. This L4 defense is paired with **CrowdSec**, a modern, behavioral Intrusion Prevention System that actively analyzes logs and automatically bans malicious IPs attempting brute-force or L7 layer attacks across the network.
*   **Internal Name Resolution:** NPM is configured to route traffic to backend services using internal Docker hostnames (e.g., `vaultwarden:80`) rather than the host's LAN IP. This keeps traffic entirely within the Docker virtual switch and out of the host's firewall rules.
*   **Host Telemetry Daemon:** A custom bash script (`check_health.sh`) runs as a background daemon via cron directly on the Arch host. It continuously monitors CPU temperature, RAM availability and Disk usage pushing telemetry data via API to Uptime Kuma every 60 seconds for real-time Discord alerting if hardware thresholds are exceeded.
*   **Air-Gapped Daily Backups (Total RTO Optimization):** Designed a highly resilient Disaster Recovery pipeline. An automated daily cronjob triggers a backup script that temporarily mounts an external USB drive, extracts all critical persistent volumes and unmounts it . This renders the backup drive invisible to the filesystem most of the time, effectively air-gapping it from ransomware lateral movement. When combined with this GitOps repository, the entire infrastructure can be rebuilt from scratch on bare metal in minutes without any manual reconfiguration.
*   **Strict Secrets Management:** All secrets, API tokens and environment variables are externalized into a `.env` file. A comprehensive `.gitignore` ensures that no Docker volumes, databases, logs or cryptographic keys are ever committed to version control.

## Deployment Configuration

1.  Clone the repository to the host machine.
2.  Create an `.env` file at the project root populated with the required variables (e.g., DDNS tokens, Timezone, Passwords).
3.  Ensure host UFW (if present) rules are configured to permit explicit routing between the VPN interface and the Docker network.
4.  Deploy the stack using `docker-compose up -d`.
5.  Restore persistent data from the ephemeral USB backup drive if performing a total disaster recovery.
