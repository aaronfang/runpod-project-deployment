#!/bin/bash

# Define directories
WORKSPACE="/workspace"
PANOHEAD_DIR="$WORKSPACE/PanoHead"
DDFA_DIR="$WORKSPACE/3DDFA_V2"
DATA_DIR="$PANOHEAD_DIR/data"

# Define download function
download_file() {
    local file_url=$1
    local output_dir=$2
    local output_file=$3

    # 如果文件不存在，则下载
    if [ ! -f "$output_dir/$output_file" ]; then
        echo "File not found! Downloading $output_file..."
        mkdir -p "$output_dir"
        aria2c --console-log-level=error -c -x 16 -s 16 -k 1M "$file_url" -d "$output_dir" -o "$output_file"
    else
        echo "File $output_file already exists. Skipping download."
    fi
}

# clone repos and install dependencies
if [ ! -d "$PANOHEAD_DIR" ]; then

    echo "install dlib dependencies..."
    apt-get update
    apt -y install -qq aria2
    apt-get install -y --no-install-recommends build-essential cmake 

    git clone -b dev1 https://github.com/camenduru/PanoHead $PANOHEAD_DIR
    echo "========== PanoHead克隆完成 =========="

    echo "Install dependencies..."
    cd $PANOHEAD_DIR || exit
    python -m venv venv
    venv/bin/pip install imgui glfw pyspng mrcfile ninja plyfile trimesh onnxruntime onnx 
    venv/bin/pip install cython opencv-python click dlib tqdm imageio matplotlib scipy imageio-ffmpeg scikit-image

    # Clone and build 3DDFA_V2
    git clone -b dev https://github.com/camenduru/3DDFA_V2 $DDFA_DIR
    cd $DDFA_DIR || exit
    sh ./build.sh
    
    # Copy files to 3DDFA_V2 directory
    cp -rf "$PANOHEAD_DIR/3DDFA_V2_cropping/test" "$DDFA_DIR"
    cp -rf "$PANOHEAD_DIR/3DDFA_V2_cropping/crop_samples" "$DDFA_DIR"
    cp "$PANOHEAD_DIR/3DDFA_V2_cropping/dlib_kps.py" "$DDFA_DIR"
    cp "$PANOHEAD_DIR/3DDFA_V2_cropping/recrop_images.py" "$DDFA_DIR"
    echo "========== 3DDFA_V2克隆完成 =========="

    # Download shape_predictor
    download_file "https://huggingface.co/camenduru/shape_predictor_68_face_landmarks/resolve/main/shape_predictor_68_face_landmarks.dat" "$DDFA_DIR" "shape_predictor_68_face_landmarks.dat"
    echo "========== shape_predictor下载完成 =========="

    # Download models
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/ablation-trigridD-1-025000.pkl" "$PANOHEAD_DIR/models" "ablation-trigridD-1-025000.pkl"
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/baseline-easy-khair-025000.pkl" "$PANOHEAD_DIR/models" "baseline-easy-khair-025000.pkl"
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/easy-khair-180-gpc0.8-trans10-025000.pkl" "$PANOHEAD_DIR/models" "easy-khair-180-gpc0.8-trans10-025000.pkl"
    echo "========== 模型下载完成 =========="

    # Prepare directories
    mkdir -p "$DATA_DIR" "$DATA_DIR/stage" "$DATA_DIR/output"
    echo "========== data, stage, output目录创建完成 =========="

    # sed -i "s/if extension == '.json':/if extension != '.jpg':/g" "$DDFA_DIR/dlib_kps.py"
    # echo "========== dlib_kps.py修改完成 =========="
    sed -i 's/np.long/np.int64/g' "$DDFA_DIR/bfm/bfm.py"
    echo "========== bfm.py修改完成 =========="
    sed -i 's/dtype=np.int)/dtype=np.int_)/g' "$DDFA_DIR/FaceBoxes/utils/nms/cpu_nms.pyx"
    echo "========== cpu_nms.pyx修改完成 =========="
    # sed -i 's/max_batch = .*/max_batch = 3000000/g' "$PANOHEAD_DIR/projector_withseg.py"
    # echo "========== projector_withseg.py修改完成 =========="

fi

################## launch ##################

# # remove files in data directory
# rm -rf "$DATA_DIR/stage/*" "$DDFA_DIR/crop_samples/img/*" "$DDFA_DIR/test/original/*"

# # check if src directory is empty
# if [ -z "$(ls -A $SRC_DIR)" ]; then
#     echo "Error: $SRC_DIR is empty."
#     exit 1
# fi

# # move first image to test/original
# FIRST_IMAGE=$(ls $SRC_DIR | head -n 1)
# mv "$SRC_DIR/$FIRST_IMAGE" "$DDFA_DIR/test/original/$FIRST_IMAGE"
# echo "Moved $FIRST_IMAGE to $DDFA_DIR/test/original/"

# IMAGE_NAME=$(basename "$FIRST_IMAGE" .jpg)
# CUR_OUTPUT_DIR="$OUTPUT_DIR/$IMAGE_NAME"
# mkdir -p "$CUR_OUTPUT_DIR"

# # Recrop images
# cd $DDFA_DIR || exit
# python dlib_kps.py
# python recrop_images.py # -i data.pkl -j dataset.json
# echo "========== 重新裁切完成 =========="

# cd $PANOHEAD_DIR || exit
# # Run gen_videos_proj_withseg.py for pre and post videos
# for video_type in pre post
# do
#     python gen_videos_proj_withseg.py --output="$CUR_OUTPUT_DIR/easy-khair-180-gpc0.8-trans10-025000.pkl/0/PTI_render/$video_type.mp4" --latent="$CUR_OUTPUT_DIR/easy-khair-180-gpc0.8-trans10-025000.pkl/0/projected_w.npz" --trunc 0.7 --network "$CUR_OUTPUT_DIR/easy-khair-180-gpc0.8-trans10-025000.pkl/0/fintuned_generator.pkl" --cfg Head
#     echo "========== $video_type.mp4生成完成 =========="
# done

# # Generate ply model
# python projector_withseg.py --num-steps=300 --num-steps-pti=300 --shapes=True --outdir="$CUR_OUTPUT_DIR" --target_img="$DATA_DIR/stage" --network="$PANOHEAD_DIR/models/easy-khair-180-gpc0.8-trans10-025000.pkl" --idx 0
# echo "========== ply model生成完成 =========="