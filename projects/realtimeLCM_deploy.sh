#!/bin/bash

ROOT_DIR="/workspace"
RLCM_DIR="${ROOT_DIR}/Real-Time-Latent-Consistency-Model"
SERVER_PORT=7860

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${RLCM_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/radames/Real-Time-Latent-Consistency-Model.git "${RLCM_DIR}"

  # Navigate into the cloned directory
  cd "${RLCM_DIR}" || exit
  
  echo "Creating a virtual environment..."
  python -m venv venv 
  venv/bin/pip install -r requirements.txt
  # venv/bin/pip uninstall torch
  # venv/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# 启动GUI
echo "启动GUI..."
cd "${RLCM_DIR}" || exit
source venv/bin/activate
uvicorn "app:app" --host 0.0.0.0 --port=${SERVER_PORT} --reload