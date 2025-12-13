#!/usr/bin/env bash
# =============================================================================
# File: scripts/azure-cost-estimate.sh
# Purpose: Estimate monthly Azure costs for Fawkes AKS infrastructure
# Usage: ./scripts/azure-cost-estimate.sh [--resource-group RG_NAME]
# Dependencies: az CLI, jq
# Owner: Fawkes Platform Team
# =============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP="${1:-fawkes-rg}"
BUDGET_TARGET_MIN=300
BUDGET_TARGET_MAX=500
LOCATION="eastus"

# Pricing data (USD/month, approximate as of Dec 2024)
# These are East US prices; adjust for your region
declare -A PRICES=(
    # AKS - Free control plane, only pay for nodes
    ["aks_control_plane"]=0
    
    # VM prices per month (730 hours)
    ["Standard_D2s_v3"]=70.08
    ["Standard_D4s_v3"]=140.16
    ["Standard_D8s_v3"]=280.32
    
    # Storage (per GB/month)
    ["managed_disk_p10"]=19.71      # 128 GB Premium SSD
    ["managed_disk_p20"]=46.08      # 512 GB Premium SSD
    ["storage_account_lrs"]=0.0208  # LRS per GB
    
    # Networking
    ["load_balancer_basic"]=0       # Basic LB is free
    ["load_balancer_standard"]=18.26
    ["public_ip_static"]=3.65
    ["outbound_data_gb"]=0.087      # First 5GB free, then $0.087/GB
    
    # Container Registry
    ["acr_basic"]=5
    ["acr_standard"]=20
    ["acr_premium"]=40
    
    # Log Analytics
    ["log_analytics_gb"]=2.76       # Per GB ingested
    ["log_analytics_estimated_gb"]=5 # Estimated GB per month
)

