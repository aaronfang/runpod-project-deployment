#!/bin/bash

ROOT_DIR="/workspace"    # 项目根目录
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
    git pull

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

    echo "modify config.json..."
    if [ -f "${WEBUI_DIR}/config.json" ]; then
        echo "Modifying config.json..."
        sed -i 's/"randn_source": .*/"randn_source": "CPU",/' "${WEBUI_DIR}/config.json"
        sed -i 's/"sgm_noise_multiplier": .*/"sgm_noise_multiplier": true,/' "${WEBUI_DIR}/config.json"
        sed -i 's/"no_dpmpp_sde_batch_determinism": .*/"no_dpmpp_sde_batch_determinism": false,/' "${WEBUI_DIR}/config.json"
        sed -i 's/"quicksettings_list": .*/"quicksettings_list": ["sd_model_checkpoint","sd_vae","CLIP_stop_at_last_layers"],/' "${WEBUI_DIR}/config.json"
        sed -i 's/"hide_samplers": .*/"hide_samplers": ["LMS","Heun","DPM2","DPM2 a","DPM++ 2S a","DPM++ 2M","DPM++ SDE","DPM++ 2M SDE","DPM++ 2M SDE Heun","DPM++ 2M SDE Heun Karras","DDIM","PLMS","DPM++ 2S a Karras","DPM2 a Karras","DPM2 Karras","LMS Karras","DPM adaptive","DPM fast","DPM++ 3M SDE","DPM++ 2M SDE Heun Exponential"],/' "${WEBUI_DIR}/config.json"
    fi

    echo "replacing styles.csv..."
    cp "./styles.csv" "${WEBUI_DIR}/styles.csv"

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
