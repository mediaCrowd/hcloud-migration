#!/usr/bin/env bash

if [[ -z `command -v jq` ]]; 
then
  echo -e "[$(date)] can not run migration!"
  echo -e "  \xE2\x9D\x8C jq is required. run apt-get install jq"
  exit 1
fi

getServerName()
{
  curl -s \
    -X GET -H "Authorization: Bearer $API_KEY" \
    "https://api.hetzner.cloud/v1/servers/$SERVER_ID" | jq -r '.server.name'
}

serverStatus()
{
  curl -s \
    -X GET -H "Authorization: Bearer $API_KEY" \
    "https://api.hetzner.cloud/v1/servers/$SERVER_ID" | jq -r '.server.status'
}

getStatus()
{
  status=$(serverStatus)
}

shutdown()
{
  getStatus

  if [ $status == 'running' ]; then
    echo -n "  - shutting down $SERVER_NAME ($SERVER_ID)"
    curl -s \
      -X POST \
      -H "Authorization: Bearer $API_KEY" \
      "https://api.hetzner.cloud/v1/servers/$SERVER_ID/actions/shutdown" >/dev/null
  else 
    echo -e "  - $SERVER_NAME ($SERVER_ID) is already down"
  fi
}

start()
{
  getStatus

  if [ $status == 'off' ]; then
    echo -e "  - starting $SERVER_NAME ($SERVER_ID)"

    curl -s \
	    -X POST \
	    -H "Authorization: Bearer $API_KEY" \
	    "https://api.hetzner.cloud/v1/servers/$SERVER_ID/actions/poweron" >/dev/null
  else 
    echo -e "  - $SERVER_NAME ($SERVER_ID) is already running"
  fi
}

migrate()
{
  curl -s \
    -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"upgrade_disk":false,"server_type":"'$SERVER_TYPE_TARGET'"}' \
    "https://api.hetzner.cloud/v1/servers/$SERVER_ID/actions/change_type" | jq -r '.error'
}

doMigration()
{
  if [[ -z $API_KEY || -z $SERVER_ID || -z $SERVER_TYPE_TARGET ]];
  then
    echo -e "[$(date)] missing data to migrate server!" 
    exit 1
  fi

  SERVER_NAME=$( getServerName )

  if [[ $SERVER_NAME == "null" ]];
  then
    echo "  - No Server running with id $SERVER_ID!"
    exit 1
  fi

  echo -e "[$(date)] start migrating $SERVER_NAME to $SERVER_TYPE_TARGET"

  shutdown

  getStatus
  while [[ $status != 'off' ]]; do
    echo -n "."
    sleep 1
    getStatus
  done

  migrationError=$( migrate )
  if [ "$migrationError" != "null" ]; then
    echo
    echo -e "[$(date)] ERROR:"
    echo -e "$migrationError"
    echo -e "  --> Restarting $SERVER_NAME ($SERVER_ID)"

    start

    sleep 5
    echo -e "[$(date)] $SERVER_NAME ($SERVER_ID) is $( serverStatus ) after failed migration"
    exit 1
  fi

  echo
  echo -n "  - migrate $SERVER_NAME ($SERVER_ID) to $SERVER_TYPE_TARGET"
  
  sleep 5
  getStatus
  while [ $status == 'migrating' ]; do
    echo -n "."
    sleep 10
    getStatus
  done

  echo
  echo -e "  \xE2\x9C\x94 done! $SERVER_NAME ($SERVER_ID) is $( serverStatus )"
  echo -e "[$(date)] finished migrating $SERVER_NAME ($SERVER_ID) to $SERVER_TYPE_TARGET"
}