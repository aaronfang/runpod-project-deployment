import gradio as gr
import os
import subprocess
from func import download_files

class DeployApp:
    def __init__(self):

        self.session_dropdown = None

    def load_scripts(self):
        return [f for f in os.listdir('projects') if os.path.isfile(os.path.join('projects', f)) and f.endswith('.sh') and 'deploy' in f]

    # def deploy(script):
    #     script = os.path.join('projects', script)
    #     subprocess.run(['chmod', '+x', script])
    #     subprocess.run(['bash', script])
    #     return "Deploy Complete"

    # def deploy(self, script):
    #     script = os.path.join('projects', script)
    #     subprocess.run(['chmod', '+x', script])
    #     session_name = os.path.basename(script).replace('.sh', '')
    #     subprocess.run(['tmux', 'new-session', '-d', '-s', session_name, 'bash ' + script])
    #     subprocess.run(['tmux', 'attach-session', '-t', session_name])
    #     self.update_session_dropdown_options()
    #     return "Deploy Complete"

    def download(self, url, path):
        download_files([url], path)
        return "Download Complete"

    # def get_sessions(self):
    #     result = subprocess.run(['tmux', 'list-sessions'], stdout=subprocess.PIPE)
    #     sessions = result.stdout.decode().split('\n')
    #     return [s.split(':')[0] for s in sessions if s]

    # def switch_session(self, session_name):
    #     if session_name is None:
    #         return "No session selected"
    #     subprocess.run(['tmux', 'switch-client', '-t', session_name])
    #     return "Switched to session " + session_name

    # def update_session_dropdown_options(self):
    #     self.session_dropdown.choices = self.get_sessions()

    # def run_command(command):
    #     process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
    #     while True:
    #         output = process.stdout.readline()
    #         if output == '' and process.poll() is not None:
    #             break
    #         if output:
    #             print(output.strip())
    #     rc = process.poll()
    #     return rc

    def kill_processes_on_port(self, port):
        subprocess.run(['fuser', '-k', f'{port}/tcp'])

    def create_ui(self):
        with gr.Blocks(analytics_enabled=False) as ui_component:
            with gr.Accordion("Projects to Deploy", open=True):
                deploy_dropdown = gr.components.Dropdown(choices=self.load_scripts(), value=self.load_scripts()[0], label="Select Deployment Script")
                btn_deploy = gr.Button("Deploy/Launch", variant="primary", )

            # with gr.Accordion("Sessions", open=True):
            #     self.session_dropdown = gr.components.Dropdown(choices=self.get_sessions(), label="Select Session")
            #     btn_switch = gr.Button("Switch", variant="primary", )

            with gr.Accordion("Download Files", open=False):
                download_url = gr.components.Textbox(lines=1, placeholder="https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16", label="下载URL")
                download_path = gr.components.Textbox(lines=1, placeholder="Select Destination Path", label="Download to ...")
                download_dropdown = gr.components.Dropdown(choices=[
                    '/workspace/stable-diffusion-webui/models/Stable-diffusion',
                    '/workspace/stable-diffusion-webui/models/Lora',
                    '/workspace/stable-diffusion-webui/models/VAE',
                    '/workspace/stable-diffusion-webui/embeddings',
                    ], label="Preset Paths")
                btn_download = gr.Button("Download", variant="primary", )
            # with gr.Accordion("Send Files", open=True):
            #     send_filepath = gr.components.Textbox(lines=1, placeholder="File/Folder to send", label="Send File/Folder")
            #     btn_send = gr.Button("Send", variant="primary", )
            # with gr.Accordion("Kill Processes", open=False):
            #     kill_port = gr.components.Textbox(lines=1, placeholder="Port to kill", label="Kill Port")
            #     btn_kill = gr.Button("Kill", variant="primary", )

            output_text = gr.components.Textbox(lines=1, label="Output")

            btn_deploy.click(
                fn=self.deploy,
                inputs=[deploy_dropdown],
                # outputs=[output_text]
            )

            # btn_switch.click(
            #     fn=self.switch_session,
            #     inputs=[self.session_dropdown],
            # )
        
            btn_download.click(
                fn=self.download,
                inputs=[download_url, download_path],
                outputs=[output_text]
            )

            download_dropdown.change(
                fn=lambda dropdown_selected: dropdown_selected,
                inputs=[download_dropdown],
                outputs=[download_path]
            )

            # btn_send.click(
            #     fn=lambda send_filepath: run_command(f'runpodctl send {send_filepath}'),
            #     inputs=[send_filepath],
            #     outputs=[output_text]
            # )

            # btn_kill.click(
            #     fn=lambda kill_port: self.kill_processes_on_port(kill_port),
            #     inputs=[kill_port],
            #     # outputs=[output_text]
            # )

        return ui_component


app = DeployApp()
iface = app.create_ui()
iface.launch(server_name="0.0.0.0", server_port=4444, share=True)
# iface.launch(server_name="localhost", server_port=4444)
