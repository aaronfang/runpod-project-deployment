import gradio as gr
import os
from PIL import Image
import subprocess
from datetime import datetime
import shutil
import webbrowser


def open_output_dir():
    webbrowser.open(OUTPUT_DIR)


# check if there is a picture uploaded or selected
def check_img_input(control_image):
    if control_image is None:
        raise gr.Error("Please select or upload an input image")


def remove_files_in_dir(dir):
    if os.path.exists(dir):
        for file in os.listdir(dir):
            os.remove(os.path.join(dir, file))


def generate(image_block: Image.Image, crop_chk:bool):

    for dir in [STAGE_DIR, CROP_DIR, ORG_DIR]:
        remove_files_in_dir(dir)

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    image_name = f"image_{timestamp}"
    # CUR_OUTPUT_DIR = OUTPUT_DIR
    CUR_OUTPUT_DIR = os.path.join(OUTPUT_DIR, image_name)
    os.makedirs(CUR_OUTPUT_DIR, exist_ok=True)
    
    image_block = image_block.convert("RGB")
    save_dir = ORG_DIR if crop_chk else CROP_DIR
    image_block.save(os.path.join(save_dir, f'{image_name}.jpg'))

    if crop_chk:
        subprocess.run(["python", "dlib_kps.py"], cwd=DDFA_DIR, check=True)
        subprocess.run(["python", "recrop_images.py"], cwd=DDFA_DIR, check=True)

    # copy image from CROP_DIR to STAGE_DIR
    for file in os.listdir(CROP_DIR):
        shutil.copy2(os.path.join(CROP_DIR, file), STAGE_DIR)
    
    croped_img_dir = os.path.join(STAGE_DIR, f'{image_name}.jpg')
    
    sub_dir = os.path.join(CUR_OUTPUT_DIR, "easy-khair-180-gpc0.8-trans10-025000.pkl", "0")

    # Generate ply model and videos
    subprocess.run(["python", "projector_withseg.py", "--num-steps", "300", "--num-steps-pti", "300", "--shapes", "True", "--outdir", CUR_OUTPUT_DIR, "--target_img", STAGE_DIR, "--network", os.path.join(PANOHEAD_DIR, "models/easy-khair-180-gpc0.8-trans10-025000.pkl"), "--idx", "0"], cwd=PANOHEAD_DIR, check=True)
    subprocess.run(["python", "gen_videos_proj_withseg.py", "--output", os.path.join(sub_dir, "PTI_render", "pre.mp4"), "--latent", os.path.join(sub_dir, "projected_w.npz"), "--trunc", "0.7", "--network", "./models/easy-khair-180-gpc0.8-trans10-025000.pkl", "--cfg", "Head"], check=True)
    subprocess.run(["python", "gen_videos_proj_withseg.py", "--output", os.path.join(sub_dir, "PTI_render", "post.mp4"), "--latent", os.path.join(sub_dir, "projected_w.npz"), "--trunc", "0.7", "--network", os.path.join(sub_dir, "fintuned_generator.pkl"), "--cfg", "Head"], check=True)

    return [croped_img_dir, os.path.join(sub_dir, "PTI_render", "pre.mp4"), os.path.join(sub_dir, "PTI_render", "post.mp4"), os.path.join(sub_dir, "proj.mp4")]


if __name__ == "__main__":
    _TITLE = '''PanoHead: Geometry-Aware 3D Full-Head Synthesis in 360°'''

    _DESCRIPTION = '''PanoHead is a geometry-aware 3D full-head synthesis method that can generate a 3D head model from a single portrait image in 360°. It is based on the [3DDFA_V2](https://github.com/cleardusk/3DDFA_V2) and [PanoHead](https://github.com/SizheAn/PanoHead) projects. This demo is based on the [gradio](https://gradio.app/) library.'''

    _IMG_USER_GUIDE = '''## How to use this demo
                            1. Upload or select an image from the examples below.
                            2. Click the "Generate" button.
                            3. Wait for the model to be generated.
                            4. Click the "Download" button to download the model.
                            5. Check the "Generate video" box to generate a video of the model rotating.
                            6. Click the "Download" button to download the video.
                            7. Click the "Clear" button to clear the output.
                            8. Repeat steps 1-7 to generate more models.'''

    # Define directories
    WORKSPACE = "/workspace"
    # WORKSPACE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    PANOHEAD_DIR = os.path.join(WORKSPACE, "PanoHead")
    DDFA_DIR = os.path.join(WORKSPACE, "3DDFA_V2")
    ORG_DIR = os.path.join(DDFA_DIR, "test/original")
    CROP_DIR = os.path.join(DDFA_DIR, "crop_samples/img")
    DATA_DIR = os.path.join(PANOHEAD_DIR, "data")
    STAGE_DIR = os.path.join(DATA_DIR, "stage")
    OUTPUT_DIR = os.path.join(DATA_DIR, "output")

    # Compose demo layout & data flow
    with gr.Blocks(title=_TITLE, theme=gr.themes.Soft()) as demo:
        with gr.Row():
            with gr.Column(scale=1):
                gr.Markdown('# ' + _TITLE)
        gr.Markdown(_DESCRIPTION)
        with gr.Row():
            with gr.Column(scale=1):
                image_block = gr.Image(type='pil', image_mode='RGB', height=290, label='Input image', tool=None)
            with gr.Column(scale=1):
                crop_image_block = gr.Image(type='pil', image_mode='RGB', height=290, label='Cropped image', tool=None)

        # Image-to-3D
        with gr.Row(variant='panel'):
            with gr.Column(scale=5):
                crop_chk = gr.Checkbox(True, label='Re-Crop Image to Face Only')
                img_run_btn = gr.Button("Generate")
                open_output_dir_btn = gr.Button("Open Output Directory")
                img_guide_text = gr.Markdown(_IMG_USER_GUIDE, visible=True)

            with gr.Column(scale=5):
                with gr.Row():
                    pre_video_block = gr.Video(label='Pre.mp4', height=290, width=290)
                    post_video_block = gr.Video(label='Post.mp4', height=290, width=290)
                proj_video_block = gr.Video(label='Proj.mp4', height=290)
                # obj3d = gr.Model3D(clear_color=[0.0, 0.0, 0.0, 0.0], label="3D Model (Final)")

            # else display an error message
            img_run_btn.click(check_img_input, inputs=[image_block], queue=False).success(
                generate,
                inputs=[image_block, crop_chk],
                outputs=[proj_video_block, pre_video_block, post_video_block, crop_image_block]
            ).then(
                lambda results: {
                    # 'obj3d': results[0] if results is not None else None,
                    'crop_image_block': results[0] if results and results[0] is not None else 'No cropped image generated',
                    'pre_video_block': results[1] if results and results[1] is not None else 'No pre video generated',
                    'post_video_block': results[2] if results and results[2] is not None else 'No post video generated',
                    'proj_video_block': results[3] if results and results[3] is not None else 'No proj video generated',
                }
            )

            open_output_dir_btn.click(open_output_dir)

    demo.queue().launch()