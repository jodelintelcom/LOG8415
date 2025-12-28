# LOG8415E - Project

Students:
- ALCINDOR Marc Jodel - 2000081

# How to run the benchmark

The fully automated process is contained in the `deploy.sh` script. 

Requirements:
- Make sure you have started your AWS lab and you have your AWS credentials in your `~/.aws/credentials` file. The profile must be called `default`. For example:
    ```
    [default]
    aws_access_key_id=YOUR_SECRET_KEY_ID
    aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
    aws_session_token=YOUR_SESSION_TOKEN
    ```
- `uv` installed on your local computer to run the `benchmark.py` script.
- `ssh-keygen` tool installed on your local computer to automatically generate an SSH keypair.

1. Respect requirements.
2. Execute `deploy.sh` script. You may have to make it executable (`chmod +x deploy.sh`).
3. Read results on your CloudWatch interface, or in the generated `benchmark-results.txt` file.

Note: You may find other README files in specific folders. This current README file is the only one you have to read to execute the full benchmark process. Other README files are just additional information.