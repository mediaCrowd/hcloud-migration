# Hetzner Cloud Server Migration

This script handles all required commands to migrate a hcloud server to a new server type.

## Features

- Run all required API commands with one shell command
- checks the server status for every migration step
- workflow is optimized to be used with automations, eg. crontab.
- Text-output for logging and debugging keeps track of progress and server status

## Important notes

- migration is only possible when the server is not running, so this script will shut down your server!
- the migration will keep the inital storage size! This is required to easily downgrade a server.
- the script requries the 'jq' command.

## Usage

1. Clone this repo

2. Copy the sample file to a `.sh`-file

    eg. ```cp migrate.sh.sample migrate.sh```

3. Enter required data
    - server-id
    - migration target (eg. "cx21")
    - API key

4. If not already done, install `jq`

    ```apt-get install jq```

5. Run your script or add it to your automation tool
