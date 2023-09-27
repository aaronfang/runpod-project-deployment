#!/bin/bash

ROOT_DIR="/workspace"    # 项目根目录
COMFYUI_DIR="${ROOT_DIR}/ComfyUI"    # Kohya库克隆路径
SERVER_PORT=7860    # 服务器端口

# Clone the repository if KOYHA_DIR does not exist
if [ ! -d "${COMFYUI_DIR}" ]; then
    echo "Cloning the repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"

    # Navigate into the cloned directory
    cd "${COMFYUI_DIR}" || exit
    python -m venv venv

    echo "installing requirements..."
    venv/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118 xformers
    venv/bin/pip install -r requirements.txt

    # copy extra_model_paths.yaml.example to extra_model_paths.yaml
    cp extra_model_paths.yaml.example extra_model_paths.yaml
    sed -i 's/path\/to\/stable-diffusion-webui\//\/workspace\/stable-diffusion-webui\//g' extra_model_paths.yaml
    sed -i 's/models\/ControlNet/\/workspace\/stable-diffusion-webui\/extensions\/sd-webui-controlnet\/models\//g' extra_model_paths.yaml

    # clone custom nodes
    cd custom_nodes || exit
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

echo "Selected Port: ${SERVER_PORT}"

export KMP_DUPLICATE_LIB_OK=TRUE

# 启动GUI
echo "启动GUI..."
cd "${COMFYUI_DIR}" || exit
venv/bin/python main.py --listen "0.0.0.0" --port ${SERVER_PORT} --preview-method auto --auto-launch