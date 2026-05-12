# Arch Chromebook Homelab(Updating as I go)

This repository documents the architecture, configuration and deployment of a self-hosted Zero-Trust home server built on repurposed Chromebook hardware. The infrastructure is entirely containerized and designed for maximum privacy, achieving digital sovereignty through localized, encrypted data management.

---

## Hardware Modification & Base System

Transforming a locked-down Chromebook into a standalone server required physical hardware modification. The internal battery was disconnected to bypass the hardware write-protect (WP) mechanism, allowing the installation of custom firmware and enabling USB boot capabilities. 

The base operating system is a minimal installation of Arch Linux. While configured to operate continuously with the lid closed like a traditional headless server, it retains local keyboard and display access for direct configurations. Remote access to the host is secured exclusively via SSH key-pair authentication, with password authentication disabled.

---

## Containerized Architecture

The entire stack is deployed via Docker and Docker Compose, ensuring process isolation alongside easy updates and rapid recovery.

* **Nginx Proxy Manager (NPM):** Serves as the reverse proxy, handling SSL/TLS termination, enforcing strict Access Control Lists (ACLs) and HTTP Strict Transport Security (HSTS). It routes traffic internally without unnecessarily exposing container ports to the host. **All hosted domains have successfully achieved an A+ security rating on SSL Labs testing** ensuring enterprise-grade encryption.
* **Pi-hole:** Network-wide DNS sinkhole for ad, tracker and malware blocking. Configured with Split-Horizon DNS to ensure local requests resolve to internal IPs, preventing NAT loopback issues.
* **dnsproxy:** Encrypts all upstream DNS queries (via DoH/DoT) and routes them to Quad9. While ISPs can still see target IP addresses and SNI data during connections. This protects against Man-in-the-Middle (MitM) attacks, eavesdropping on public Wi-Fi and DNS cache poisoning by malicious actors. Additionally, it prevents ISPs from logging browsing habits or hijacking failed domain requests for advertising.
* **Vaultwarden:** A lightweight, Rust-based Bitwarden-compatible password manager. Public signups are disabled with restricted access only to the local LAN or the  VPN subnet.
* **WireGuard:** A stealth VPN tunnel operating on UDP/51820 providing secure remote access to the internal network.Beyond standard encryption, it is significantly hardened via strict micro-segmentation at the firewall level. Traffic is also specifically routed only between the VPN subnet and the internal Docker network, completely preventing unauthorized lateral movement across the host's LAN.
* **DuckDNS:** A dynamic DNS updater that maintains routing for infrastructure and application-specific subdomains.

---

## Security & Zero-Trust Routing

Security is enforced at both the network and application layers, operating on a Zero-Trust model.

* **Micro-Segmented Firewall (UFW):** The host firewall is configured with a default `DROP` policy for all incoming and forwarded traffic. Internal routing is strictly controlled via surgical `ufw route` rules, allowing traffic to pass *only* between the WireGuard subnet and the internal Docker bridge network. No global forwarding is permitted.
* **Internal Name Resolution:** NPM is configured to route traffic to backend services using internal Docker hostnames (e.g., `vaultwarden:80`) rather than the host's LAN IP. This keeps traffic entirely within the Docker virtual switch and out of the host's firewall rules.
* **Strict Secrets Management:** All secrets, API tokens and environment variables are externalized into a `.env` file. A comprehensive `.gitignore` ensures that no Docker volumes, databases, logs or cryptographic keys are ever committed to version control.
---

## Deployment Configuration


1. Clone the repository to the host machine.
2. Create an `.env` file at the project root populated with the required variables (e.g., DDNS tokens, Timezone).
3. Ensure host UFW (if present) rules are configured to permit explicit routing between the VPN interface and the Docker network.
4. Deploy the stack using `docker-compose up -d`.
