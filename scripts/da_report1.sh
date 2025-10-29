#!/bin/bash
################################################################################
# da_report.sh - DirectAdmin Account & Domain CSV Report
#
# Description:
#   Generates a CSV report of all DirectAdmin accounts and domains including:
#   - Account name
#   - Disk space usage (KB)
#   - Domain name
#   - PHP version (user default)
#   - Hostname
#
# Usage:
#   ./da_report.sh [OPTIONS]
#
# Options:
#   -o, --output FILE    Output file path (default: da_report_YYYYMMDD_HHMMSS.csv)
#   -j, --json           Output in JSON format instead of CSV
#   -h, --help           Display this help message
#
# Environment Variables:
#   DA_ADMIN_CLI         Path to DirectAdmin CLI (default: /usr/local/directadmin/dataskq)
#   DA_DATA_DIR          Path to DA data directory (default: /usr/local/directadmin/data)
#   OUTPUT_DIR           Output directory (default: current directory)
#
# Requirements:
#   - DirectAdmin installation
#   - Root or admin access
#   - jq (for JSON output, optional)
#
# NIS2 Compliance:
#   This report helps maintain asset inventory for DNS/domain infrastructure,
#   supporting governance and audit requirements under NIS2 Directive (EU) 2022/2555
#
################################################################################

set -euo pipefail
IFS=$'\n\t'

# Configuration with environment overrides
DA_ADMIN_CLI="${DA_ADMIN_CLI:-/usr/local/directadmin/dataskq}"
DA_DATA_DIR="${DA_DATA_DIR:-/usr/local/directadmin/data}"
OUTPUT_DIR="${OUTPUT_DIR:-.}"
OUTPUT_FORMAT="csv"
OUTPUT_FILE=""
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

# Display usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Generate a CSV/JSON report of DirectAdmin accounts and domains.

OPTIONS:
    -o, --output FILE    Output file path (default: da_report_${TIMESTAMP}.csv)
    -j, --json           Output in JSON format instead of CSV
    -h, --help           Display this help message

ENVIRONMENT VARIABLES:
    DA_ADMIN_CLI         Path to DirectAdmin CLI (default: /usr/local/directadmin/dataskq)
    DA_DATA_DIR          Path to DA data directory (default: /usr/local/directadmin/data)
    OUTPUT_DIR           Output directory (default: current directory)

EXAMPLES:
    # Generate default CSV report
    $(basename "$0")

    # Generate JSON report
    $(basename "$0") --json

    # Custom output location
    $(basename "$0") -o /var/reports/domains.csv

EOF
    exit 0
}

# Log messages with timestamp
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" >&2
}

