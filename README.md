# Arch Chromebook Homelab(Updated as I go)

This repository documents the architecture, configuration and deployment of a self-hosted Zero-Trust home server  built on repurposed Chromebook hardware. "The infrastructure utilizes a hybrid-containerized architecture. While core applications operate within isolated Docker environments. Critical security layers (UFW, CrowdSec Firewall Bouncers) and telemetry daemons execute directly on the hardened Arch Linux host for deep kernel-level control. 
## Hardware Modification & Base System

Transforming a locked-down Chromebook into a standalone server required physical hardware modification as the internal battery  was disconneced to bypass the hardware write-protect (WP) mechanism. This allows the installation of custom firmware (like arch) and enables USB boot capabilities.

The base operating system is a minimal installation of Arch Linux. While the chromebook is configured to operate continuously with the lid closed like a traditional headless server, it retains local keyboard and display access for direct physical configurations(if needed).

* **Network Stability:** L2 network stability is enforced by moving from Wi-Fi to a hardwired Ethernet connection. The static IP is bound directly to the hardware MAC address of the Ethernet  adapter via NetworkManager (nmtui). It is also enforced via a static DHCP reservation at the ISP Router level. This dual-layer binding prevents interface configuration drifts and ensures the host never loses its IP lease.
* **Host Access:** Remote access to the host machine is secured only via SSH Key-Pair authentication as Password authentication being strictly disabled at the `sshd` level.

## Containerized Architecture

The core application stack is deployed via Docker and Docker Compose, ensuring process isolation. This is integrated with host-level bash automation and cloud-synchronized threat intelligence (CrowdSec), balancing rapid recovery with uncompromising host security.

* **Nginx Proxy Manager (NPM):** Serves as the reverse proxy handling SSL/TLS termination. Enforcing strict Access Control Lists (ACLs) and HTTP Strict Transport Security (HSTS). Even its own Admin panel (port 81) is completely removed from host mapping, routed through a secured domain with strict ACLs via internal Docker DNS. All hosted domains have successfully achieved an A+ security rating on SSL Labs testing.
* **Dashy:** A unified, highly customizable operational dashboard acting as the central entry point for the entire Homelab. Engineered with persistent Docker volumes bound directly to the host filesystem. The UI has been heavily modified using a custom dark cybersec-themed CSS file (`custom-theme.css`) mounted securely as read-only (`:ro`), which was generated via LLM assistance with manual tailoring.
* **Pi-hole:** Network-wide DNS sinkhole for ad, tracker and malware blocking. Configured with Split-Horizon DNS ensuring local requests resolve to internal IPs, preventing NAT loopback issues and securing local resolution and speed.
* **dnsproxy:** Encrypts all upstream DNS queries(via DoH/DoT) and routes them to Quad9. This protects against Man-in-the-Middle (MitM) attacks, eavesdropping and DNS cache poisoning. It also guarantees ISPs cannot log browsing habits or hijack failed domain requests.
* **Vaultwarden:** A lightweight Rust-based Bitwarden-compatible password manager. Public signups are disabled (`SIGNUPS_ALLOWED=false`). Extended logging is enabled (`EXTENDED_LOGGING=true`) to feed precise authentication data to the Intrusion Prevention System. WebSockets are fully enabled  allowing Live Sync across connected clients.
* **WireGuard:** A stealth VPN tunnel operating on UDP/51820 acting as the **only** ingress point to the server. Beyond standard encryption, it is significantly hardened via strict micro-segmentation at the firewall level.
* **Dozzle:** A lightweight, web-based log viewer providing real-time container log streaming and observability for rapid debugging and IPS monitoring.
* **DuckDNS:** A dynamic DNS updater that maintains routing for infrastructure and application-specific subdomains.
* **Uptime Kuma:** A self-hosted monitoring tool for zero-trust observability. It monitors backend containers internally via Docker hostnames, checks SSL certificate expirations and verifies external DNS resolution without exposing its port to the public web.

## Security, Zero-Trust Routing & Telemetry

Security is enforced at both the network and application layers, operating on a  Zero-Trust model. The external attack surface is thus reduced to a minimum.

* **Application-Level Defense-in-Depth (2FA & Auth):** Even in the highly unlikely event that an attacker breaches the WireGuard tunnel, bypasses the UFW routes and evades the CrowdSec IPS they still cannot access the applications. Every exposed internal domain is fortified with distinct,  credentials and Time-Based One-Time Passwords (`TOTP / 2FA`).
* **Absolute Zero-Trust Ingress & DNS-01 Challenges:** The physical ISP router has exactly **one** open port: UDP 51820 (WireGuard). Port 80 and 443 are strictly closed at the router level. To achieve this without breaking SSL renewals. Let's Encrypt certificates are renewed entirely via **DNS-01 Challenges** using the DuckDNS API through Nginx Proxy Manager.
* **Micro-Segmented Firewall (UFW) & Behavioral IPS (CrowdSec):** The host firewall (`ufw`) is configured with a default DROP policy. Internal routing is controlled via UFW route rules. Allowing traffic to pass only between the WireGuard subnet and the internal Docker bridge network. This L4 defense is paired with **CrowdSec**, a modern, behavioral Intrusion Prevention System. CrowdSec actively analyzes Nginx logs and Vaultwarden telemetry, automatically banning malicious IPs attempting brute-force or L7 layer attacks via a kernel-level `iptables` bouncer.
* **Internal Name Resolution:** NPM routes traffic to backend services using internal Docker hostnames (e.g., `vaultwarden:80`) rather than the host's LAN IP, keeping traffic entirely within the safe Docker virtual switch.
* **Host Telemetry Daemon:** A custom bash script (`health_check.sh`) runs as a background daemon using a dedicated user crontab. It continuously monitors CPU temperature, free RAM and Disk usage. It then pushes telemetry data via API to Uptime-Kuma every 60 seconds for real-time webhook alerting. Alerting also if hardware thresholds are exceeded.
* **Air-Gapped Daily Backups (Total RTO Optimization):** Designed a highly resilient Disaster Recovery pipeline. An automated daily cronjob (`backup.sh`), running securely under its own distinct crontab user, temporarily mounts an external USB drive, extracts all critical volumes and then unmounts it. This renders the backup drive invisible to the filesystem, effectively securing it from ransomware. Combined with this GitOps repository, the infrastructure can be rebuilt from scratch in minutes.
* **Strict Secrets Management:** All secrets, API tokens and environment variables are saved in a `.env` file. A comprehensive `.gitignore` ensures that no Docker volumes or other sensitive information are ever committed to version control.

## Deployment Configuration

1. Clone the repository to the host machine.
2. Create an `.env` file at the project root populated with the required variables (e.g., DDNS tokens, Timezones, Database Passwords).
3. Ensure host UFW rules are configured to permit explicit routing between the VPN interface and the Docker network.
4. Deploy the stack using `docker-compose up -d`.
5. Setup each dashboard login (if required) and setup to you needs and liking.
6. Restore persistent data from the  USB backup drive, if performing a total disaster recovery.
