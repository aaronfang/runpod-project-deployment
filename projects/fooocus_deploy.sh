#!/bin/bash

ROOT_DIR="/workspace"
FOOOCUS_DIR="${ROOT_DIR}/Fooocus"
SERVER_PORT=7860

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${FOOOCUS_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/lllyasviel/Fooocus.git "${FOOOCUS_DIR}"

  # Navigate into the cloned directory
  cd "${FOOOCUS_DIR}" || exit
  
  echo "Creating a virtual environment..."
  python3 -m venv fooocus_env
  fooocus_env/bin/pip install pygit2==1.12.2

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# 启动GUI
echo "启动GUI..."

OPTIONS="Anime Realistic None"
select opt in $OPTIONS; do
  if [ "$opt" = "Anime" ]; then
    fooocus_env/bin/python entry_with_update.py --preset anime --listen="0.0.0.0" --port=${SERVER_PORT}
    break
  elif [ "$opt" = "Realistic" ]; then
    fooocus_env/bin/python entry_with_update.py --preset realistic --listen="0.0.0.0" --port=${SERVER_PORT}
    break
  elif [ "$opt" = "None" ]; then
    fooocus_env/bin/python entry_with_update.py --listen="0.0.0.0" --port=${SERVER_PORT}
    break
  else
    echo "Invalid option. Please choose again."
  fi
done