#!/bin/bash

ROOT_DIR="/workspace"    # 项目根目录
Akegarasu_DIR="${ROOT_DIR}/lora-scripts"    # Kohya库克隆路径
INPUT_DIR="${ROOT_DIR}/lora-scripts/input"    # 输入文件目录
# SERVER_PORT=7860    # 服务器端口

# Clone the repository if Akegarasu_DIR does not exist
if [ ! -d "${Akegarasu_DIR}" ]; then
  echo "Cloning the repository..."
  git clone --recurse-submodules https://github.com/Akegarasu/lora-scripts "${Akegarasu_DIR}"

  # Navigate into the cloned directory
  cd "${Akegarasu_DIR}" || exit
  # Create the input and output directories
  mkdir -p "${INPUT_DIR}"

  # Run setup script
  chmod +x ./install.bash
  ./install.bash
fi

# # Check if port is occupied, if occupied, increment the port number
# while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
#     echo "Port ${SERVER_PORT} is occupied. Trying next port..."
#     SERVER_PORT=$((SERVER_PORT+1))
# done

# echo "Selected Port: ${SERVER_PORT}"

# 启动GUI
echo "启动GUI..."
cd "${Akegarasu_DIR}" || exit
export HF_HOME=huggingface
export PYTHONUTF8=1
python gui.py --host=0.0.0.0 --tensorboard-host=0.0.0.0 "$@"


