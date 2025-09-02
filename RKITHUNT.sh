#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

show_banner() {
  clear
  echo -e "${RED}"
 echo " ██████╗ ██╗  ██╗██╗████████╗██╗  ██╗██╗   ██╗███╗   ██╗████████╗"
 echo " ██╔══██╗██║ ██╔╝██║╚══██╔══╝██║  ██║██║   ██║████╗  ██║╚══██╔══╝"
 echo " ██████╔╝█████╔╝ ██║   ██║   ███████║██║   ██║██╔██╗ ██║   ██║   "
 echo " ██╔══██╗██╔═██╗ ██║   ██║   ██╔══██║██║   ██║██║╚██╗██║   ██║   "
 echo " ██║  ██║██║  ██╗██║   ██║   ██║  ██║╚██████╔╝██║ ╚████║   ██║   "
 echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   "
  echo -e "${NC}"
  echo -e "${YELLOW}             RKITHunt - Rootkit Hunter for Linux Systems By Neel Zaveri${NC}\n"
}

pause_and_return() {
  echo -e "\n${YELLOW}Press [Enter] to return to the main menu...${NC}"
  read
  main_menu
}

save_prompt() {
  echo -e "\n${YELLOW}Do you want to save this output to a file? [y/N]: ${NC}"
  read save_choice
  if [[ "$save_choice" =~ ^[Yy]$ ]]; then
    mv "$1" "saved_$1"
    echo -e "${GREEN}Output saved as: saved_$1${NC}"
  else
    rm -f "$1"
    echo -e "${YELLOW}Output discarded.${NC}"
  fi
}

