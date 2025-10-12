#!/bin/bash
# Module de vérification des services

# Vérification des services critiques
check_critical_services() {
    log_info "Vérification des services critiques..."
    
    local failed_services=()
    local status=0
    
    for service in "${CRITICAL_SERVICES[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "Service $service: ACTIF"
        else
            log_error "Service $service: INACTIF"
            failed_services+=("$service")
            status=2
        fi
    done
    
    if (( ${#failed_services[@]} > 0 )); then
        log_critical "Services en échec: ${failed_services[*]}"
    fi
    
    return $status
}

# Redémarrage automatique d'un service
restart_failed_service() {
    local service="$1"
    
    log_warning "Tentative de redémarrage du service: $service"
    
    if systemctl restart "$service" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$service"; then
            log_success "Service $service redémarré avec succès"
            return 0
        fi
    fi
    
    log_error "Échec du redémarrage du service $service"
    return 1
}

# Vérification des logs d'erreurs d'un service
check_service_logs() {
    local service="$1"
    local lines="${2:-20}"
    
    log_info "Dernières erreurs du service $service:"
    
    if command -v journalctl &> /dev/null; then
        journalctl -u "$service" -p err -n "$lines" --no-pager 2>/dev/null | \
        while read -r line; do
            log_warning "  $line"
        done
    fi
}

# Fonction globale de monitoring des services
run_service_monitoring() {
    log_info "========== MONITORING SERVICES =========="
    
    check_critical_services
    local status=$?
    
    # Si des services sont en échec, tenter de les redémarrer
    if (( status > 0 )); then
        for service in "${CRITICAL_SERVICES[@]}"; do
            if ! systemctl is-active --quiet "$service"; then
                restart_failed_service "$service"
                check_service_logs "$service" 10
            fi
        done
    fi
    
    return $status
}

# Validation basique de la configuration d'un service systemd
validate_service_config() {
    local service="$1"
    if [[ -z "$service" ]]; then
        log_error "Aucun service fourni pour la validation"
        return 1
    fi

    # Vérifier l'existence de l'unité
    if ! systemctl list-unit-files | awk '{print $1}' | grep -qx "${service}.service"; then
        log_error "Unité systemd introuvable: ${service}.service"
        return 1
    fi

    # Vérifier la validité via systemd-analyze si disponible
    if command -v systemd-analyze &>/dev/null; then
        if systemd-analyze verify "/etc/systemd/system/${service}.service" "/lib/systemd/system/${service}.service" 2>&1 | grep -qi "error"; then
            log_error "Configuration systemd invalide pour ${service}"
            return 1
        fi
    fi

    log_success "Configuration systemd valide pour ${service}"
    return 0
}