# EthStorage-bot

**EthStorage-bot** is an automated script designed to monitor EthStorage nodes. It sends alerts to Telegram when it detects that the number of successful mining operations exceeds 0 or when the mining power falls below 100%.

## Features

- Sends an alert to Telegram when the number of successful mining operations (**succeeded**) increased.
- Sends an alert to Telegram when the **mining power** is less than 100%.

## Prerequisites

Before using EthStorage-bot, please ensure the following conditions are met:
1. Your node OS is Ubuntu 22.
2. Your EthStorage node is set up through [Docker](https://docs.ethstorage.io/storage-provider-guide/tutorials#from-a-docker-image).
3. You have telegram bot token and chat_id. You can get them for free. Google how to.
4. `jq` and `curl` are installed on your node.

    To install `jq` and `curl`:
    
    ```bash
    apt update
    apt install jq curl
    ```

## Setup

1. Download this repository, copy the sample configuration file to create your actual configuration file:

```bash
git clone https://github.com/AnyNodes/EthStorage-bot.git
cd EthStorage-bot
cp config_sample.json config.json
```

2. Edit `config.json` to include your Telegram bot token, chat ID, and any other relevant configuration.
   - `node_name`: in case you have more than one nodes and want to distinguish them, give it a name on your own. If you only have one node, leave it empty.
   - `check_mining_power`: if the mining power of your node is always less than 100%, you may not want to receive the mining power alert frequently, then just set this parameter to `false`. You will only receive alert when `succeeded` is greater than 0.

4. Ensure the script is executable:

```bash
chmod +x ./es_bot.sh
```

## Cron Job

Google how to use crontab first.

To run `EthStorage-bot` at regular intervals, you can add it to your `crontab`. Here's an example configuration to execute the script every hour:

**# Make sure to replace /path/to/EthStorage-bot/es_bot.sh and /path/to/crontab.log with the actual paths on your system.**

```bash
10 * * * * /bin/bash /path/to/EthStorage-bot/es_bot.sh >> /path/to/crontab.log 2>&1
```

This setup will run the es_bot.sh script at the 10th minute of every hour, redirecting output to a specified log file.

## Logs

- Mining stats of each run: /path/to/mining_stats.log
- Crontab log: /path/to/crontab.log

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you need any support or have questions, please create github issue, or come to our [AnyNode telegram channel](https://t.me/AnyNodes).
