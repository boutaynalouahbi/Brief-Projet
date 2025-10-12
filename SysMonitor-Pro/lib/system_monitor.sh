#!/bin/bash
# Module de monitoring système

# Surveillance de l'utilisation CPU
monitor_cpu_usage() {
    log_info "Vérification utilisation CPU..."
    
    # Méthode 1: Utiliser top pour obtenir le CPU idle
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
    local cpu_usage=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "0")
    
    # Arrondir le résultat
    cpu_usage=$(printf "%.0f" "$cpu_usage")
    
    log_info "Utilisation CPU: ${cpu_usage}%"
    
    # Vérification des seuils
    if (( $(echo "$cpu_usage >= $CPU_CRITICAL" | bc -l) )); then
        log_critical "CPU critique: ${cpu_usage}% (seuil: ${CPU_CRITICAL}%)"
        return 2
    elif (( $(echo "$cpu_usage >= $CPU_WARNING" | bc -l) )); then
        log_warning "CPU élevé: ${cpu_usage}% (seuil: ${CPU_WARNING}%)"
        return 1
    else
        log_success "CPU normal: ${cpu_usage}%"
        return 0
    fi
}

# Surveillance de la mémoire
monitor_memory_usage() {
    log_info "Vérification utilisation mémoire..."
    
    # Lecture de /proc/meminfo
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    
    # Calcul du pourcentage utilisé
    local mem_used=$((mem_total - mem_available))
    local mem_percent=$((mem_used * 100 / mem_total))
    
    log_info "Utilisation mémoire: ${mem_percent}% (${mem_used}kB / ${mem_total}kB)"
    
    # Vérification des seuils
    if (( mem_percent >= MEMORY_CRITICAL )); then
        log_critical "Mémoire critique: ${mem_percent}% (seuil: ${MEMORY_CRITICAL}%)"
        return 2
    elif (( mem_percent >= MEMORY_WARNING )); then
        log_warning "Mémoire élevée: ${mem_percent}% (seuil: ${MEMORY_WARNING}%)"
        return 1
    else
        log_success "Mémoire normale: ${mem_percent}%"
        return 0
    fi
}

# Surveillance de l'espace disque
monitor_disk_space() {
    log_info "Vérification espace disque..."
    
    local critical_found=false
    local warning_found=false
    
    # Parcourir toutes les partitions
    while IFS= read -r line; do
        local partition=$(echo "$line" | awk '{print $1}')
        local usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        local mount_point=$(echo "$line" | awk '{print $6}')
        
        log_info "Partition $mount_point ($partition): ${usage}%"
        
        if (( usage >= DISK_CRITICAL )); then
            log_critical "Disque critique sur $mount_point: ${usage}% (seuil: ${DISK_CRITICAL}%)"
            critical_found=true
        elif (( usage >= DISK_WARNING )); then
            log_warning "Disque élevé sur $mount_point: ${usage}% (seuil: ${DISK_WARNING}%)"
            warning_found=true
        fi
    done < <(df -h | grep '^/dev/' | grep -v '/boot')
    
    if $critical_found; then
        return 2
    elif $warning_found; then
        return 1
    else
        log_success "Tous les disques sont OK"
        return 0
    fi
}

# Surveillance du load average
monitor_system_load() {
    log_info "Vérification charge système (load average)..."
    
    # Récupérer le load average 1 minute
    local load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    
    # Nombre de CPU
    local cpu_count=$(nproc)
    
    # Load normalisé par CPU
    local load_per_cpu=$(echo "$load_1min / $cpu_count" | bc -l | awk '{printf "%.2f", $0}')
    
    log_info "Load average: $load_1min (${cpu_count} CPUs) - Load/CPU: $load_per_cpu"
    
    if (( $(echo "$load_per_cpu >= $LOAD_CRITICAL" | bc -l) )); then
        log_critical "Load critique: $load_per_cpu par CPU (seuil: $LOAD_CRITICAL)"
        return 2
    elif (( $(echo "$load_per_cpu >= $LOAD_WARNING" | bc -l) )); then
        log_warning "Load élevé: $load_per_cpu par CPU (seuil: $LOAD_WARNING)"
        return 1
    else
        log_success "Load normal: $load_per_cpu par CPU"
        return 0
    fi
}

# Fonction globale de monitoring système
run_system_monitoring() {
    log_info "========== MONITORING SYSTÈME =========="
    
    local status=0
    
    monitor_cpu_usage || ((status+=$?))
    monitor_memory_usage || ((status+=$?))
    monitor_disk_space || ((status+=$?))
    monitor_system_load || ((status+=$?))
    
    if (( status >= 8 )); then
        log_critical "Problèmes critiques détectés sur le système"
        return 2
    elif (( status > 0 )); then
        log_warning "Avertissements détectés sur le système"
        return 1
    else
        log_success "Système en bonne santé"
        return 0
    fi
}