function print_header() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  Fawkes Azure AKS Cost Estimation${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

function check_prerequisites() {
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI (az) is not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed${NC}"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        echo -e "${YELLOW}Not logged in to Azure. Please run 'az login'${NC}"
        exit 1
    fi
}

function get_resource_config() {
    echo -e "${BLUE}Fetching resource configuration...${NC}"
    
    # Try to get actual deployed resources, fall back to defaults
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        echo -e "${GREEN}Found resource group: $RESOURCE_GROUP${NC}"
        DEPLOYED=true
    else
        echo -e "${YELLOW}Resource group not found. Using default configuration.${NC}"
        DEPLOYED=false
    fi
}

function calculate_aks_costs() {
    local system_nodes=2
    local system_vm_size="Standard_D4s_v3"
    local user_nodes_min=2
    local user_nodes_max=10
    local user_vm_size="Standard_D4s_v3"
    
    # AKS control plane (free for standard tier)
    local control_plane_cost=0
    
    # System node pool
    local system_node_cost=${PRICES[$system_vm_size]}
    local system_pool_cost=$(awk "BEGIN {printf \"%.2f\", $system_node_cost * $system_nodes}")
    
    # User node pool (estimate average between min and max)
    local user_nodes_avg=$(awk "BEGIN {printf \"%.0f\", ($user_nodes_min + $user_nodes_max) / 2}")
    local user_node_cost=${PRICES[$user_vm_size]}
    local user_pool_cost=$(awk "BEGIN {printf \"%.2f\", $user_node_cost * $user_nodes_avg}")
    
    # Total compute
    local total_compute=$(awk "BEGIN {printf \"%.2f\", $control_plane_cost + $system_pool_cost + $user_pool_cost}")
    
    echo ""
    echo -e "${BLUE}AKS Cluster Costs:${NC}"
    echo "  Control Plane (Standard):     \$$(printf "%7.2f" $control_plane_cost)"
    echo "  System Pool ($system_nodes x $system_vm_size): \$$(printf "%7.2f" $system_pool_cost)"
    echo "  User Pool (~$user_nodes_avg x $user_vm_size):  \$$(printf "%7.2f" $user_pool_cost)"
    echo "  ${GREEN}Subtotal (Compute):${NC}           \$$(printf "%7.2f" $total_compute)"
    
    echo "$total_compute"
}

function calculate_storage_costs() {
    # OS disks for nodes (128GB Premium SSD per node)
    local total_nodes=6  # 2 system + avg 4 user
    local os_disk_cost=${PRICES["managed_disk_p10"]}
    local total_os_disks=$(awk "BEGIN {printf \"%.2f\", $os_disk_cost * $total_nodes}")
    
    # Storage account (estimate 50GB for Terraform state and misc)
    local storage_gb=50
    local storage_cost=$(awk "BEGIN {printf \"%.2f\", $storage_gb * ${PRICES["storage_account_lrs"]}}")
    
    # Persistent volumes (estimate 100GB for platform services)
    local pv_cost=$(awk "BEGIN {printf \"%.2f\", ${PRICES["managed_disk_p10"]} * 1}")
    
    local total_storage=$(awk "BEGIN {printf \"%.2f\", $total_os_disks + $storage_cost + $pv_cost}")
    
    echo ""
    echo -e "${BLUE}Storage Costs:${NC}"
    echo "  OS Disks ($total_nodes x 128GB):      \$$(printf "%7.2f" $total_os_disks)"
    echo "  Storage Account (~${storage_gb}GB):   \$$(printf "%7.2f" $storage_cost)"
    echo "  Persistent Volumes (est):     \$$(printf "%7.2f" $pv_cost)"
    echo "  ${GREEN}Subtotal (Storage):${NC}           \$$(printf "%7.2f" $total_storage)"
    
    echo "$total_storage"
}

function calculate_networking_costs() {
    # Load Balancer (Standard)
    local lb_cost=${PRICES["load_balancer_standard"]}
    
    # Public IP (static)
    local ip_cost=${PRICES["public_ip_static"]}
    
    # Outbound data transfer (estimate 100GB/month)
    local data_gb=100
    local data_cost=$(awk "BEGIN {printf \"%.2f\", ($data_gb - 5) * ${PRICES["outbound_data_gb"]}}")
    
    local total_networking=$(awk "BEGIN {printf \"%.2f\", $lb_cost + $ip_cost + $data_cost}")
    
    echo ""
    echo -e "${BLUE}Networking Costs:${NC}"
    echo "  Load Balancer (Standard):     \$$(printf "%7.2f" $lb_cost)"
    echo "  Public IP (Static):           \$$(printf "%7.2f" $ip_cost)"
    echo "  Data Transfer (~${data_gb}GB):    \$$(printf "%7.2f" $data_cost)"
    echo "  ${GREEN}Subtotal (Networking):${NC}        \$$(printf "%7.2f" $total_networking)"
    
    echo "$total_networking"
}

function calculate_acr_costs() {
    local acr_sku="standard"
    local acr_cost=${PRICES["acr_${acr_sku}"]}
    
    # Storage for container images (estimate 10GB)
    local image_storage=10
    local storage_cost=$(awk "BEGIN {printf \"%.2f\", $image_storage * ${PRICES["storage_account_lrs"]}}")
    
    local total_acr=$(awk "BEGIN {printf \"%.2f\", $acr_cost + $storage_cost}")
    
    echo ""
    echo -e "${BLUE}Container Registry Costs:${NC}"
    echo "  ACR (Standard tier):          \$$(printf "%7.2f" $acr_cost)"
    echo "  Image Storage (~${image_storage}GB):     \$$(printf "%7.2f" $storage_cost)"
    echo "  ${GREEN}Subtotal (ACR):${NC}               \$$(printf "%7.2f" $total_acr)"
    
    echo "$total_acr"
}

function calculate_monitoring_costs() {
    local log_gb=${PRICES["log_analytics_estimated_gb"]}
    local cost_per_gb=${PRICES["log_analytics_gb"]}
    local total_monitoring=$(awk "BEGIN {printf \"%.2f\", $log_gb * $cost_per_gb}")
    
    echo ""
    echo -e "${BLUE}Monitoring Costs:${NC}"
    echo "  Log Analytics (~${log_gb}GB):      \$$(printf "%7.2f" $total_monitoring)"
    echo "  ${GREEN}Subtotal (Monitoring):${NC}        \$$(printf "%7.2f" $total_monitoring)"
    
    echo "$total_monitoring"
}

function calculate_misc_costs() {
    # Key Vault (mostly free, small cost for operations)
    local kv_cost=0.50
    
    # Bandwidth between services (estimate)
    local internal_bandwidth=2.00
    
    local total_misc=$(awk "BEGIN {printf \"%.2f\", $kv_cost + $internal_bandwidth}")
    
    echo ""
    echo -e "${BLUE}Other Costs:${NC}"
    echo "  Key Vault:                    \$$(printf "%7.2f" $kv_cost)"
    echo "  Internal Bandwidth:           \$$(printf "%7.2f" $internal_bandwidth)"
    echo "  ${GREEN}Subtotal (Other):${NC}             \$$(printf "%7.2f" $total_misc)"
    
    echo "$total_misc"
}

function print_summary() {
    local compute=$1
    local storage=$2
    local networking=$3
    local acr=$4
    local monitoring=$5
    local misc=$6
    
    local total=$(awk "BEGIN {printf \"%.2f\", $compute + $storage + $networking + $acr + $monitoring + $misc}")
    
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  TOTAL ESTIMATED MONTHLY COST${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
    printf "  Compute (AKS):                \$%7.2f\n" "$compute"
    printf "  Storage:                      \$%7.2f\n" "$storage"
    printf "  Networking:                   \$%7.2f\n" "$networking"
    printf "  Container Registry:           \$%7.2f\n" "$acr"
    printf "  Monitoring:                   \$%7.2f\n" "$monitoring"
    printf "  Other:                        \$%7.2f\n" "$misc"
    echo ""
    echo -e "  ${GREEN}TOTAL:                        \$$(printf "%7.2f" $total)${NC}"
    echo ""
    
    # Compare to budget
    echo -e "${BLUE}Budget Analysis:${NC}"
    echo "  Target Budget:  \$${BUDGET_TARGET_MIN} - \$${BUDGET_TARGET_MAX}/month"
    
    if (( $(awk "BEGIN {print ($total <= $BUDGET_TARGET_MAX)}") )); then
        echo -e "  ${GREEN}✓ Within budget target${NC}"
    else
        echo -e "  ${RED}✗ Exceeds budget target${NC}"
        local overage=$(awk "BEGIN {printf \"%.2f\", $total - $BUDGET_TARGET_MAX}")
        echo -e "  ${YELLOW}Overage: \$$overage${NC}"
        suggest_optimizations "$total"
    fi
    echo ""
}

function suggest_optimizations() {
    local total=$1
    
    echo ""
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${YELLOW}  Cost Optimization Suggestions${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo ""
    
    echo "1. Reduce VM sizes:"
    echo "   - Switch to Standard_D2s_v3 (~\$140/month savings)"
    echo ""
    
    echo "2. Optimize node pool sizing:"
    echo "   - Reduce user pool max from 10 to 5 nodes"
    echo "   - Consider spot instances for non-critical workloads"
    echo ""
    
    echo "3. Use Azure reservations:"
    echo "   - 1-year reserved instances: ~38% savings"
    echo "   - 3-year reserved instances: ~62% savings"
    echo ""
    
    echo "4. Optimize storage:"
    echo "   - Use Standard SSD instead of Premium (~50% savings)"
    echo "   - Right-size disk allocations"
    echo ""
    
    echo "5. Network optimization:"
    echo "   - Use Basic Load Balancer if possible (~\$18/month savings)"
    echo "   - Minimize outbound data transfer"
    echo ""
    
    echo "6. Container Registry:"
    echo "   - Use Basic tier for dev/test (~\$15/month savings)"
    echo "   - Clean up old/unused images regularly"
    echo ""
    
    echo "7. Monitoring:"
    echo "   - Set log retention to 7 days for dev environments"
    echo "   - Filter verbose logs at source"
    echo ""
}

function main() {
    print_header
    check_prerequisites
    get_resource_config
    
    compute=$(calculate_aks_costs)
    storage=$(calculate_storage_costs)
    networking=$(calculate_networking_costs)
    acr=$(calculate_acr_costs)
    monitoring=$(calculate_monitoring_costs)
    misc=$(calculate_misc_costs)
    
    print_summary "$compute" "$storage" "$networking" "$acr" "$monitoring" "$misc"
    
    echo -e "${BLUE}Note: These are estimates based on typical usage.${NC}"
    echo -e "${BLUE}Actual costs may vary based on usage patterns and region.${NC}"
    echo ""
    echo -e "${BLUE}For detailed cost analysis, use:${NC}"
    echo "  az cost-management query"
    echo "  or visit: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview"
    echo ""
}

main "$@"
