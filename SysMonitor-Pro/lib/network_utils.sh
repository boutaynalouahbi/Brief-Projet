#!/bin/bash
# Module de surveillance réseau

# Test de connectivité Internet
check_network_connectivity() {
    log_info "Test de connectivité Internet..."
    
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    local success_count=0
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 2 "$host" &> /dev/null; then
            log_success "Connectivité OK vers $host"
           
        else
            log_warning "Échec de connexion vers $host"
        fi
    done

}

monitor_network_interfaces() {
    log_info "État des interfaces réseau..."
    
    while read -r interface status addresses; do
        if [[ "$status" == "UP" ]]; then
            log_success "Interface $interface: $status ($addresses)"
        else
            log_warning "Interface $interface: $status"
        fi
    done < <(ip -brief addr show)
}


# Vérification des ports ouverts
check_open_ports() {
    log_info "Scan des ports ouverts en écoute..."
    
    if command -v ss &> /dev/null; then
        while read -r line; do
            port=$(echo "$line" | awk '{print $NF}' | awk -F: '{print $NF}')
            protocol=$(echo "$line" | awk '{print $1}')
            log_info "  Port $port ouvert ($protocol)"
        done < <(ss -tuln | grep LISTEN)
    elif command -v netstat &> /dev/null; then
        while read -r line; do
            port=$(echo "$line" | awk '{print $4}' | rev | cut -d':' -f1 | rev)
            log_info "  Port $port ouvert"
        done < <(netstat -tuln | grep LISTEN)
    fi
}


# Analyse simple du trafic réseau (débit cumulatif par interface)
monitor_network_traffic() {
    log_info "Analyse du trafic réseau (rx/tx octets)"
    
    if [[ -r /proc/net/dev ]]; then
        while read -r line; do
            log_info "$line"
        done < <(awk 'NR>2 {gsub(":","",$1); printf "  %s RX:%s TX:%s\n", $1, $2, $10}' /proc/net/dev)
    else
        log_warning "/proc/net/dev non accessible"
    fi
}



# Fonction globale de monitoring réseau
run_network_monitoring() {
    log_info "========== MONITORING RÉSEAU =========="
    
    check_network_connectivity
    local status=$?
    
    monitor_network_interfaces
    check_open_ports
    monitor_network_traffic  
    
    return $status
}


