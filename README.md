# RKITHUNT
RKitHunt (Rootkit Hunter) is a lightweight Bash-based security auditing tool designed to detect signs of rootkits, malware, and backdoors on Linux systems.  It performs multiple forensic checks to identify hidden processes, suspicious kernel modules, backdoored binaries, and other anomalies used by attackers to persist on compromised systems.

✨ **Features of RootKHunter**

- Detects hidden processes and reports suspicious activity.
- Identifies hidden files and directories with ownership & permissions.
- Scans for suspicious kernel modules (possible rootkit implants).
- Verifies the integrity of system binaries using SHA256 hashes.
- Checks common rootkit files, strings, and signatures.
- Monitors network ports & anomalies.
- Interactive menu-driven interface for ease of use.

📦 **Installation**

Clone the repository and make the script executable:

git clone https://github.com/neelzaveri/rkithunter.git
cd rkithunt
chmod +x rkithunt.sh

🚀 **Usage**
Run the tool with root privileges for full detection:
sudo ./rkithunt.sh

🛠️ **Requirements**
Linux system (tested on Debian/Ubuntu, compatible with most distros)
Root privileges recommended for full scan

⚠️ **Disclaimer**
RKitHunt is an auditing tool only. It does not remove or clean rootkits. If suspicious activity is detected, further investigation and system hardening are strongly recommended.
#rootkit #rootkithunter #CyberTool #cybersecurity #forensictool #rootkit-hunter
