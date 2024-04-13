#!/bin/bash

# Docker container name
container_name="es"

# Determine the directory where the script is located
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Use the determined script directory to define the path of the config.json
config_file="${script_dir}/config.json"

# Path to the files where the previous 'succeeded' and 'failed' counts are stored
prev_succeeded_file="${script_dir}/prev_succeeded.txt"
prev_failed_file="${script_dir}/prev_failed.txt"

# Read info from config.json using the config_file variable
bot_token=$(jq -r '.bot_token' "${config_file}")
chat_id=$(jq -r '.chat_id' "${config_file}")
node_name=$(jq -r '.node_name' "${config_file}")
check_mining_power=$(jq -r '.check_mining_power' "${config_file}")

# Telegram API URL
telegram_url="https://api.telegram.org/bot$bot_token/sendMessage"

# Log file path for the mining logs
log_file="${script_dir}/mining_stats.log"

# Read the previous 'succeeded' and 'failed' counts or default to 0 if not available
prev_succeeded=$(cat "$prev_succeeded_file" 2>/dev/null || echo 0)
prev_failed=$(cat "$prev_failed_file" 2>/dev/null || echo 0)

# Separate line for readability
echo >> "$log_file"

# Function to log and send message
log_and_send_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    curl -s -X POST "$telegram_url" -d chat_id="$chat_id" -d text="$message"
}

# Process the last 10 minutes of logs with timeout for specific actions
log_output=$(timeout 1m docker logs "$container_name" --since 10m)
if [[ $? -ne 0 ]]; then
    message="Timeout while retrieving logs from Docker."
    [[ -n "$node_name" ]] && message="<$node_name>: $message"
    log_and_send_message "$message"
else
    current_succeeded=$(echo "$log_output" | grep "Mining stats" | tail -1 | awk -F'succeeded=' '{print $2}' | awk '{print $1}')
    current_failed=$(echo "$log_output" | grep "Mining stats" | tail -1 | awk -F'failed=' '{print $2}' | awk '{print $1}')
    echo current_succeeded: $current_succeeded
    echo current_failed: $current_failed
    if [[ "$current_succeeded" -gt "$prev_succeeded" ]]; then
        message="Mining succeeded count increased from $prev_succeeded to $current_succeeded."
        [[ -n "$node_name" ]] && message="<$node_name>: $message"
        log_and_send_message "$message"
        echo "$current_succeeded" > "$prev_succeeded_file"
    fi
    if [[ "$current_failed" -gt "$prev_failed" ]]; then
        message="Mining failed count increased from $prev_failed to $current_failed."
        [[ -n "$node_name" ]] && message="<$node_name>: $message"
        log_and_send_message "$message"
        echo "$current_failed" > "$prev_failed_file"
    fi
    echo "$log_output" >> "$log_file"  # Log the entire output
fi
