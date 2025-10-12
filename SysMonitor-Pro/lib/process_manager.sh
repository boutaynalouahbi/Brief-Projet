#!/bin/bash
# Module de gestion des processus

# Liste des processus les plus consommateurs
list_top_processes() {
    log_info "Top 10 processus consommateurs de CPU..."
    
    ps aux --sort=-%cpu | head -11 | tail -10 | while read line; do
        local user=$(echo "$line" | awk '{print $1}')
        local pid=$(echo "$line" | awk '{print $2}')
        local cpu=$(echo "$line" | awk '{print $3}')
        local mem=$(echo "$line" | awk '{print $4}')
        local command=$(echo "$line" | awk '{print $11}')
        
        log_info "  PID:$pid USER:$user CPU:${cpu}% MEM:${mem}% CMD:$command"
    done
}

# Détection des processus zombies
find_zombie_processes() {
    log_info "Recherche de processus zombies..."
    
    local zombie_count=$(ps aux | awk '$8 ~ /Z/ {print $0}' | wc -l)
    
    if (( zombie_count > 0 )); then
        log_warning "Trouvé $zombie_count processus zombie(s)"
        ps aux | awk '$8 ~ /Z/ {print $2, $11}' | while read pid cmd; do
            log_warning "  Zombie PID:$pid CMD:$cmd"
        done
        
        if (( zombie_count >= ZOMBIE_CRITICAL )); then
            return 2
        elif (( zombie_count >= ZOMBIE_WARNING )); then
            return 1
        fi
    else
        log_success "Aucun processus zombie"
    fi
    
    return 0
}

# Surveillance d'un processus spécifique
monitor_specific_process() {
    local process_name="$1"
    
    log_info "Surveillance du processus: $process_name"
    
    if pgrep -x "$process_name" > /dev/null; then
        local pid=$(pgrep -x "$process_name" | head -1)
        local cpu=$(ps -p "$pid" -o %cpu= | tr -d ' ')
        local mem=$(ps -p "$pid" -o %mem= | tr -d ' ')
        
        log_success "Processus $process_name actif (PID:$pid CPU:${cpu}% MEM:${mem}%)"
        return 0
    else
        log_error "Processus $process_name introuvable"
        return 1
    fi
}

# Fonction globale de monitoring des processus
run_process_monitoring() {
    log_info "========== MONITORING PROCESSUS =========="
    
    list_top_processes
    find_zombie_processes
    
    return 0
}

# Arrêt sécurisé d'un processus problématique
kill_problematic_process() {
    local process_name_or_pid="$1"
    local timeout_seconds="${2:-5}"

    if [[ -z "$process_name_or_pid" ]]; then
        log_error "Aucun processus spécifié pour l'arrêt"
        return 1
    fi

    local pids=()
    if [[ "$process_name_or_pid" =~ ^[0-9]+$ ]]; then
        pids=("$process_name_or_pid")
    else
        mapfile -t pids < <(pgrep -x "$process_name_or_pid" || true)
    fi

    if (( ${#pids[@]} == 0 )); then
        log_warning "Aucun PID trouvé pour '$process_name_or_pid'"
        return 0
    fi

    for pid in "${pids[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            log_warning "PID $pid inexistant"
            continue
        fi

        log_warning "Envoi SIGTERM au PID $pid"
        kill -15 "$pid" 2>/dev/null || true

        local waited=0
        while kill -0 "$pid" 2>/dev/null && (( waited < timeout_seconds )); do
            sleep 1
            ((waited++))
        done

        if kill -0 "$pid" 2>/dev/null; then
            log_critical "Forçage SIGKILL du PID $pid"
            kill -9 "$pid" 2>/dev/null || true
        else
            log_success "Processus $pid arrêté proprement"
        fi
    done

    return 0
}