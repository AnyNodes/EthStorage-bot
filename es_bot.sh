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

# separate line
echo >> "$log_file"

# Check docker logs for "Mining stats"
docker logs $container_name --since 5m | grep "Mining stats" | while read -r line ; do

    # pick the vaule of succeeded
    succeeded=$(echo $line | awk -F'succeeded=' '{print $2}' | awk '{print $1}')

    # Log the succeeded value with a timestamp
    echo "$line" >> $log_file

    # Prepare the message
    if [[ -n $node_name ]]; then
        message="Node $node_name: Mining succeeded count is greater than 0. Succeeded: $succeeded"
    else
        message="Mining succeeded count is greater than 0. Succeeded: $succeeded"
    fi

    # if the value of succeeded > 0, send message
    if [[ $succeeded -ge 0 ]]; then
        curl -s -X POST $telegram_url -d chat_id=$chat_id -d text="$message"
    fi

done

# Check if monitoring mining power is enabled
if [[ "$check_mining_power" == "true" ]]; then
    # Check docker logs for "Mining tasks timed out"
    docker logs $container_name --since 5m | grep "Mining tasks timed out" | while read -r line ; do
        # Prepare the message
        message="Mining power is not 100%"
        if [[ -n $node_name ]]; then
            message="Node $node_name: $message"
        fi

        # Send message
        curl -s -X POST $telegram_url -d chat_id=$chat_id -d text="$message"

        # Log the event with a timestamp
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
    done
fi
