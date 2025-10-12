#!/bin/bash


# Couleurs pour l'affichage terminal
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction principale de log
log_with_level() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/sysmonitor.log"
    
    # Créer le dossier de logs s'il n'existe pas
    mkdir -p "$LOG_DIR"
    
    # Format: [TIMESTAMP] [LEVEL] MESSAGE
    local log_entry="[$timestamp] [$level] $message"
    
    # Écrire dans le fichier
    echo "$log_entry" >> "$log_file"
    
    # Affichage coloré selon le niveau
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        "CRITICAL")
            echo -e "${RED}[CRITICAL]${NC} $message"
            # Envoi vers syslog pour les erreurs critiques
            logger -p local0.err "SysMonitor: $message"
            ;;
    esac
}

# Fonctions raccourcis pour chaque niveau
log_info() {
    log_with_level "INFO" "$1"
}

log_success() {
    log_with_level "SUCCESS" "$1"
}

log_warning() {
    log_with_level "WARNING" "$1"
}

log_error() {
    log_with_level "ERROR" "$1"
}

log_critical() {
    log_with_level "CRITICAL" "$1"
}