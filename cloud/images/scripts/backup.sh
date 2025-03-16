#!/usr/bin/env bash

# Help function
function show_help() {
    echo "Usage: $0 -d <backup_directory> -r <retention_backups> <files/directories>"
    echo "\nOptions:"
    echo "  -d  Directory where backups will be stored"
    echo "  -r  Number of backups to retain"
    echo "  <files/directories> List of files and directories to back up"
    exit 1
}

# Retention function
function clean_old_backups() {
    local backup_dir="$1"
    local retention_count="$2"
    local hostname="$3"
    local formated_path_name="$4"

    # Get all backup files, sorted by most recent
    backup_files=($(find "$backup_dir" -type f -name "bkp_host-${hostname}-files-${formated_path_name}-*.tar.gz" | sort -r))

    # Get the number of backups to remove (total backups minus the retention count)
    backups_to_remove=$((${#backup_files[@]} - retention_count))

    if (( backups_to_remove > 0 )); then
        for (( i = retention_count; i < ${#backup_files[@]}; i++ )); do
            rm -f "${backup_files[$i]}"
            echo "Removed old backup: ${backup_files[$i]}" | tee -a "$LOG_FILE"
        done
    fi
}

# Argument verification
if [[ $# -eq 0 ]]; then
    show_help
fi

# Variables
STORAGE_BACKUPS=""
RETENTION_BACKUPS=""
FILES_TO_BACKUP=()
LOG_FILE=""

date_now="$(date +'%Y%m%d%M')"
hostname="$(hostname)"

# Processing arguments
while getopts "d:r:h" opt; do
    case "$opt" in
        d) STORAGE_BACKUPS="$OPTARG" ;;
        r) RETENTION_BACKUPS="$OPTARG" ;;
        h) show_help ;;
        *) show_help ;;
    esac
done
shift $((OPTIND -1))

if [[ -z "$STORAGE_BACKUPS" || -z "$RETENTION_BACKUPS" || $# -eq 0 ]]; then
    show_help
fi

FILES_TO_BACKUP=($@)
LOG_FILE="${STORAGE_BACKUPS}/backup_log_${date_now}.log"

# Create backup directory if it doesn't exist
mkdir -p "$STORAGE_BACKUPS"

# Create log file
{
    echo "Backup started at: $(date)"
    echo "Host: ${hostname}"
    echo "Backup destination: ${STORAGE_BACKUPS}"
    echo "Retention configured: ${RETENTION_BACKUPS} backups"
    echo "Items to be backed up: ${FILES_TO_BACKUP[@]}"
    echo "Current directory: $(pwd)"
    echo "-----------------------------"
} | tee -a "$LOG_FILE"

# Construct the full backup file name by concatenating all file/directory names
concatenated_paths=""
for path_to_backup in "${FILES_TO_BACKUP[@]}"; do
    concatenated_paths+=$(echo "$path_to_backup" | tr '/' '_')"-"
done

# Remove trailing hyphen
concatenated_paths="${concatenated_paths%-}"

tar_file_extension=".tar.gz"  # Extension of the tar file

# Final backup filename
backup_filename="${STORAGE_BACKUPS}/bkp_host-${hostname}-files-${concatenated_paths}-date_${date_now}${tar_file_extension}"

# Creating backup
echo "Creating backup: $backup_filename" | tee -a "$LOG_FILE"
tar -czf "$backup_filename" "${FILES_TO_BACKUP[@]}"

echo "Backup completed at: $(date)" | tee -a "$LOG_FILE"

# Clean up old backups specific to the host, keeping only the latest $RETENTION_BACKUPS backups
clean_old_backups "$STORAGE_BACKUPS" "$RETENTION_BACKUPS" "$hostname" "$concatenated_paths"

echo "Backups older than the last ${RETENTION_BACKUPS} backups for host ${hostname} have been removed." | tee -a "$LOG_FILE"

echo "Backup process finished."
