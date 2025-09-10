# Terraform Project Structure

This repository contains Terraform configuration files for managing infrastructure as code. Below is an overview of the directory structure and its purpose:

## Credentials and access to AWS platform

Make sure you have started your AWS lab and you have your AWS credentials in your `~/.aws/credentials` file. For example:
```
[default]
aws_access_key_id=YOUR_SECRET_KEY_ID
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
aws_session_token=YOUR_SESSION_TOKEN
```

## Usage

1. **Initialize Terraform:**
    ```sh
    terraform init
    ```
2. **Plan Infrastructure Changes:**
    ```sh
    terraform plan
    ```
3. **Apply Changes:**
    ```sh
    terraform apply
    ```

## Modules

Reusable modules are located in the `modules/` directory. Each module encapsulates resources for specific components.
