#!/bin/bash

ROOT_DIR="/workspace"
WONDER3D_DIR="${ROOT_DIR}/Wonder3D"
SERVER_PORT=7860

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${WONDER3D_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/xxlong0/Wonder3D.git "${WONDER3D_DIR}"

  # Navigate into the cloned directory
  cd "${WONDER3D_DIR}" || exit
  
  echo "Creating a virtual environment..."
  python -m venv venv 
  venv/bin/pip install -r requirements.txt
  venv/bin/pip install git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch

  echo "Downloading the pre-trained model..."
  gdown "1cjPsKhUy8lvod-XfTJi4Ofpt5-hVF4Gx"
  unzip "ckpts.zip"

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# 启动GUI
echo "启动GUI..."
cd "${WONDER3D_DIR}" || exit
venv/bin/python gradio_app.py