#!/bin/bash


set -e
set -u
set -o pipefail

BASE_DIR="$(dirname "$0")"

source "$BASE_DIR/config/settings.conf"
source "$BASE_DIR/config/thresholds.conf"
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/lib/system_monitor.sh"
source "$BASE_DIR/lib/process_manager.sh"
source "$BASE_DIR/lib/service_checker.sh"
source "$BASE_DIR/lib/network_utils.sh"

validate_prerequisites() {
    command -v systemctl >/dev/null 2>&1 || { log_error "systemctl manquant"; return 1; }
    command -v ip >/dev/null 2>&1 || { log_error "ip manquant"; return 1; }
    mkdir -p "$LOG_DIR" "$REPORT_DIR"
    return 0
}

run_system_monitoring() {
    log_info "=== Surveillance Système ==="
    monitor_cpu_usage
    monitor_memory_usage
    monitor_disk_space
    monitor_system_load
}

run_process_monitoring() {
    log_info "=== Gestion des Processus ==="
    list_top_processes
    find_zombie_processes
    monitor_specific_process "sshd"
}

run_service_monitoring() {
    log_info "=== Vérification Services ==="
    check_critical_services
}

run_network_monitoring() {
    log_info "=== Surveillance Réseau ==="
    check_network_connectivity
    monitor_network_interfaces
    check_open_ports
}

add_system_metrics_section() {
    echo "<div class='section'><h2>Surveillance Système</h2><pre>"
    top -bn1 | head -n 10
    echo "</pre></div>"
}

add_process_analysis_section() {
    echo "<div class='section'><h2>Processus</h2><pre>"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 10
    echo "</pre></div>"
}

add_service_status_section() {
    echo "<div class='section'><h2>Services</h2><pre>"
    systemctl list-units --type=service --state=running | head -n 15
    echo "</pre></div>"
}

add_network_analysis_section() {
    echo "<div class='section'><h2>Réseau</h2><pre>"
    ip -br addr show
    echo "</pre></div>"
}

generate_system_report() {
    if [[ -z "$REPORT_DIR" ]]; then
        log_error "REPORT_DIR non défini !"
        return 1
    fi

    local report_file="${REPORT_DIR}/system_report_$(date +%Y%m%d_%H%M%S).html"
    mkdir -p "$(dirname "$report_file")" || { log_error "Impossible de créer le dossier $(dirname "$report_file")"; return 1; }
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SysMonitor Pro - Rapport Système</title>
    <style>
        body { font-family: Arial; margin: 20px; background: #f4f4f4; }
        .header { background: #2c3e50; color: white; padding: 20px; }
        .section { background: white; margin: 20px 0; padding: 15px; border-radius: 8px; }
        h1, h2 { color: #2c3e50; }
    </style>
</head>
<body>
<div class="header">
<h1>Rapport SysMonitor Pro</h1>
<p>Généré le : $(date)</p>
<p>Serveur : $(hostname)</p>
</div>
EOF

    add_system_metrics_section >> "$report_file"
    add_process_analysis_section >> "$report_file"
    add_service_status_section >> "$report_file"
    add_network_analysis_section >> "$report_file"
    echo "</body></html>" >> "$report_file"

    log_info "Rapport généré : $report_file"
}


cleanup() {
    log_info "Nettoyage en cours..."
    exit $?
}
trap cleanup EXIT INT TERM

main() {
    log_info "=== Démarrage SysMonitor Pro ==="
    validate_prerequisites
    run_system_monitoring
    run_process_monitoring
    run_service_monitoring
    run_network_monitoring
    generate_system_report
    log_info "=== Monitoring terminé avec succès ==="
}

main "$@"
