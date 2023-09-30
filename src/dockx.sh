#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color, to reset stuff

current_dir=$(pwd)

echo -e "${GREEN}    ____             __  _  __${NC}"
echo -e "${GREEN}   / __ \____  _____/ /_| |/ /${NC}"
echo -e "${GREEN}  / / / / __ \/ ___/ //_/   / ${NC}"
echo -e "${GREEN} / /_/ / /_/ / /__/ ,< /   |  ${NC}" 
echo -e "${GREEN}/_____/\____/\___/_/|_/_/|_|  ${NC}"
echo "============================="
echo -e "${YELLOW}Working Directory: $current_dir${NC}"
echo "============================="

print_usage() {
    echo "Usage: dockx [OPTION]"
    echo "Manage Docker Compose projects in subdirectories."
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  --status        List directories and show status (Dockerfile, docker-compose.yml)"
    echo "  --up-all        Bring up all Docker Compose projects"
    echo "  --kill-all      Stop and remove all Docker containers and images"
    echo "  --log-all       Log all live-container xinetdlog to ,log folder"
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    print_usage
    exit 0
elif [ "$1" == "--up-all" ]; then
    subdirs=$(find "$current_dir" -maxdepth 1 -mindepth 1 -type d ! -name '.*')
    everything_up=true

    for dir in $subdirs; do
        if [ -f "$dir/docker-compose.yaml" ] || [ -f "$dir/docker-compose.yml" ]; then
            echo "Running docker-compose in $dir"
            docker-compose -f "$dir/docker-compose.yaml" up -d --build
            if [ $? -ne 0 ]; then
                everything_up=false
                echo -e "${RED}[-] Failed to bring up containers in $dir${NC}"
            fi
        fi
    done
    if [ "$everything_up" = true ]; then
        echo -e "${GREEN}[+] Everything is up${NC}"
    else
        echo -e "${RED}[-] Not all containers are up${NC}"
    fi
elif [ "$1" == "--kill-all" ]; then
    echo "Stopping all Docker containers..."
    docker stop $(docker ps -q)
    echo -e "${RED}[-] Removing all Docker containers...${NC}"
    docker rm $(docker ps -a -q)

    echo -e "${RED}[-] Removing all Docker images...${NC}"
    docker rmi $(docker images -q)
elif [ "$1" == "--status" ]; then
    subdirs=$(find "$current_dir" -maxdepth 1 -mindepth 1 -type d ! -name '.*')
    for dir in $subdirs; do
        dockerfile_status="${RED}Not Exist${NC}"
        composefile_status="${RED}Not Exist${NC}"
        flagfile_status="${RED}Not Exist${NC}"
        if [ -f "$dir/Dockerfile" ]; then
            dockerfile_status="${GREEN}Exist${NC}"
        fi
        if [ -f "$dir/docker-compose.yaml" ]; then
            composefile_status="${GREEN}Exist${NC}"
        fi
        if [ "$(find "$dir" -type f -name '*flag*' | wc -l)" -gt 0 ]; then
            flagfile_status="${GREEN}Exist${NC}"
        fi        
        echo -e "${YELLOW}${dir}${NC}:"
        echo -e "    - Dockerfile         : ${dockerfile_status}"
        echo -e "    - docker-compose.yaml: ${composefile_status}"
        echo -e "    - flag.txt           : ${flagfile_status}"
    done
elif [ "$1" == "--log-all" ]; then
    container_names=$(docker ps -a --format '{{.Names}}')
    mkdir .log
    echo -e "${GREEN}[+] Created Log Directory${NC}"
    echo "Available Containers: "
    for container in $container_names; do
        container_prefix=$(echo "$container" | cut -d'-' -f1)
        echo -e "${YELLOW}-$container_prefix${NC}"
        destination_file=".log/${container_prefix}-log"
        docker cp "$container:/var/log/xinetdlog" "$destination_file"
        echo "----> Copied /var/log/xinetdlog from $container to $destination_file"
    done
else
    echo -e "${RED}[-] Invalid choice. Please refer to -h / --help.${NC}"
fi