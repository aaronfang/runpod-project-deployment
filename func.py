
import os
import requests
from tqdm import tqdm
from subprocess import run
from urllib.parse import urlparse

#### SET PATHs #### 
root = "/workspace"
venv_path = os.path.join(root, "venv")
webui_path = os.path.join(root, "stable-diffusion-webui")
checkpoint_model_path = os.path.join(webui_path, "models", "Stable-diffusion")
vae_path = os.path.join(webui_path, "models", "VAE")
lora_path = os.path.join(webui_path, "models", "Lora")
embedding_path = os.path.join(webui_path, "embeddings")
extensions_path = os.path.join(webui_path, "extensions")
scripts_path = os.path.join(webui_path, "scripts")

#### Functions ####
# function to run bash command
def run_cmd(cmd, cwd=None):
    run(cmd, cwd=cwd, shell=True, check=True)

def run_cmd_return(cmd):
    result = run(cmd, shell=True, capture_output=True, text=True)
    return result.returncode, result.stdout, result.stderr

# download function from url
def download_files(urls, dest_path):
    for url in urls:
        parsed_url = urlparse(url)
        command = ""

        if 'civitai' in parsed_url.netloc:
            url = url.split('?type')[0]
            command = f"aria2c --console-log-level=error -c -x 16 -s 16 -k 1M {url} -d \"{dest_path}\""
        elif 'huggingface' in parsed_url.netloc:
            filename = url.split('/')[-1]
            command = f"aria2c --console-log-level=error -c -x 16 -s 16 -k 1M -o {filename} {url} -d \"{dest_path}\""
        elif 'drive.google.com' in parsed_url.netloc:
            file_id = parsed_url.path.split('/')[-2]
            command = f"gdown {file_id}"
            run_cmd(command, cwd=dest_path)
        else:
            try:
                command = f"aria2c --console-log-level=error -c -x 16 -s 16 -k 1M {url} -d \"{dest_path}\""
            except:
                print(f"An error occurred while downloading {url}.")
        result = os.system(command)
        if result == 0:
            print(f"{url} downloaded successfully!")
        else:
            print(f"An error occurred while downloading {url}.")

def download_with_progress(url, dest_path):
        filename = os.path.basename(urlparse(url).path)
        response = requests.get(url, stream=True)
        total_length = int(response.headers.get('content-length', 0))

        with open(dest_path, "wb") as file, tqdm(
            desc=f"Downloading {filename}", total=total_length, unit="B", unit_scale=True
        ) as progress_bar:
            for data in response.iter_content(chunk_size=4096):
                file.write(data)
                progress_bar.update(len(data))

# update git repo function
def update_git_repo(repo_path, repo_url=None, force_reset=False, update_submodules=False, branch=None):
    # clone repository if repo_url is provided and repo doesn't exist
    if repo_url and not os.path.exists(repo_path):
        parent_dir = os.path.dirname(repo_path)
        if update_submodules:
            run(['git', 'clone', '--recurse-submodules', repo_url, repo_path], check=True)
        else:
            run(['git', 'clone', repo_url, repo_path], check=True)
        print(f"Git repository cloned from {repo_url} to {repo_path} successfully!")
    elif os.path.exists(repo_path):
        # change working directory
        os.chdir(repo_path)

        # checkout specific branch if provided
        if branch:
            run(["git", "checkout", branch], check=True)
            print(f"Checked out branch {branch} in {repo_path} successfully!")

        # reset git repository if needed
        if force_reset:
            run(["git", "reset", "--hard"], check=True)
            print(f"Git repository in {repo_path} reset successfully!")
        
        # Check for submodules and update if present
        if update_submodules and os.path.isfile('.gitmodules'):
            run(["git", "pull"], check=True)
            run(["git", "submodule", "update", "--init", "--recursive"], check=True)
            print(f"Submodules in {repo_path} updated successfully!")
        else:
            # pull latest version if repo exists
            run(["git", "pull"], check=True)
            print(f"Git repository in {repo_path} pulled successfully!")