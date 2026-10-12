POSTGRES_CONTAINER_ID=$(podman ps --filter "label=com.docker.compose.project=$COMPOSE_PROJECT_NAME" --filter "label=com.docker.compose.service=postgres" --format '{{.ID}}')

if [ -n "$POSTGRES_CONTAINER_ID" ]; then
  export POSTGRES_USER=$(podman inspect "$POSTGRES_CONTAINER_ID" | jq -r '.[0].Config.Env[] | select(startswith("POSTGRES_USER=")) | split("=")[1]')
  export POSTGRES_PASSWORD=$(podman inspect "$POSTGRES_CONTAINER_ID" | jq -r '.[0].Config.Env[] | select(startswith("POSTGRES_PASSWORD=")) | split("=")[1]')
  export POSTGRES_DB=$(podman inspect "$POSTGRES_CONTAINER_ID" | jq -r '.[0].Config.Env[] | select(startswith("POSTGRES_DB=")) | split("=")[1]')
  export POSTGRES_PORT=$(podman inspect "$POSTGRES_CONTAINER_ID" | jq -r '.[0].NetworkSettings.Ports["5432/tcp"][0].HostPort')
  export POSTGRES_HOST=127.0.0.1
else
  unset POSTGRES_USER
  unset POSTGRES_PASSWORD
  unset POSTGRES_DB
  unset POSTGRES_PORT
  unset POSTGRES_HOST
fi
