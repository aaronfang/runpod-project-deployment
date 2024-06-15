#!/bin/bash

ROOT_DIR="/workspace"    # 项目根目录
KOYHA_DIR="${ROOT_DIR}/kohya_ss"    # Kohya库克隆路径
INPUT_DIR="${ROOT_DIR}/kohya_ss/input"    # 输入文件目录
OUTPUT_DIR="${ROOT_DIR}/kohya_ss/output"    # 输出文件目录
SERVER_PORT=7860    # 服务器端口

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${KOYHA_DIR}" ]; then
  echo "Cloning the repository..."
  git clone https://github.com/bmaltais/kohya_ss.git "${KOYHA_DIR}"

  # Navigate into the cloned directory
  cd "${KOYHA_DIR}" || exit
  # Create the input and output directories
  mkdir -p "${INPUT_DIR}"
  mkdir -p "${OUTPUT_DIR}"

  # Run setup script
  chmod +x ./setup-runpod.sh
  ./setup-runpod.sh
fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

# 启动GUI
echo "启动GUI..."
cd "${KOYHA_DIR}" || exit
./gui.sh --share --listen=0.0.0.0 --server_port=${SERVER_PORT} --headless
