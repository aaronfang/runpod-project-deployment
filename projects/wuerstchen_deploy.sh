#!/bin/bash

ROOT_DIR="/workspace"    # Project root directory
WUERSTCHEN_DIR="${ROOT_DIR}/Wuerstchen-hf"    # Path to clone Kohya library
SERVER_PORT=7860    # 服务器端口

# Clone the repository if WUERSTCHEN_DIR does not exist
if [ ! -d "${WUERSTCHEN_DIR}" ]; then
  echo "Cloning the repository..."
  git clone -b dev https://github.com/camenduru/Wuerstchen-hf "${WUERSTCHEN_DIR}"

  # Navigate into the cloned directory
  cd "${WUERSTCHEN_DIR}" || exit

  # create a virtual environment
  echo "Creating a virtual environment..."
  # if not venv exists, create one
  if [ ! -d "venv" ]; then
    python3 -m venv venv
  fi

  # Check if requirements.txt exists before installing the required packages
  echo "Installing the required packages..."
  venv/bin/pip install -r requirements.txt

  # Download the previewer model
  MODEL_URL="https://huggingface.co/spaces/warp-ai/Wuerstchen/resolve/main/previewer/text2img_wurstchen_b_v1_previewer_100k.pt"
  MODEL_PATH="${WUERSTCHEN_DIR}/previewer/text2img_wurstchen_b_v1_previewer_100k.pt"
  echo "Downloading the previewer model..."
  wget ${MODEL_URL} -O "${MODEL_PATH}"

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

# check if app.py exists in WUERSTCHEN_DIR, if exists, modify the file, replace .launch() with .launch(server_name="0.0.0.0", server_port=SERVER_PORT,share=True)
if [ -f "${WUERSTCHEN_DIR}/app.py" ]; then
    echo "app.py exists. Modifying the file..."
    sed -i "s/.launch()/.launch(server_name=\"0.0.0.0\", server_port=${SERVER_PORT},share=True)/g" "${WUERSTCHEN_DIR}/app.py"
fi

# Start the application
venv/bin/python app.py

