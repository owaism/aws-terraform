# aws-terraform
Initial AWS Infrastructure as Code using Terraform

# Setup

1. Create a file called "aws_creds.tfvars" in the root folder of the terraform directory and put your aws credentials in it. The file should have the following format:

```
[core_terraform]
aws_access_key_id=<PUT YOUR KEY HERE>
aws_secret_access_key=<PUT YOUR SECRET HERE>
```

2. Create a ssh Public and Private Key pair (https://www.maketecheasier.com/generate-public-private-ssh-key/).
3. Update module global-variables > outputs.tf to reflect your ssh key pair paths.


# Startup the terraform scripts

```
terraform apply
```
