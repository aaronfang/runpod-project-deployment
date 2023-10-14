#!/bin/bash

# Define directories
WORKSPACE="/workspace"
PANOHEAD_DIR="$WORKSPACE/PanoHead"
DDFA_DIR="$WORKSPACE/3DDFA_V2"

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

    cd $PANOHEAD_DIR || exit
    # Download models
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/ablation-trigridD-1-025000.pkl" "$PANOHEAD_DIR/models" "ablation-trigridD-1-025000.pkl"
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/baseline-easy-khair-025000.pkl" "$PANOHEAD_DIR/models" "baseline-easy-khair-025000.pkl"
    download_file "https://huggingface.co/camenduru/PanoHead/resolve/main/easy-khair-180-gpc0.8-trans10-025000.pkl" "$PANOHEAD_DIR/models" "easy-khair-180-gpc0.8-trans10-025000.pkl"
    echo "========== 模型下载完成 =========="

    echo "Install dependencies..."
    python -m venv venv
    venv/bin/pip install imgui glfw pyspng mrcfile ninja plyfile trimesh onnxruntime onnx 
    venv/bin/pip install cython opencv-python click dlib tqdm imageio matplotlib scipy imageio-ffmpeg scikit-image

    # Clone and build 3DDFA_V2
    git clone -b dev https://github.com/camenduru/3DDFA_V2 $DDFA_DIR
    cd $DDFA_DIR || exit
    sh ./build.sh
    

    # Copy files to 3DDFA_V2 directory
    cp -rf "$PANOHEAD_DIR/3DDFA_V2_cropping/test" "$DDFA_DIR"
    cp "$PANOHEAD_DIR/3DDFA_V2_cropping/dlib_kps.py" "$DDFA_DIR"
    cp "$PANOHEAD_DIR/3DDFA_V2_cropping/recrop_images.py" "$DDFA_DIR"
    echo "========== 3DDFA_V2克隆完成 =========="

    # Download shape_predictor
    download_file "https://huggingface.co/camenduru/shape_predictor_68_face_landmarks/resolve/main/shape_predictor_68_face_landmarks.dat" "$DDFA_DIR" "shape_predictor_68_face_landmarks.dat"
    echo "========== shape_predictor下载完成 =========="

    # Prepare directories
    mkdir -p "$WORKSPACE/in" "$WORKSPACE/stage" "$WORKSPACE/output"
    echo "========== in, stage, output目录创建完成 =========="

    cd $DDFA_DIR || exit
    rm -r ./bfm/bfm.py
    rm -r ./FaceBoxes/utils/nms/cpu_nms.pyx
    git reset --hard
    sed -i "s/if extension == '.json':/if extension != '.jpg':/g" dlib_kps.py
    echo "========== dlib_kps.py修改完成 =========="
    sed -i 's/np.long/np.int64/g' ./bfm/bfm.py
    echo "========== bfm.py修改完成 =========="
    sed -i 's/dtype=np.int)/dtype=np.int_)/g' ./FaceBoxes/utils/nms/cpu_nms.pyx
    echo "========== cpu_nms.pyx修改完成 =========="

fi

################## launch ##################

# # prepare input images
# # rm -rf "$WORKSPACE/stage/*" "$DDFA_DIR/crop_samples/img/*" "$DDFA_DIR/test/original/*" "$WORKSPACE/output/*"
# # cp "$WORKSPACE/in/*" "$DDFA_DIR/test/original"
# # Check if the files exist in the directories before deleting
# if [ -d "$WORKSPACE/stage" ] && [ "$(ls -A $WORKSPACE/stage)" ]; then
#    echo "stage目录不为空，正在删除..."
#    rm -rf "$WORKSPACE"/stage/*
# fi

# if [ -d "$DDFA_DIR/crop_samples/img" ] && [ "$(ls -A $DDFA_DIR/crop_samples/img)" ]; then
#    echo "crop_samples/img目录不为空，正在删除..."
#    rm -rf "$DDFA_DIR"/crop_samples/img/*
# fi

# if [ -d "$DDFA_DIR/test/original" ] && [ "$(ls -A $DDFA_DIR/test/original)" ]; then
#    echo "test/original目录不为空，正在删除..."
#    rm -rf "$DDFA_DIR"/test/original/*
# fi

# if [ -d "$WORKSPACE/output" ] && [ "$(ls -A $WORKSPACE/output)" ]; then
#    echo "output目录不为空，正在删除..."
#    rm -rf "$WORKSPACE"/output/*
# fi

# # Check if the files exist in the input directory before copying
# if [ "$(ls -A $WORKSPACE/in)" ]; then
#    cp "$WORKSPACE"/in/* "$DDFA_DIR"/test/original/
#    echo "========== 图片复制完成 =========="
# else
#     echo "in目录为空，无法继续"
#     exit 1
# fi

# # Run dlib_kps.py and recrop_images.py
# python dlib_kps.py
# python recrop_images.py -i data.pkl -j dataset.json
# echo "========== 图片裁剪完成 =========="
# cp -rf "$DDFA_DIR"/crop_samples/img/* "$WORKSPACE"/stage
# echo "========== 裁剪后图片复制完成 =========="

# # Modify the max_batch in projector_withseg.py and run it
# sed -i 's/max_batch = .*/max_batch = 3000000/g' "$PANOHEAD_DIR/projector_withseg.py"
# echo "========== projector_withseg.py修改完成 =========="
# cd $PANOHEAD_DIR || exit
# python projector_withseg.py --num-steps=300 --num-steps-pti=300 --shapes=True --outdir="$WORKSPACE/output" --target_img="$WORKSPACE/stage" --network="$PANOHEAD_DIR/models/easy-khair-180-gpc0.8-trans10-025000.pkl" --idx 0
# echo "========== ply model生成完成 =========="
# # Run gen_videos_proj_withseg.py for pre and post videos
# for video_type in pre post
# do
#     python gen_videos_proj_withseg.py --output="$WORKSPACE/output/easy-khair-180-gpc0.8-trans10-025000.pkl/0/PTI_render/$video_type.mp4" --latent="$WORKSPACE/output/easy-khair-180-gpc0.8-trans10-025000.pkl/0/projected_w.npz" --trunc 0.7 --network "$WORKSPACE/output/easy-khair-180-gpc0.8-trans10-025000.pkl/0/fintuned_generator.pkl" --cfg Head
#     echo "========== $video_type.mp4生成完成 =========="
# done