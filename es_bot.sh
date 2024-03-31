#!/bin/bash

# Docker container name
container_name="es"

# Determine the directory where the script is located
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Use the determined script directory to define the path of the config.json
config_file="${script_dir}/config.json"

# Read info from config.json using the config_file variable
bot_token=$(jq -r '.bot_token' "${config_file}")
chat_id=$(jq -r '.chat_id' "${config_file}")
node_name=$(jq -r '.node_name' "${config_file}")
check_mining_power=$(jq -r '.check_mining_power' "${config_file}")

# Telegram API URL
telegram_url="https://api.telegram.org/bot$bot_token/sendMessage"

# Log file path
log_file="${script_dir}/mining_stats.log"

# Flags to ensure messages are sent only once per script execution
stats_message_sent=0
timeout_message_sent=0

# Separate line for readability
echo >> "$log_file"

# Function to log and send message
log_and_send_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    curl -s -X POST "$telegram_url" -d chat_id="$chat_id" -d text="$message"
}

# Check docker logs
docker logs "$container_name" --since 5m | while read -r line; do
    if [[ "$line" == *"Mining stats"* && "$stats_message_sent" -eq 0 ]]; then
        succeeded=$(echo "$line" | awk -F'succeeded=' '{print $2}' | awk '{print $1}')
        if [[ "$succeeded" -gt 0 ]]; then
            message="Mining succeeded count is greater than 0. Succeeded: $succeeded"
            [[ -n "$node_name" ]] && message="Node $node_name: $message"
            log_and_send_message "$message"
            stats_message_sent=1
        fi
    elif [[ "$line" == *"Mining tasks timed out"* && "$timeout_message_sent" -eq 0 && "$check_mining_power" == "true" ]]; then
        message="Mining power is not 100%"
        [[ -n "$node_name" ]] && message="Node $node_name: $message"
        log_and_send_message "$message"
        timeout_message_sent=1
    fi
done
