#!/bin/bash

ROOT_DIR="/workspace"
PROJ_SCRIPTS_DIR="${ROOT_DIR}/runpod-project-deployment/projects"
WEBUI_DIR="${ROOT_DIR}/stable-diffusion-webui"
EXTENSIONS_DIR="${WEBUI_DIR}/extensions"
CN_MODEL_DIR="${EXTENSIONS_DIR}/sd-webui-controlnet/models"
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
    git pull origin master

    echo "clone extensions..."
    cd "${EXTENSIONS_DIR}" || exit
    git clone https://github.com/DominikDoom/a1111-sd-webui-tagcomplete.git
    git clone https://github.com/Bing-su/adetailer.git
    git clone https://github.com/pkuliyi2015/multidiffusion-upscaler-for-automatic1111.git
    git clone https://github.com/ArtVentureX/sd-webui-agent-scheduler.git
    git clone https://github.com/Mikubill/sd-webui-controlnet.git
    git clone https://github.com/zanllp/sd-webui-infinite-image-browsing.git
    git clone https://github.com/fkunn1326/openpose-editor.git
    git clone https://github.com/yankooliveira/sd-webui-photopea-embed.git
    git clone https://github.com/butaixianran/Stable-Diffusion-Webui-Civitai-Helper.git
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-wildcards.git
    git clone https://github.com/novitalabs/sd-webui-cleaner.git
    git clone https://github.com/ljleb/sd-webui-freeu.git

    cd "${CN_MODEL_DIR}" || exit
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_scribble.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_softedge.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11e_sd15_ip2p.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11e_sd15_shuffle.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_inpaint.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15s2_lineart_anime.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_mlsd.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_normalbae.yaml
    wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_seg.yaml
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_canny.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_canny_anime.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_depth.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_depth_anime.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_blur.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_blur_anime.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_openpose_anime_v2.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/kohya_controllllite_xl_scribble_anime.safetensors
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ip-adapter_sd15_plus.pth
    wget https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/ip-adapter_xl.pth

    echo "download vae models..."
    cd "${VAE_DIR}" || exit
    wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/blob/main/vae-ft-mse-840000-ema-pruned.safetensors
    wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

    echo "download embeddings models..."
    cd "${EMBEDDINGS_DIR}" || exit
    gdown "1-EXxOitLlXq-uRmGcuTFraRPV1pv3qUQ"
    unzip "embeddings.zip"

    echo "replacing config.json..."
    cp "${PROJ_SCRIPTS_DIR}/config.json" "${WEBUI_DIR}/config.json"

    echo "replacing styles.csv..."
    cp "${PROJ_SCRIPTS_DIR}/styles.csv" "${WEBUI_DIR}/styles.csv"

    # Common out default args in webui-user.sh
    if [[ -f "${WEBUI_DIR}/webui-user.sh" ]]
    then
        sed -i 's/^export COMMANDLINE_ARGS/#&/' "${WEBUI_DIR}/webui-user.sh"
    fi
fi

# Check if port is occupied, if occupied, increment the port number
while lsof -Pi :${SERVER_PORT} -sTCP:LISTEN -t >/dev/null ; do
    echo "Port ${SERVER_PORT} is occupied. Trying next port..."
    SERVER_PORT=$((SERVER_PORT+1))
done

cd "${WEBUI_DIR}" || exit

# 启动GUI
echo "启动GUI..."
./webui.sh -f --listen --port ${SERVER_PORT} --theme=dark --share --api --xformers --enable-insecure-extension-access --no-half-vae