# Log error messages
error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Log warning messages
warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Escape CSV field (handles quotes and commas)
csv_escape() {
    local field="$1"
    # If field contains comma, quote, or newline, wrap in quotes and escape quotes
    if [[ "$field" =~ [,\"] ]]; then
        field="${field//\"/\"\"}"  # Escape quotes by doubling them
        echo "\"$field\""
    else
        echo "$field"
    fi
}

# Check if DirectAdmin is installed and accessible
check_da_installation() {
    if [[ ! -f "$DA_ADMIN_CLI" ]]; then
        error "DirectAdmin CLI not found at: $DA_ADMIN_CLI"
        error "Please set DA_ADMIN_CLI environment variable or ensure DirectAdmin is installed"
        exit 1
    fi

    if [[ ! -d "$DA_DATA_DIR" ]]; then
        error "DirectAdmin data directory not found at: $DA_DATA_DIR"
        error "Please set DA_DATA_DIR environment variable"
        exit 1
    fi

    if [[ ! -r "$DA_ADMIN_CLI" ]]; then
        error "Cannot read DirectAdmin CLI. Run this script with appropriate permissions (root/admin)"
        exit 1
    fi
}

# Get list of all users
get_users() {
    echo "CMD_API_SHOW_USERS" | "$DA_ADMIN_CLI" | grep -oP '(?<=list\[)[^\]]+' || true
}

# Get user's disk space usage in KB
get_user_quota() {
    local username="$1"
    local quota_file="${DA_DATA_DIR}/users/${username}/user.usage"

    if [[ -f "$quota_file" ]]; then
        grep -oP '(?<=quota=)[0-9]+' "$quota_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Get user's domains
get_user_domains() {
    local username="$1"
    local domains_file="${DA_DATA_DIR}/users/${username}/domains.list"

    if [[ -f "$domains_file" ]]; then
        cat "$domains_file"
    fi
}

# Get user's default PHP version
get_user_php_version() {
    local username="$1"
    local user_conf="${DA_DATA_DIR}/users/${username}/user.conf"

    if [[ -f "$user_conf" ]]; then
        grep -oP '(?<=php1_select=)[^\s]+' "$user_conf" 2>/dev/null || echo "default"
    else
        echo "default"
    fi
}

# Get domain's hostname (A record or primary IP)
get_domain_hostname() {
    local domain="$1"
    local ip_address

    # Try to resolve domain's IP
    ip_address=$(dig +short "$domain" A | head -n1 2>/dev/null || echo "unresolved")

    if [[ -n "$ip_address" && "$ip_address" != "unresolved" ]]; then
        echo "$ip_address"
    else
        echo "unresolved"
    fi
}

# Generate CSV report
generate_csv_report() {
    local output_file="$1"
    local temp_file="${output_file}.tmp"

    log "Generating CSV report..."

    # Write CSV header
    echo "account,space_kb,domain,domain_php_version,hostname" > "$temp_file"

    local user_count=0
    local domain_count=0

    # Process each user
    while IFS= read -r username; do
        [[ -z "$username" ]] && continue

        ((user_count++))
        log "Processing user: $username ($user_count)"

        local quota
        quota=$(get_user_quota "$username")

        local php_version
        php_version=$(get_user_php_version "$username")

        # Process each domain for this user
        while IFS= read -r domain; do
            [[ -z "$domain" ]] && continue

            ((domain_count++))

            local hostname
            hostname=$(get_domain_hostname "$domain")

            # Write CSV row with proper escaping
            echo "$(csv_escape "$username"),$(csv_escape "$quota"),$(csv_escape "$domain"),$(csv_escape "$php_version"),$(csv_escape "$hostname")" >> "$temp_file"

        done < <(get_user_domains "$username")

    done < <(get_users)

    # Move temp file to final location
    mv "$temp_file" "$output_file"

    log "Report generated successfully!"
    log "Users processed: $user_count"
    log "Domains processed: $domain_count"
    log "Output file: $output_file"
}

# Generate JSON report
generate_json_report() {
    local output_file="$1"
    local temp_file="${output_file}.tmp"

    log "Generating JSON report..."

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        error "jq is required for JSON output but not found"
        error "Install with: yum install jq (RHEL/CentOS) or apt-get install jq (Debian/Ubuntu)"
        exit 1
    fi

    local user_count=0
    local domain_count=0
    local json_array="["

    # Process each user
    while IFS= read -r username; do
        [[ -z "$username" ]] && continue

        ((user_count++))
        log "Processing user: $username ($user_count)"

        local quota
        quota=$(get_user_quota "$username")

        local php_version
        php_version=$(get_user_php_version "$username")

        # Process each domain for this user
        while IFS= read -r domain; do
            [[ -z "$domain" ]] && continue

            ((domain_count++))

            local hostname
            hostname=$(get_domain_hostname "$domain")

            # Add comma separator if not first entry
            [[ "$json_array" != "[" ]] && json_array+=","

            # Build JSON object
            json_array+=$(jq -n \
                --arg account "$username" \
                --arg space_kb "$quota" \
                --arg domain "$domain" \
                --arg php_version "$php_version" \
                --arg hostname "$hostname" \
                '{account: $account, space_kb: $space_kb, domain: $domain, domain_php_version: $php_version, hostname: $hostname}')

        done < <(get_user_domains "$username")

    done < <(get_users)

    json_array+="]"

    # Pretty print JSON
    echo "$json_array" | jq '.' > "$temp_file"

    # Move temp file to final location
    mv "$temp_file" "$output_file"

    log "Report generated successfully!"
    log "Users processed: $user_count"
    log "Domains processed: $domain_count"
    log "Output file: $output_file"
}

################################################################################
# Main
################################################################################

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Set default output file if not specified
if [[ -z "$OUTPUT_FILE" ]]; then
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        OUTPUT_FILE="${OUTPUT_DIR}/da_report_${TIMESTAMP}.json"
    else
        OUTPUT_FILE="${OUTPUT_DIR}/da_report_${TIMESTAMP}.csv"
    fi
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Pre-flight checks
check_da_installation

# Generate report
log "Starting DirectAdmin report generation"
log "Format: $OUTPUT_FORMAT"
log "Output: $OUTPUT_FILE"

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    generate_json_report "$OUTPUT_FILE"
else
    generate_csv_report "$OUTPUT_FILE"
fi

log "Done!"
exit 0