run_module() {
  local mod=$1
  local ts=$(date +%Y%m%d_%H%M%S)
  local out="rootkhunter_module${mod}_$ts.log"

  case $mod in
    1)
      echo -e "${YELLOW}Checking for hidden processes...${NC}" | tee "$out"
      ps -eo pid > /tmp/pslist
      hidden=0
      for pid in /proc/[0-9]*; do
        p=${pid#/proc/}
        if ! grep -qw "$p" /tmp/pslist; then
          user=$(stat -c '%U' "$pid" 2>/dev/null)
          exe=$(readlink "$pid/exe" 2>/dev/null)
          cmd=$(cat "$pid/cmdline" 2>/dev/null | tr '\0' ' ')
          echo -e "${RED}[!!] Hidden process detected: PID=$p USER=$user CMD=${cmd:-N/A} EXE=${exe:-N/A}${NC}" | tee -a "$out"
          hidden=1
        fi
      done
      [[ $hidden -eq 0 ]] && echo -e "${GREEN}[OK] No hidden processes found.${NC}" | tee -a "$out"
      ;;
    2)
      echo -e "${YELLOW}Checking open network ports...${NC}" | tee "$out"
      ss -tulnp | tee -a "$out"
      echo -e "${GREEN}[OK] Port check done.${NC}" | tee -a "$out"
      ;;
    3)
      echo -e "${YELLOW}Scanning kernel modules for suspicious content...${NC}" | tee "$out"
      for m in $(lsmod | awk 'NR>1{print $1}'); do
        modpath=$(modinfo -n "$m" 2>/dev/null)
        if [[ -f "$modpath" ]]; then
          strings "$modpath" | grep -Ei "rootkit|malware|hook|hide|hideme|phide|backdoor" >/dev/null && \
            echo -e "${RED}[!!] Suspicious string in module $m ($modpath)${NC}" | tee -a "$out"
        fi
      done
      echo -e "${GREEN}[OK] Kernel module scan completed.${NC}" | tee -a "$out"
      ;;
    4)
      echo -e "${YELLOW}Scanning for hidden files and directories...${NC}" | tee "$out"
      for dir in /bin /sbin /usr/bin /usr/sbin /etc /dev /root /var /opt /home; do
        echo -e "${YELLOW}Scanning $dir...${NC}" | tee -a "$out"
        find "$dir" -maxdepth 1 -name ".*" ! -name "." ! -name ".." 2>/dev/null | while read -r h; do
          ls -ld "$h" 2>/dev/null | tee -a "$out"
        done
      done
      echo -e "${GREEN}[OK] Hidden file check completed.${NC}" | tee -a "$out"
      ;;
    5)
      echo -e "${YELLOW}Searching for SUID/SGID binaries...${NC}" | tee "$out"
      find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -lh {} \; 2>/dev/null | tee -a "$out"
      echo -e "${GREEN}[OK] SUID/SGID scan completed.${NC}" | tee -a "$out"
      ;;
    6)
      echo -e "${YELLOW}Looking for known-bad files (full path)...${NC}" | tee "$out"
      BADLIST=("rc2.d/S99evil" "bin/.sshbin" "initd/xyzbackdoor" ".rk" ".bd" ".socket" ".bat" ".evil" "backdoor.sh" "bdoor.sh" "reverse.sh" "install.sh" "runme.sh" "rdp" "rdp.sh")
      for pattern in "${BADLIST[@]}"; do
        matches=$(find / -path "*/$pattern" 2>/dev/null)
        if [[ -n "$matches" ]]; then
          while IFS= read -r match; do
            echo -e "${RED}[!!] Known-bad file found: $match${NC}" | tee -a "$out"
          done <<< "$matches"
        fi
      done
      echo -e "${GREEN}[OK] Known-bad file scan completed.${NC}" | tee -a "$out"
      ;;
    7)
      echo -e "${YELLOW}Verifying system binary integrity...${NC}" | tee "$out"
      if ! command -v debsums &>/dev/null; then
        echo -e "${RED}debsums not found. Install it via: sudo apt install debsums${NC}" | tee -a "$out"
      else
        for bin in /bin/ls /usr/bin/ssh /usr/bin/top; do
          pkg=$(dpkg -S "$bin" 2>/dev/null | awk -F: '{print $1}')
          [[ -n "$pkg" ]] && debsums -s "$pkg" >> "$out" 2>&1
        done
        echo -e "${GREEN}[OK] Binary hash integrity check completed.${NC}" | tee -a "$out"
      fi
      ;;
    8)
      echo -e "${YELLOW}Scanning critical binaries for suspicious strings...${NC}" | tee "$out"
      for b in /bin/ps /bin/netstat /usr/bin/top; do
        if [[ -f "$b" ]]; then
          strings "$b" | grep -Ei "hook|hide|rootkit|malware|rdp|remote|reverse" >/dev/null && \
          echo -e "${RED}[!!] Suspicious string found in $b${NC}" | tee -a "$out"
        fi
      done
      echo -e "${GREEN}[OK] Binary string scan completed.${NC}" | tee -a "$out"
      ;;
    *)
      echo -e "${RED}Invalid module selection.${NC}"
      return
      ;;
  esac

  save_prompt "$out"
  pause_and_return
}

main_menu() {
  show_banner
  echo -e "${YELLOW}Select a module to run:${NC}"
  echo "  1) Hidden Processes"
  echo "  2) Hidden Ports"
  echo "  3) Kernel Module Inspection"
  echo "  4) Hidden Files/Directories"
  echo "  5) SUID/SGID Binaries"
  echo "  6) Known-Bad Files"
  echo "  7) Hash Integrity Check"
  echo "  8) Suspicious Binary Strings"
  echo -e "${RED}  9) Exit${NC}"
  echo -n -e "${GREEN}Enter your choice [1-9]: ${NC}"
  read choice

  case $choice in
    [1-8]) run_module "$choice" ;;
    9) echo -e "${YELLOW}Exiting RKitHunt. Stay safe.${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid selection. Try again.${NC}"; sleep 1; main_menu ;;
  esac
}

# Start the tool
main_menu
