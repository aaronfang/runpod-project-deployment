#!/bin/bash

ROOT_DIR="/workspace"    # 项目根目录
WEBUI_DIR="${ROOT_DIR}/stable-diffusion-webui"
EXTENSIONS_DIR="${WEBUI_DIR}/extensions"
MODEL_DIR="${WEBUI_DIR}/models"
CHICKPOINT_DIR="${MODEL_DIR}/Stable-diffusion"
LORA_DIR="${MODEL_DIR}/Lora"
VAE_DIR="${MODEL_DIR}/VAE"
EMBEDDINGS_DIR="${WEBUI_DIR}/embeddings"
OUTPUTS_DIR="${WEBUI_DIR}/outputs"
SCRIPTS_DIR="${WEBUI_DIR}/scripts"
SERVER_PORT=7860    # 服务器端口

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${WEBUI_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui "${WEBUI_DIR}"
else
    echo "Updating the repository..."
    cd "${WEBUI_DIR}" || exit
    git pull
fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done


cd "${WEBUI_DIR}" || exit

# Common out default args in webui-user.sh
if [[ -f ./webui-user.sh ]]
then
    sed -i 's/^export COMMANDLINE_ARGS/#&/' ./webui-user.sh
fi

# 启动GUI
echo "启动GUI..."
./webui.sh -f --listen --port ${SERVER_PORT} --theme=dark --share --api --xformers --enable-insecure-extension-access --no-half-vae
