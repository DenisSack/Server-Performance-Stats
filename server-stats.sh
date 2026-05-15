#!/bin/bash

# Server Stats Script - Analyzes basic server performance stats
# Usage: ./server-stats.sh

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# === OS INFORMATION ===
print_header "OS Information"
echo -e "${GREEN}OS Version:${NC}"
cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2
echo -e "${GREEN}Kernel:${NC} $(uname -r)"
echo -e "${GREEN}Hostname:${NC} $(hostname)"

# === UPTIME ===
print_header "System Uptime"
uptime

# === CPU USAGE ===
print_header "CPU Usage"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo -e "${GREEN}Total CPU Usage:${NC} ${RED}${cpu_usage}%${NC}"

# === LOAD AVERAGE ===
print_header "Load Average"
load_avg=$(cat /proc/loadavg)
echo -e "${GREEN}Load Average:${NC} $load_avg"

# === MEMORY USAGE ===
print_header "Memory Usage"
memory_info=$(free -h | grep Mem)
total_mem=$(echo $memory_info | awk '{print $2}')
used_mem=$(echo $memory_info | awk '{print $3}')
free_mem=$(echo $memory_info | awk '{print $4}')
mem_percentage=$(free | grep Mem | awk '{printf("%.2f", ($3/$2) * 100)}')

echo -e "${GREEN}Total Memory:${NC} $total_mem"
echo -e "${GREEN}Used Memory:${NC} ${RED}$used_mem${NC}"
echo -e "${GREEN}Free Memory:${NC} ${GREEN}$free_mem${NC}"
echo -e "${GREEN}Memory Usage:${NC} ${RED}${mem_percentage}%${NC}"

# === DISK USAGE ===
print_header "Disk Usage"
df -h / | tail -1 | awk '{
    printf "%-30s %10s %10s %10s %8s\n", "Filesystem", "Size", "Used", "Available", "Use%"
    printf "%-30s %10s %10s %10s %8s\n", $1, $2, $3, $4, $5
}'

echo -e "\n${GREEN}All Mounted Filesystems:${NC}"
df -h | tail -n +2 | awk '{printf "%-25s %10s %10s %10s %8s\n", $1, $2, $3, $4, $5}'

# === TOP 5 PROCESSES BY CPU USAGE ===
print_header "Top 5 Processes by CPU Usage"
ps aux --sort=-%cpu | head -n 6 | awk 'NR>1 {printf "%-8s %-6s %8s %s\n", $1, $2, $3"%", $11}'

# === TOP 5 PROCESSES BY MEMORY USAGE ===
print_header "Top 5 Processes by Memory Usage"
ps aux --sort=-%mem | head -n 6 | awk 'NR>1 {printf "%-8s %-6s %8s %s\n", $1, $2, $4"%", $11}'

# === LOGGED IN USERS ===
print_header "Logged In Users"
who

# === FAILED LOGIN ATTEMPTS ===
print_header "Failed Login Attempts (Last 24 hours)"
if [ -f /var/log/auth.log ]; then
    failed_count=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
    echo -e "${GREEN}Failed SSH/Login Attempts:${NC} ${RED}$failed_count${NC}"
    echo -e "\n${GREEN}Recent Failed Attempts:${NC}"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | awk '{print $1, $2, $3, $(NF-5), $(NF-3), $(NF-1)}' || echo "No recent failed attempts"
else
    echo "Auth log file not readable"
fi

# === NETWORK STATISTICS ===
print_header "Network Interfaces"
ip -s link show | grep -E "^\d+:|RX|TX" | paste - - | sed 's/RX packets//' | sed 's/TX packets//'

echo -e "\n${BLUE}========================================${NC}"
echo -e "${CYAN}Report Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}========================================${NC}\n"
