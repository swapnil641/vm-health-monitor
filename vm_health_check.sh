#!/bin/bash

###############################################################################
# VM Health Check Script
# 
# Purpose: Analyze the health of a virtual machine based on CPU, memory, 
#          and disk space utilization.
# 
# Health Status:
#   - HEALTHY: All parameters are below 60% utilization
#   - NOT HEALTHY: Any parameter is 60% or above
#
# Usage:
#   ./vm_health_check.sh              # Check health status
#   ./vm_health_check.sh explain      # Check health status with explanation
#
# Target: Ubuntu Linux
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Thresholds
THRESHOLD=60

# Variables to store values
CPU_USAGE=0
MEMORY_USAGE=0
DISK_USAGE=0

# Health status
HEALTH_STATUS="HEALTHY"
REASONS=()

###############################################################################
# Function: Get CPU Usage
# Returns: CPU usage percentage
###############################################################################
get_cpu_usage() {
    # Using top command to get average CPU usage
    # Alternative method that works on most systems
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | cut -d'%' -f1)
    
    # Handle potential decimal values
    cpu_usage=$(printf "%.0f" "$cpu_usage")
    
    echo "$cpu_usage"
}

###############################################################################
# Function: Get Memory Usage
# Returns: Memory usage percentage
###############################################################################
get_memory_usage() {
    # Using free command to get memory usage
    local memory_info=$(free | grep Mem)
    local total=$(echo $memory_info | awk '{print $2}')
    local used=$(echo $memory_info | awk '{print $3}')
    
    local memory_usage=$((used * 100 / total))
    
    echo "$memory_usage"
}

###############################################################################
# Function: Get Disk Usage
# Returns: Disk usage percentage for root filesystem
###############################################################################
get_disk_usage() {
    # Using df command to get disk usage of root filesystem
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    
    echo "$disk_usage"
}

###############################################################################
# Function: Check Health Status
# Analyzes CPU, Memory, and Disk usage
###############################################################################
check_health() {
    echo "Analyzing VM Health..."
    echo "======================="
    echo ""
    
    # Get current usage values
    CPU_USAGE=$(get_cpu_usage)
    MEMORY_USAGE=$(get_memory_usage)
    DISK_USAGE=$(get_disk_usage)
    
    # Reset reasons array
    REASONS=()
    
    # Check CPU usage
    if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
        HEALTH_STATUS="NOT HEALTHY"
        REASONS+=("CPU usage is ${CPU_USAGE}% (threshold: ${THRESHOLD}%)")
    fi
    
    # Check Memory usage
    if [ "$MEMORY_USAGE" -ge "$THRESHOLD" ]; then
        HEALTH_STATUS="NOT HEALTHY"
        REASONS+=("Memory usage is ${MEMORY_USAGE}% (threshold: ${THRESHOLD}%)")
    fi
    
    # Check Disk usage
    if [ "$DISK_USAGE" -ge "$THRESHOLD" ]; then
        HEALTH_STATUS="NOT HEALTHY"
        REASONS+=("Disk usage is ${DISK_USAGE}% (threshold: ${THRESHOLD}%)")
    fi
}

###############################################################################
# Function: Display Health Status
###############################################################################
display_status() {
    if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
        echo -e "${GREEN}Status: ✓ HEALTHY${NC}"
    else
        echo -e "${RED}Status: ✗ NOT HEALTHY${NC}"
    fi
}

###############################################################################
# Function: Display Metrics
###############################################################################
display_metrics() {
    echo ""
    echo "Current Resource Utilization:"
    echo "-----------------------------"
    
    # CPU Usage
    if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  CPU Usage:    ${RED}${CPU_USAGE}%${NC}"
    else
        echo -e "  CPU Usage:    ${GREEN}${CPU_USAGE}%${NC}"
    fi
    
    # Memory Usage
    if [ "$MEMORY_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  Memory Usage: ${RED}${MEMORY_USAGE}%${NC}"
    else
        echo -e "  Memory Usage: ${GREEN}${MEMORY_USAGE}%${NC}"
    fi
    
    # Disk Usage
    if [ "$DISK_USAGE" -ge "$THRESHOLD" ]; then
        echo -e "  Disk Usage:   ${RED}${DISK_USAGE}%${NC}"
    else
        echo -e "  Disk Usage:   ${GREEN}${DISK_USAGE}%${NC}"
    fi
    
    echo ""
}

###############################################################################
# Function: Display Explanation
###############################################################################
display_explanation() {
    echo ""
    echo "Health Status Explanation:"
    echo "============================"
    
    if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
        echo -e "${GREEN}The VM is healthy!${NC}"
        echo ""
        echo "All resource parameters are within acceptable limits:"
        echo "  • CPU usage (${CPU_USAGE}%) is below ${THRESHOLD}%"
        echo "  • Memory usage (${MEMORY_USAGE}%) is below ${THRESHOLD}%"
        echo "  • Disk usage (${DISK_USAGE}%) is below ${THRESHOLD}%"
        echo ""
        echo "Recommendation: No immediate action required."
    else
        echo -e "${RED}The VM is NOT healthy!${NC}"
        echo ""
        echo "The following issues were detected:"
        echo ""
        
        local count=1
        for reason in "${REASONS[@]}"; do
            echo "  $count. $reason"
            ((count++))
        done
        
        echo ""
        echo "Recommendations:"
        
        # Check which resource is problematic
        if [[ " ${REASONS[@]} " =~ "CPU" ]]; then
            echo "  • ${YELLOW}CPU Usage High:${NC}"
            echo "    - Check running processes: ps aux --sort=-%cpu | head -10"
            echo "    - Consider stopping unnecessary services"
            echo "    - Monitor with: top or htop"
        fi
        
        if [[ " ${REASONS[@]} " =~ "Memory" ]]; then
            echo "  • ${YELLOW}Memory Usage High:${NC}"
            echo "    - Check memory consuming processes: ps aux --sort=-%mem | head -10"
            echo "    - Consider increasing RAM or optimizing applications"
            echo "    - Check for memory leaks"
        fi
        
        if [[ " ${REASONS[@]} " =~ "Disk" ]]; then
            echo "  • ${YELLOW}Disk Usage High:${NC}"
            echo "    - Find largest directories: du -sh /* | sort -rh | head -10"
            echo "    - Clean up temporary files and logs"
            echo "    - Consider archiving old data or increasing disk capacity"
            echo "    - Check: sudo ncdu / (install ncdu if needed)"
        fi
    fi
    
    echo ""
}

###############################################################################
# Function: Display Usage
###############################################################################
display_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no arguments)     Display VM health status with metrics"
    echo "  explain            Display health status with detailed explanation"
    echo "  -h, --help         Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0                 # Check health status"
    echo "  $0 explain         # Check health with explanation"
    echo ""
}

###############################################################################
# Main Script Logic
###############################################################################

# Parse command line arguments
case "${1}" in
    "explain")
        EXPLAIN=true
        ;;
    "-h"|"--help")
        display_usage
        exit 0
        ;;
    "")
        EXPLAIN=false
        ;;
    *)
        echo "Error: Invalid argument '${1}'"
        echo ""
        display_usage
        exit 1
        ;;
esac

# Check health
check_health

# Display results
display_status
display_metrics

# Display explanation if requested
if [ "$EXPLAIN" = true ]; then
    display_explanation
fi

# Exit with appropriate status code
if [ "$HEALTH_STATUS" = "HEALTHY" ]; then
    exit 0
else
    exit 1
fi
