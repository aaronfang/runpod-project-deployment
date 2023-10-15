import gradio as gr
import os
from PIL import Image
import subprocess
import os
from datetime import datetime


# check if there is a picture uploaded or selected
def check_img_input(control_image):
    if control_image is None:
        raise gr.Error("Please select or upload an input image")


def remove_files_in_dir(dir):
    for file in os.listdir(dir):
        os.remove(os.path.join(dir, file))


def generate(image_block: Image.Image, crop_chk:bool, gen_video_chk:bool):

    for dir in [STAGE_DIR, CROP_DIR, ORG_DIR]:
        remove_files_in_dir(dir)

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    image_name = f"image_{timestamp}"
    CUR_OUTPUT_DIR = os.path.join(OUTPUT_DIR, image_name)
    if not os.path.exists(CUR_OUTPUT_DIR):
        os.makedirs(CUR_OUTPUT_DIR)
    
    if crop_chk:
        image_block = image_block.convert("RGB")
        image_block.save(os.path.join(ORG_DIR, f'{image_name}.jpg'))
        subprocess.run(["python", "dlib_kps.py"], cwd=DDFA_DIR)
        subprocess.run(["python", "recrop_images.py"], cwd=DDFA_DIR)
    else:
        image_block = image_block.convert("RGB")
        image_block.save(os.path.join(CROP_DIR, f'{image_name}.jpg'))

    # Generate ply model
    subprocess.run(["python", "projector_withseg.py", "--num-steps", "300", "--num-steps-pti", "300", "--shapes", "True", "--outdir", CUR_OUTPUT_DIR, "--target_img", STAGE_DIR, "--network", os.path.join(PANOHEAD_DIR, "models/easy-khair-180-gpc0.8-trans10-025000.pkl"), "--idx", "0"], cwd=PANOHEAD_DIR)

    if gen_video_chk:
        for video_type in ["pre", "post"]:
            subprocess.run(["python", "gen_videos_proj_withseg.py", "--output", os.path.join(CUR_OUTPUT_DIR, "easy-khair-180-gpc0.8-trans10-025000.pkl/0/PTI_render", f"{video_type}.mp4"), "--latent", os.path.join(CUR_OUTPUT_DIR, "easy-khair-180-gpc0.8-trans10-025000.pkl/0/projected_w.npz"), "--trunc", "0.7", "--network", os.path.join(CUR_OUTPUT_DIR, "easy-khair-180-gpc0.8-trans10-025000.pkl/0/fintuned_generator.pkl"), "--cfg", "Head"], cwd=PANOHEAD_DIR)

        return os.path.join(CUR_OUTPUT_DIR, 'geometry.ply'), os.path.join(CUR_OUTPUT_DIR, "easy-khair-180-gpc0.8-trans10-025000.pkl/0/PTI_render", "post.mp4")
    else:
        return os.path.join(CUR_OUTPUT_DIR, 'geometry.ply'), None


if __name__ == "__main__":
    _TITLE = '''PanoHead: Geometry-Aware 3D Full-Head Synthesis in 360°'''

    _DESCRIPTION = '''PanoHead is a geometry-aware 3D full-head synthesis method that can generate a 3D head model from a single portrait image in 360°. It is based on the [3DDFA_V2](https://github.com/cleardusk/3DDFA_V2) and [PanoHead](https://github.com/SizheAn/PanoHead) projects. This demo is based on the [gradio](https://gradio.app/) library.'''

    _IMG_USER_GUIDE = '''## How to use this demo
                            1. Upload or select an image from the examples below.
                            2. Click the "Generate 3D" button.
                            3. Wait for the model to be generated.
                            4. Click the "Download" button to download the model.
                            5. Check the "Generate video" box to generate a video of the model rotating.
                            6. Click the "Download" button to download the video.
                            7. Click the "Clear" button to clear the output.
                            8. Repeat steps 1-7 to generate more models.'''

    # # load images in 'data' folder as examples
    # example_folder = os.path.join(os.path.dirname(__file__), 'data')
    # example_fns = os.listdir(example_folder)
    # example_fns.sort()
    # examples_full = [os.path.join(example_folder, x) for x in example_fns if x.endswith('.png')]

    # Define directories
    WORKSPACE = "/workspace"
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

        # Image-to-3D
        with gr.Row(variant='panel'):
            with gr.Column(scale=5):
                image_block = gr.Image(type='pil', image_mode='RGB', height=290, label='Input image', tool=None)

                crop_chk = gr.Checkbox(True, label='Re-Crop Image to Face Only')
                gen_video_chk = gr.Checkbox(True, label='Generate Video')

                # gr.Examples(
                #     examples=examples_full,  # NOTE: elements must match inputs list!
                #     inputs=[image_block],
                #     outputs=[image_block],
                #     cache_examples=False,
                #     label='Examples (click one of the images below to start)',
                #     examples_per_page=40
                # )

                img_run_btn = gr.Button("Generate")
                img_guide_text = gr.Markdown(_IMG_USER_GUIDE, visible=True)

            with gr.Column(scale=5):
                # display post.mp4
                video_block = gr.Video(type='mp4', label='Output video', height=290, width=290, tool=None)
                obj3d = gr.Model3D(clear_color=[0.0, 0.0, 0.0, 0.0], label="3D Model (Final)")

            # if there is an input image, continue with inference
            # else display an error message
            img_run_btn.click(check_img_input, inputs=[image_block], queue=False).success(
                generate,
                inputs=[image_block, crop_chk, gen_video_chk],
                outputs=[obj3d, video_block]
            ).then(
                lambda results: {
                    'obj3d': results[0] if results is not None else None,
                    'video_block': results[1] if results and results[1] is not None else 'No video generated'
                }
            )

    demo.queue().launch(server_name='0.0.0.0', server_port=7860, share=True)