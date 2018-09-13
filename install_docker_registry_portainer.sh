# step 1. install docker first
# step 2. install portainer
PORTAINER_BASE=/home/docker-data/portainer
PORTAINER_DATA=${PORTAINER_BASE}/data

[[ -d ${PORTAINER_DATA} ]] || /usr/bin/mkdir -p ${PORTAINER_DATA}
cd ${PORTAINER_BASE}

echo "version: '2'

services:
  portainer:
    image: portainer/portainer
    container_name: portainer
    ports:
      - \"9000:9000\"
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${PORTAINER_DATA}:/data" > docker-compose.yml
