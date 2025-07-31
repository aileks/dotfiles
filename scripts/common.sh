#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    local upper_title=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    local title=" ${upper_title} "
    local width=60
    local title_len=${#title}

    if [ "$title_len" -gt "$((width - 2))" ]; then
        echo
        echo -e "${PURPLE}${title}${NC}"
        echo
        return
    fi

    local padding_left=$(((width - title_len - 2) / 2))
    [ $padding_left -lt 0 ] && padding_left=0

    local padding_right=$((width - title_len - padding_left - 2))
    [ $padding_right -lt 0 ] && padding_right=0

    echo
    echo -e "${BLUE}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${NC}"
    echo -e "${BLUE}║$(printf '%*s' $padding_left '')${PURPLE}${title}${BLUE}$(printf '%*s' $padding_right '')║${NC}"
    echo -e "${BLUE}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${NC}"
    echo
}

print_info() {
    echo
    echo -e "${CYAN}ℹ $1${NC}"
    echo
}

print_success() {
    echo
    echo -e "${GREEN}✓ $1${NC}"
    echo
}

print_warning() {
    echo
    echo -e "${YELLOW}⚠ $1${NC}"
    echo
}

print_error() {
    echo
    echo -e "${RED}✗ $1${NC}"
    echo
}

prompt_user() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        echo -e "${YELLOW}$question $prompt${NC}"
        read -r response

        if [[ -z "$response" ]]; then
            response="$default"
        fi

        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${NC}" ;;
        esac
    done
}
