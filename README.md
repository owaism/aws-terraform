# aws-terraform
Initial AWS Infrastructure as Code using Terraform


# AWS Infrastructure Creation Plan

1. Setup: Terraform Backend
2. Setup: Global Variables use in the terraform scripts
3. Setup: AWS configs and Terraform Remote State
4. AWS: Create VPC
5. AWS: Create Security Groups
	- Public Load Balancer Security Group for HTTP ELB
	- Private Security Group for all other resources
	- Bastion Security group for the SSH Jumpbox (Bastion server)
6. AWS: Create Internet Gateway to for DMZ to be able to access the internet
7. AWS: Create DMZ Route Tables 
8. AWS: Create DMZ Subnets
9. AWS: Create Association between DMZ route table and DMZ Subnets
10. AWS: Create EIPs (Public IP Addresses) for the NAT Boxes
11. AWS: Create NAT Gateways
12. AWS: Create Private Route Tables
13. AWS: Create Private Subnets
14. AWS: Create Association between private route tables and private subnets
15. AWS: Create Key Pair in AWS using the local SSH key pairs
16. AWS: Create Bastion Host in the DMZ subnet (SSH Jumpbox)
17. AWS: Create the 3 webnodes in the private subnets with Nginx on them
18. AWS: Create the Load balancer in the DMZ subnet with the 3 Webnodes behind it.
19. Output: output the ELB web address.

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
