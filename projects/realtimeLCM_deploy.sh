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

### Env Variables ###
# TIMEOUT: limit user session timeout
# SAFETY_CHECKER: disabled if you want NSFW filter off
# MAX_QUEUE_SIZE: limit number of users on current app instance
# TORCH_COMPILE: enable if you want to use torch compile for faster inference works well on A100 GPUs

# examples:
# TIMEOUT=120 SAFETY_CHECKER=True MAX_QUEUE_SIZE=4 uvicorn "app-img2img:app" --host 0.0.0.0 --port 7860 --reload


echo "请设置环境参数，如果想跳过，请直接按回车键。"

read -p "设置 TIMEOUT (空闲超时时间(s), int): " TIMEOUT
read -p "设置 SAFETY_CHECKER (NSFW开关, bool): " SAFETY_CHECKER
read -p "设置 MAX_QUEUE_SIZE (可连接用户数, int): " MAX_QUEUE_SIZE
read -p "设置 TORCH_COMPILE (torch加速推理, bool): " TORCH_COMPILE

# 如果环境变量为空，则不添加到启动命令中
TIMEOUT=${TIMEOUT:+TIMEOUT=$TIMEOUT}
SAFETY_CHECKER=${SAFETY_CHECKER:+SAFETY_CHECKER=$SAFETY_CHECKER}
MAX_QUEUE_SIZE=${MAX_QUEUE_SIZE:+MAX_QUEUE_SIZE=$MAX_QUEUE_SIZE}
TORCH_COMPILE=${TORCH_COMPILE:+TORCH_COMPILE=$TORCH_COMPILE}

echo "请选择启动选项："
echo "1. txt to img (lcm)"
echo "2. txt to img (lcm lora)"
echo "3. img to img (lcm)"
echo "4. img to img (lcm lora)"
read -p "输入选项（1-4）：" option

case $option in
  1)
    $TIMEOUT $SAFETY_CHECKER $MAX_QUEUE_SIZE $TORCH_COMPILE uvicorn "app-txt2img:app" --host 0.0.0.0 --port=${SERVER_PORT} --reload
    ;;
  2)
    $TIMEOUT $SAFETY_CHECKER $MAX_QUEUE_SIZE $TORCH_COMPILE uvicorn "app-txt2imglora:app" --host 0.0.0.0 --port=${SERVER_PORT} --reload
    ;;
  3)
    $TIMEOUT $SAFETY_CHECKER $MAX_QUEUE_SIZE $TORCH_COMPILE uvicorn "app-controlnet:app" --host 0.0.0.0 --port=${SERVER_PORT} --reload
    ;;
  4)
    $TIMEOUT $SAFETY_CHECKER $MAX_QUEUE_SIZE $TORCH_COMPILE uvicorn "app-controlnetlora:app" --host 0.0.0.0 --port=${SERVER_PORT} --reload
    ;;
  *)
    echo "无效的选项。请重新运行脚本并选择一个有效的选项。"
    ;;
esac