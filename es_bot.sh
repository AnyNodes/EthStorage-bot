#!/bin/bash

# Docker container name
container_name="es"

# Determine the directory where the script is located
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Use the determined script directory to define the path of the config.json
config_file="${script_dir}/config.json"

# Path to the file where the previous 'succeeded' count is stored
prev_succeeded_file="${script_dir}/prev_succeeded.txt"

# Read info from config.json using the config_file variable
bot_token=$(jq -r '.bot_token' "${config_file}")
chat_id=$(jq -r '.chat_id' "${config_file}")
node_name=$(jq -r '.node_name' "${config_file}")
check_mining_power=$(jq -r '.check_mining_power' "${config_file}")

# Telegram API URL
telegram_url="https://api.telegram.org/bot$bot_token/sendMessage"

# Log file path for the last 5 minutes logs
log_file="${script_dir}/mining_stats.log"

# Read the previous 'succeeded' count or default to 0 if not available
prev_succeeded=$(cat "$prev_succeeded_file" 2>/dev/null || echo 0)
echo prev_succeeded: $prev_succeeded

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

# Check the latest 'succeeded' count from the last 60 minutes
current_succeeded=$(docker logs "$container_name" --since 60m | grep "Mining stats" | tail -1 | awk -F'succeeded=' '{print $2}' | awk '{print $1}')
echo current_succeeded: $current_succeeded

if [[ "$current_succeeded" -gt "$prev_succeeded" ]]; then
    # This means there's been an increase, update the file
    echo "$current_succeeded" > "$prev_succeeded_file"
fi

# Now process the last 5 minutes of logs for specific actions
docker logs "$container_name" --since 5m | while read -r line; do
    if [[ "$line" == *"Mining stats"* && "$stats_message_sent" -eq 0 ]]; then
        succeeded=$(echo "$line" | awk -F'succeeded=' '{print $2}' | awk '{print $1}')
        if [[ "$succeeded" -gt "$prev_succeeded" ]]; then
            message="Mining succeeded count increased from $prev_succeeded to $succeeded."
            [[ -n "$node_name" ]] && message="<$node_name>: $message"
            log_and_send_message "$message"
            stats_message_sent=1
        fi
        echo "$line" >> "$log_file"  # Log "Mining stats" lines
    elif [[ "$line" == *"Mining tasks timed out"* && "$timeout_message_sent" -eq 0 && "$check_mining_power" == "true" ]]; then
        message="Mining power is not 100%"
        [[ -n "$node_name" ]] && message="<$node_name>: $message"
        log_and_send_message "$message"
        timeout_message_sent=1
        echo "$line" >> "$log_file"  # Log "Mining tasks timed out" lines
    fi
done
