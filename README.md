# Terraform Cookbook

- [Terraform Cookbook](#terraform-cookbook)
  - [Introduction](#introduction)
    - [Infrastructure as Code](#infrastructure-as-code)
    - [Imperative vs Declarative](#imperative-vs-declarative)
  - [Documentation](#documentation)
  - [Installation](#installation)
    - [Linux](#linux)
  - [Components](#components)
    - [Core](#core)
    - [Plugins](#plugins)
    - [Configuration Files](#configuration-files)
    - [State Files](#state-files)
  - [Environment](#environment)
    - [AWS](#aws)
  - [Resource Deployment](#resource-deployment)
    - [Initialize](#initialize)
    - [Plan](#plan)
    - [Apply](#apply)
    - [Destroy](#destroy)
  - [Resource Updates](#resource-updates)
    - [State](#state)
    - [Plan](#plan-1)
    - [Change 1 - Add custom VPC](#change-1---add-custom-vpc)
    - [Change 2 - Add redundancy](#change-2---add-redundancy)
  - [Hashicorp Configuration Language](#hashicorp-configuration-language)
    - [Blocks](#blocks)
    - [Object Types](#object-types)
    - [References](#references)

## Introduction

Terraform is tool developed by Hashicorp which is used for automated deployment of infrastructure across multiple providers in public and private cloud. It is a must have tool in order to fully benefit from Infrastructure as Code concepts.

### Infrastructure as Code

Infrastructure as Code (IaC) is to provision an infrastructure through use of software to achieve consistent and predictable environment.

There are some principles of IaC such as:
- Infrastructure is defined as code (yaml, json, hashicorp dsl)
- Code is stored in VCS
- Infrastructure definition can be imperative or declarative (prefered way)
- Deployment is idempotent and consistent
- Deployment can use push or pull model

The IaC brings number of benefits to the table such as:
- Automated deployment
- Consistent environments
- Repeatable process
- Reusable components
- Documented architecture

### Imperative vs Declarative

Infrastructure defined in imperative (procedural) way would mean you need to specify each configuration item as well as the order in which these items need to be applied to get desired outcome.

On the other hand, infrastructure defined in declarative way you only define the desired outcome, leaving implementation details up to software.

## Documentation

- [HCL Best Practices](https://www.terraform.io/docs/extend/best-practices/index.html)
- [Terraform Providers](https://registry.terraform.io/browse/providers)

## Installation

Hashicorp provides number of [packages](https://www.terraform.io/downloads.html) for various operating systems such Mac OS, Linux, Windows and others. Example below demostrates installation on Ubuntu Linux distribution.

### Linux

Terraform is distributed as single binary. In order to isntall it on Linux system, download and extract the archive content in the folder that is included in your `PATH` variable. You can leverage the `install-terraform.sh` script in the `recipes` folder.

```bash
# Define version
TERRAFORM_VERSION=0.14.10

# Download, extract and move
wget -O "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    "https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Unzip the archive
sudo unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin

# Cleanup
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
```

Once installed, verify by invoking version information.

```bash
terraform --version
Terraform v0.14.10
```

## Components

### Core

You may notice from the installation steps for Linux, terraform comes as single compiled binary that is written in Go language. It is called Terraform Core and it includes everyhing that is required for running the base software.

### Plugins

Terraform plugins are executable binaries written in Go Language which extend the capabilities of Core. Currently there is just one type of plugin - `providers`. Some example providers include be `AWS`, `Azure`, `GCP`, `Kubernetes`. 

### Configuration Files

Terraform files `.tf` store configuration. The configuration files may include `comments`, `variables`, `provider configuration`, `data sources`, `resources`, `outputs`.

```bash
# Variables
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-1"

# Provider
provider "aws" {

  access_key = "var.access_key"
  secret_key = "var.secret_key"
  region = "var.aws_region"
}

# Data source
data "aws_ami" "alx" {
  most_recent = true
  owners = ["amazon"]
  filters {}
}

# Resource
resource "aws_instance" "ex" {
  ami = "data.aws_ami.alx.id"
  instance_type = "t2.micro"
}

# Output
output = "aws_public_ip" {
  value =
  "aws_instance.ex.public_dns"
}
```

### State Files

When resources have been provisioned Terraform state file(s) are used to keep track of the current state.


## Environment

### AWS

To provision infrastructure on AWS, Terraform will require you to configure credentials with necessary permissions. 

For example, I have an existing AWS IAM group `AWSAdmins` which has attached policy `AdministratorAccess`. In order to create a new user, make it member of this group and generate credentials you can leverage `create_iam_user.sh` script located in `recipes` directory. It uses aws cli to perform these actions.

```bash
# Define IAM Username
TF_IAM_USER="tfdemo"

# Create and add user to group
aws iam create-user --user-name $TF_IAM_USER
aws iam add-user-to-group \
--group-name AWSAdmins \
--user-name $TF_IAM_USER

# Generate access key
aws iam create-access-key --user-name $TF_IAM_USER
```

The output of last command will contain the value for `AccessKeyId` and `SecretAccessKey` which you need to enter in the `.tfvars` file.

Next, you need to generate Key pair, you can leverage `create_key_pair.sh` script located in `recipes` directory.

```bash
# Define Key Pair Name
TF_EC2_KEYPAIR_NAME="tfkey"

# Create key pair
aws ec2 create-key-pair --key-name $TF_EC2_KEYPAIR_NAME --region us-east-1
```

The output of last command will contain the value for `KeyMaterial` and `KeyName`. The value of `KeyMaterial` needs to be stored in the file and path needs to be defined in the `tfvars` file. Be aware that the value of `KeyMaterial` also includes extra `\n` newline characters, remove them before saving.


## Resource Deployment

Now that the `webapp.tfvar` file has been pupulated with required credentials it is time to test our configuration.

### Initialize

```bash
cd examples/webapp

# Initialize configuration and downloads required plugins
terraform init
Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v3.36.0...
- Installed hashicorp/aws v3.36.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

```

### Plan

```bash
# Evaluates configuration files, loads variables, loads current state and generates tfplan file
terraform plan --out webapp.tfplan
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_default_vpc.default will be created
  + resource "aws_default_vpc" "default" {
      + arn                              = (known after apply)
      + assign_generated_ipv6_cidr_block = (known after apply)
      + cidr_block                       = (known after apply)
      + default_network_acl_id           = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_group_id        = (known after apply)
      + dhcp_options_id                  = (known after apply)
      + enable_classiclink               = (known after apply)
      + enable_classiclink_dns_support   = (known after apply)
      + enable_dns_hostnames             = (known after apply)
      + enable_dns_support               = true
      + id                               = (known after apply)
      + instance_tenancy                 = (known after apply)
      + ipv6_association_id              = (known after apply)
      + ipv6_cidr_block                  = (known after apply)
      + main_route_table_id              = (known after apply)
      + owner_id                         = (known after apply)
      + tags_all                         = (known after apply)
    }

  # aws_instance.nginx will be created
  + resource "aws_instance" "nginx" {
      + ami                          = "ami-087099ed8e934cdf1"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = "tfkey"
      + outpost_arn                  = (known after apply)
      + password_data                = (known after apply)
      + placement_group              = (known after apply)
      + primary_network_interface_id = (known after apply)
      + private_dns                  = (known after apply)
      + private_ip                   = (known after apply)
      + public_dns                   = (known after apply)
      + public_ip                    = (known after apply)
      + secondary_private_ips        = (known after apply)
      + security_groups              = (known after apply)
      + source_dest_check            = true
      + subnet_id                    = (known after apply)
      + tenancy                      = (known after apply)
      + vpc_security_group_ids       = (known after apply)

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_security_group.allow_ssh will be created
  + resource "aws_security_group" "allow_ssh" {
      + arn                    = (known after apply)
      + description            = "Allow ports for nginx demo"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "nginx_demo"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + vpc_id                 = (known after apply)
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + aws_instance_public_dns = (known after apply)

------------------------------------------------------------------------

This plan was saved to: webapp.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "webapp.tfplan"
```

### Apply

```bash
terraform apply "webapp.tfplan"
aws_default_vpc.default: Creating...
aws_default_vpc.default: Still creating... [10s elapsed]
aws_default_vpc.default: Creation complete after 19s [id=vpc-09fa1c74]
aws_security_group.allow_ssh: Creating...
aws_security_group.allow_ssh: Creation complete after 6s [id=sg-0668d200e4f8800f8]
aws_instance.nginx: Creating...
aws_instance.nginx: Still creating... [10s elapsed]
aws_instance.nginx: Still creating... [20s elapsed]
aws_instance.nginx: Still creating... [30s elapsed]
aws_instance.nginx: Provisioning with 'remote-exec'...
aws_instance.nginx: Provisioning with 'remote-exec'...
aws_instance.nginx (remote-exec): Connecting to remote host via SSH...
aws_instance.nginx (remote-exec):   Host: 34.232.67.164
aws_instance.nginx (remote-exec):   User: ec2-user
aws_instance.nginx (remote-exec):   Password: false
aws_instance.nginx (remote-exec):   Private key: true
aws_instance.nginx (remote-exec):   Certificate: false
aws_instance.nginx (remote-exec):   SSH Agent: true
aws_instance.nginx (remote-exec):   Checking Host Key: false
aws_instance.nginx (remote-exec):   Target Platform: unix
aws_instance.nginx: Still creating... [40s elapsed]
aws_instance.nginx (remote-exec): Connecting to remote host via SSH...
aws_instance.nginx (remote-exec):   Host: 34.232.67.164
aws_instance.nginx (remote-exec):   User: ec2-user
aws_instance.nginx (remote-exec):   Password: false
aws_instance.nginx (remote-exec):   Private key: true
aws_instance.nginx (remote-exec):   Certificate: false
aws_instance.nginx (remote-exec):   SSH Agent: true
aws_instance.nginx (remote-exec):   Checking Host Key: false
aws_instance.nginx (remote-exec):   Target Platform: unix
aws_instance.nginx (remote-exec): Connecting to remote host via SSH...
aws_instance.nginx (remote-exec):   Host: 34.232.67.164
aws_instance.nginx (remote-exec):   User: ec2-user
aws_instance.nginx (remote-exec):   Password: false
aws_instance.nginx (remote-exec):   Private key: true
aws_instance.nginx (remote-exec):   Certificate: false
aws_instance.nginx (remote-exec):   SSH Agent: true
aws_instance.nginx (remote-exec):   Checking Host Key: false
aws_instance.nginx (remote-exec):   Target Platform: unix
aws_instance.nginx (remote-exec): Connecting to remote host via SSH...
aws_instance.nginx (remote-exec):   Host: 34.232.67.164
aws_instance.nginx (remote-exec):   User: ec2-user
aws_instance.nginx (remote-exec):   Password: false
aws_instance.nginx (remote-exec):   Private key: true
aws_instance.nginx (remote-exec):   Certificate: false
aws_instance.nginx (remote-exec):   SSH Agent: true
aws_instance.nginx (remote-exec):   Checking Host Key: false
aws_instance.nginx (remote-exec):   Target Platform: unix
aws_instance.nginx (remote-exec): Connected!
aws_instance.nginx: Still creating... [50s elapsed]
aws_instance.nginx (remote-exec): Loaded plugins: priorities, update-motd,
aws_instance.nginx (remote-exec):               : upgrade-helper
aws_instance.nginx (remote-exec): Resolving Dependencies
aws_instance.nginx (remote-exec): --> Running transaction check
aws_instance.nginx (remote-exec): ---> Package nginx.x86_64 1:1.18.0-1.41.amzn1 will be installed
aws_instance.nginx (remote-exec): --> Processing Dependency: libprofiler.so.0()(64bit) for package: 1:nginx-1.18.0-1.41.amzn1.x86_64
aws_instance.nginx (remote-exec): --> Running transaction check
aws_instance.nginx (remote-exec): ---> Package gperftools-libs.x86_64 0:2.0-11.5.amzn1 will be installed
aws_instance.nginx (remote-exec): --> Processing Dependency: libunwind.so.8()(64bit) for package: gperftools-libs-2.0-11.5.amzn1.x86_64
aws_instance.nginx (remote-exec): --> Running transaction check
aws_instance.nginx (remote-exec): ---> Package libunwind.x86_64 0:1.1-10.8.amzn1 will be installed
aws_instance.nginx (remote-exec): --> Finished Dependency Resolution

aws_instance.nginx (remote-exec): Dependencies Resolved

aws_instance.nginx (remote-exec): ========================================
aws_instance.nginx (remote-exec):  Package   Arch   Version
aws_instance.nginx (remote-exec):                      Repository    Size
aws_instance.nginx (remote-exec): ========================================
aws_instance.nginx (remote-exec): Installing:
aws_instance.nginx (remote-exec):  nginx     x86_64 1:1.18.0-1.41.amzn1
aws_instance.nginx (remote-exec):                      amzn-updates 603 k
aws_instance.nginx (remote-exec): Installing for dependencies:
aws_instance.nginx (remote-exec):  gperftools-libs
aws_instance.nginx (remote-exec):            x86_64 2.0-11.5.amzn1
aws_instance.nginx (remote-exec):                      amzn-main    570 k
aws_instance.nginx (remote-exec):  libunwind x86_64 1.1-10.8.amzn1
aws_instance.nginx (remote-exec):                      amzn-main     72 k

aws_instance.nginx (remote-exec): Transaction Summary
aws_instance.nginx (remote-exec): ========================================
aws_instance.nginx (remote-exec): Install  1 Package (+2 Dependent packages)

aws_instance.nginx (remote-exec): Total download size: 1.2 M
aws_instance.nginx (remote-exec): Installed size: 3.0 M
aws_instance.nginx (remote-exec): Downloading packages:
aws_instance.nginx (remote-exec): (1/3): libunwind-1 |  72 kB   00:00
aws_instance.nginx (remote-exec): (2/3): gperftools- | 570 kB   00:00
aws_instance.nginx (remote-exec): (3/3): nginx-1.18. | 603 kB   00:00
aws_instance.nginx (remote-exec): ----------------------------------------
aws_instance.nginx (remote-exec): Total      5.4 MB/s | 1.2 MB  00:00
aws_instance.nginx (remote-exec): Running transaction check
aws_instance.nginx (remote-exec): Running transaction test
aws_instance.nginx (remote-exec): Transaction test succeeded
aws_instance.nginx (remote-exec): Running transaction
aws_instance.nginx (remote-exec):   Installing : libunwin [         ] 1/3
aws_instance.nginx (remote-exec):   Installing : libunwin [#####    ] 1/3
aws_instance.nginx (remote-exec):   Installing : libunwin [#######  ] 1/3
aws_instance.nginx (remote-exec):   Installing : libunwin [######## ] 1/3
aws_instance.nginx (remote-exec):   Installing : libunwind-1.1-10.8   1/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [         ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [#        ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [##       ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [###      ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [####     ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [#####    ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [######   ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [#######  ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftoo [######## ] 2/3
aws_instance.nginx (remote-exec):   Installing : gperftools-libs-2.   2/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [         ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [#        ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [##       ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [###      ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [####     ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [#####    ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [######   ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [#######  ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx- [######## ] 3/3
aws_instance.nginx (remote-exec):   Installing : 1:nginx-1.18.0-1.4   3/3
aws_instance.nginx (remote-exec):   Verifying  : libunwind-1.1-10.8   1/3
aws_instance.nginx (remote-exec):   Verifying  : gperftools-libs-2.   2/3
aws_instance.nginx (remote-exec):   Verifying  : 1:nginx-1.18.0-1.4   3/3

aws_instance.nginx (remote-exec): Installed:
aws_instance.nginx (remote-exec):   nginx.x86_64 1:1.18.0-1.41.amzn1

aws_instance.nginx (remote-exec): Dependency Installed:
aws_instance.nginx (remote-exec):   gperftools-libs.x86_64 0:2.0-11.5.amzn1
aws_instance.nginx (remote-exec):   libunwind.x86_64 0:1.1-10.8.amzn1

aws_instance.nginx (remote-exec): Complete!
aws_instance.nginx (remote-exec): Starting nginx:          [  OK  ]
aws_instance.nginx: Creation complete after 53s [id=i-0dba3c6583daf932d]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

aws_instance_public_dns = "ec2-34-232-67-164.compute-1.amazonaws.com"
```

Once the deployment is completed, Terraform will create a new state file `terraform.tfstate`. You can also verify that the application is up and running.

```bash
curl -I http://ec2-34-232-67-164.compute-1.amazonaws.com
HTTP/1.1 200 OK
Server: nginx/1.18.0
Date: Tue, 13 Apr 2021 13:41:05 GMT
Content-Type: text/html
Content-Length: 3770
Last-Modified: Mon, 05 Oct 2020 22:16:48 GMT
Connection: keep-alive
ETag: "5f7b9b50-eba"
Accept-Ranges: bytes

```

### Destroy

After you are done with testing, use `destroy` argument to deprovision infrastructure.

```bash
terraform destroy
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # aws_default_vpc.default will be destroyed
  - resource "aws_default_vpc" "default" {
      - arn                              = "arn:aws:ec2:us-east-1:XXXXXXXXXXXX:vpc/vpc-09fa1c74" -> null
      - assign_generated_ipv6_cidr_block = false -> null
      - cidr_block                       = "172.31.0.0/16" -> null
      - default_network_acl_id           = "acl-e46e2799" -> null
      - default_route_table_id           = "rtb-ed781593" -> null
      - default_security_group_id        = "sg-517b5e75" -> null
      - dhcp_options_id                  = "dopt-b18f0ccb" -> null
      - enable_classiclink               = false -> null
      - enable_classiclink_dns_support   = false -> null
      - enable_dns_hostnames             = true -> null
      - enable_dns_support               = true -> null
      - id                               = "vpc-09fa1c74" -> null
      - instance_tenancy                 = "default" -> null
      - main_route_table_id              = "rtb-ed781593" -> null
      - owner_id                         = "XXXXXXXXXXXX" -> null
      - tags                             = {} -> null
      - tags_all                         = {} -> null
    }

  # aws_instance.nginx will be destroyed
  - resource "aws_instance" "nginx" {
      - ami                          = "ami-087099ed8e934cdf1" -> null
      - arn                          = "arn:aws:ec2:us-east-1:XXXXXXXXXXXX:instance/i-0dba3c6583daf932d" -> null
      - associate_public_ip_address  = true -> null
      - availability_zone            = "us-east-1e" -> null
      - cpu_core_count               = 1 -> null
      - cpu_threads_per_core         = 1 -> null
      - disable_api_termination      = false -> null
      - ebs_optimized                = false -> null
      - get_password_data            = false -> null
      - hibernation                  = false -> null
      - id                           = "i-0dba3c6583daf932d" -> null
      - instance_state               = "running" -> null
      - instance_type                = "t2.micro" -> null
      - ipv6_address_count           = 0 -> null
      - ipv6_addresses               = [] -> null
      - key_name                     = "tfkey" -> null
      - monitoring                   = false -> null
      - primary_network_interface_id = "eni-0362aaaaa9391cddb" -> null
      - private_dns                  = "ip-172-31-48-39.ec2.internal" -> null
      - private_ip                   = "172.31.48.39" -> null
      - public_dns                   = "ec2-34-232-67-164.compute-1.amazonaws.com" -> null
      - public_ip                    = "34.232.67.164" -> null
      - secondary_private_ips        = [] -> null
      - security_groups              = [
          - "nginx_demo",
        ] -> null
      - source_dest_check            = true -> null
      - subnet_id                    = "subnet-8c7f66b2" -> null
      - tenancy                      = "default" -> null
      - vpc_security_group_ids       = [
          - "sg-0668d200e4f8800f8",
        ] -> null

      - credit_specification {
          - cpu_credits = "standard" -> null
        }

      - enclave_options {
          - enabled = false -> null
        }

      - metadata_options {
          - http_endpoint               = "enabled" -> null
          - http_put_response_hop_limit = 1 -> null
          - http_tokens                 = "optional" -> null
        }

      - root_block_device {
          - delete_on_termination = true -> null
          - device_name           = "/dev/xvda" -> null
          - encrypted             = false -> null
          - iops                  = 100 -> null
          - tags                  = {} -> null
          - throughput            = 0 -> null
          - volume_id             = "vol-0f08d45fba8ba3e29" -> null
          - volume_size           = 8 -> null
          - volume_type           = "gp2" -> null
        }
    }

  # aws_security_group.allow_ssh will be destroyed
  - resource "aws_security_group" "allow_ssh" {
      - arn                    = "arn:aws:ec2:us-east-1:XXXXXXXXXXXX:security-group/sg-0668d200e4f8800f8" -> null
      - description            = "Allow ports for nginx demo" -> null
      - egress                 = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = ""
              - from_port        = 0
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "-1"
              - security_groups  = []
              - self             = false
              - to_port          = 0
            },
        ] -> null
      - id                     = "sg-0668d200e4f8800f8" -> null
      - ingress                = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = ""
              - from_port        = 22
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 22
            },
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = ""
              - from_port        = 80
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 80
            },
        ] -> null
      - name                   = "nginx_demo" -> null
      - owner_id               = "XXXXXXXXXXXX" -> null
      - revoke_rules_on_delete = false -> null
      - tags                   = {} -> null
      - vpc_id                 = "vpc-09fa1c74" -> null
    }

Plan: 0 to add, 0 to change, 3 to destroy.

Changes to Outputs:
  - aws_instance_public_dns = "ec2-34-232-67-164.compute-1.amazonaws.com" -> null

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_instance.nginx: Destroying... [id=i-0dba3c6583daf932d]
aws_instance.nginx: Still destroying... [id=i-0dba3c6583daf932d, 10s elapsed]
aws_instance.nginx: Still destroying... [id=i-0dba3c6583daf932d, 20s elapsed]
aws_instance.nginx: Still destroying... [id=i-0dba3c6583daf932d, 30s elapsed]
aws_instance.nginx: Destruction complete after 34s
aws_security_group.allow_ssh: Destroying... [id=sg-0668d200e4f8800f8]
aws_security_group.allow_ssh: Destruction complete after 1s
aws_default_vpc.default: Destroying... [id=vpc-09fa1c74]
aws_default_vpc.default: Destruction complete after 0s

Destroy complete! Resources: 3 destroyed.
```


## Resource Updates

It is quite common that the infrastructure you deploy will evolve over time to align with changing business needs. Therefore a IaC tool like Terraform needs to be able to assess the current state and apply any changes that were described in the updated configuration file.

### State

Terraform stores the current state in the `.tfstate` JSON format file. It contains resources mappings and metadata. It supports locking. It is created when you first apply the plan file.

The default location of this file is in local directory, however it is also possible to store it in remote location - AWS, Azure, NFS, Terraform Cloud.

A state file contents for deprovisioned infrastructure can look like follows:

```json
{
  "version": 4,
  "terraform_version": "0.14.10",
  "serial": 9,
  "lineage": "155591be-3aa1-233c-f105-0390b72ddfff",
  "outputs": {},
  "resources": []
}
```

Valid state if very important, therefore once you decide to manage infrastructure through Terraform make all changes through it and not manually.

### Plan

When Terraform applies new configuration to infrastructure it will go over these steps:
1. Inspect state
2. Create dependency graph
3. Perform additions, updates and deletions - in parallel when possible

It is also recommended to save the plan to a file.

### Change 1 - Add custom VPC

The first change we are going to introduce to `webapp` application the introduction of new VPC resource which also needs to include Internet Gateway, Subnet, Route Table, and Route Table association.

Since we are already using VCS, this change can be inspected in commit [27bf672](https://github.com/maroskukan/terraform-cookbook/commit/27bf6722353e44d614c8151c2a4ebef5dba7d78a). Once you happy with the review, lets start by `plan` phase.

```bash
cd examples/webapp/
terraform plan -out webapp.tfplan
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.nginx1 will be created
  + resource "aws_instance" "nginx1" {
      + ami                          = "ami-087099ed8e934cdf1"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = "tfkey"
      + outpost_arn                  = (known after apply)
      + password_data                = (known after apply)
      + placement_group              = (known after apply)
      + primary_network_interface_id = (known after apply)
      + private_dns                  = (known after apply)
      + private_ip                   = (known after apply)
      + public_dns                   = (known after apply)
      + public_ip                    = (known after apply)
      + secondary_private_ips        = (known after apply)
      + security_groups              = (known after apply)
      + source_dest_check            = true
      + subnet_id                    = (known after apply)
      + tenancy                      = (known after apply)
      + vpc_security_group_ids       = (known after apply)

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_internet_gateway.igw will be created
  + resource "aws_internet_gateway" "igw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + vpc_id   = (known after apply)
    }

  # aws_route_table.rtb will be created
  + resource "aws_route_table" "rtb" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = [
          + {
              + carrier_gateway_id         = ""
              + cidr_block                 = "0.0.0.0/0"
              + destination_prefix_list_id = ""
              + egress_only_gateway_id     = ""
              + gateway_id                 = (known after apply)
              + instance_id                = ""
              + ipv6_cidr_block            = ""
              + local_gateway_id           = ""
              + nat_gateway_id             = ""
              + network_interface_id       = ""
              + transit_gateway_id         = ""
              + vpc_endpoint_id            = ""
              + vpc_peering_connection_id  = ""
            },
        ]
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.rta-subnet1 will be created
  + resource "aws_route_table_association" "rta-subnet1" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_security_group.nginx-sg will be created
  + resource "aws_security_group" "nginx-sg" {
      + arn                    = (known after apply)
      + description            = "Allow ports for nginx demo"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "nginx-sg"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + vpc_id                 = (known after apply)
    }

  # aws_subnet.subnet1 will be created
  + resource "aws_subnet" "subnet1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "us-east-1a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.1.0.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags_all                        = (known after apply)
      + vpc_id                          = (known after apply)
    }

  # aws_vpc.vpc will be created
  + resource "aws_vpc" "vpc" {
      + arn                              = (known after apply)
      + assign_generated_ipv6_cidr_block = false
      + cidr_block                       = "10.1.0.0/16"
      + default_network_acl_id           = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_group_id        = (known after apply)
      + dhcp_options_id                  = (known after apply)
      + enable_classiclink               = (known after apply)
      + enable_classiclink_dns_support   = (known after apply)
      + enable_dns_hostnames             = true
      + enable_dns_support               = true
      + id                               = (known after apply)
      + instance_tenancy                 = "default"
      + ipv6_association_id              = (known after apply)
      + ipv6_cidr_block                  = (known after apply)
      + main_route_table_id              = (known after apply)
      + owner_id                         = (known after apply)
      + tags_all                         = (known after apply)
    }

Plan: 7 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + aws_instance_public_dns = (known after apply)

------------------------------------------------------------------------

This plan was saved to: webapp.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "webapp.tfplan"
```

When you are happy with the proposed changes use `apply` argument to executed the change and provision the infrastructure.

```bash
terraform apply "webapp.tfplan"
aws_vpc.vpc: Creating...
aws_vpc.vpc: Still creating... [10s elapsed]
aws_vpc.vpc: Still creating... [20s elapsed]
aws_vpc.vpc: Still creating... [30s elapsed]
aws_vpc.vpc: Still creating... [40s elapsed]
aws_vpc.vpc: Still creating... [50s elapsed]
aws_vpc.vpc: Still creating... [1m0s elapsed]
aws_vpc.vpc: Creation complete after 1m6s [id=vpc-0b06853b96aaae847]
aws_internet_gateway.igw: Creating...
aws_subnet.subnet1: Creating...
aws_security_group.nginx-sg: Creating...
aws_internet_gateway.igw: Still creating... [10s elapsed]
aws_subnet.subnet1: Still creating... [10s elapsed]
aws_security_group.nginx-sg: Still creating... [10s elapsed]
aws_internet_gateway.igw: Creation complete after 17s [id=igw-0367670995ac620d3]
aws_route_table.rtb: Creating...
aws_subnet.subnet1: Still creating... [20s elapsed]
aws_security_group.nginx-sg: Still creating... [20s elapsed]
aws_route_table.rtb: Still creating... [10s elapsed]
aws_subnet.subnet1: Still creating... [30s elapsed]
aws_security_group.nginx-sg: Still creating... [30s elapsed]
aws_route_table.rtb: Creation complete after 14s [id=rtb-0bdf091b60ee27b3f]
#
# Output omitted
#
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

aws_instance_public_dns = "ec2-52-55-93-62.compute-1.amazonaws.com"
```

Once the deployment is completed, you can inspect the `.tfstate` file to retrieve the current state along with all details.

Finally, verify the web applications by inspecing the reponse body.

```bash
curl ec2-52-55-93-62.compute-1.amazonaws.com
<html><head><title>Blue Team Server</title></head><body style="background-color:#1F778D"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Blue Team</span></span></p></body></html>
```

### Change 2 - Add redundancy

The second change that we are going to introduce to `webapp` application is the introduction of new network resources which will now include a Elastic Load Balancer, second subnet in new Availability Zone and a new EC2 instance. Security groups will be also updated to reflect new design.

This change can be inspected in commit [efd893](https://github.com/maroskukan/terraform-cookbook/commit/efd8937b379586f91b919a64b456f7b3bd861981). Once you happy with the review, lets start by `plan` phase which will overwrite our existing `.tfplan` file.

```bash
cd examples/webapp/
terraform plan -out webapp.tfplan
aws_vpc.vpc: Refreshing state... [id=vpc-0a8534e9866d67b8a]
aws_subnet.subnet1: Refreshing state... [id=subnet-0526bb834afd059fe]
aws_internet_gateway.igw: Refreshing state... [id=igw-05493650d45f1aa09]
aws_security_group.nginx-sg: Refreshing state... [id=sg-0ebac88bf142c3692]
aws_route_table.rtb: Refreshing state... [id=rtb-0b0a422fc339f024a]
aws_instance.nginx1: Refreshing state... [id=i-02c1ecd6c3b9766b3]
aws_route_table_association.rta-subnet1: Refreshing state... [id=rtbassoc-00d4a78aa5901538a]

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
  ~ update in-place

Terraform will perform the following actions:

  # aws_elb.web will be created
  + resource "aws_elb" "web" {
      + arn                         = (known after apply)
      + availability_zones          = (known after apply)
      + connection_draining         = false
      + connection_draining_timeout = 300
      + cross_zone_load_balancing   = true
      + dns_name                    = (known after apply)
      + id                          = (known after apply)
      + idle_timeout                = 60
      + instances                   = (known after apply)
      + internal                    = (known after apply)
      + name                        = "nginx-elb"
      + security_groups             = (known after apply)
      + source_security_group       = (known after apply)
      + source_security_group_id    = (known after apply)
      + subnets                     = (known after apply)
      + zone_id                     = (known after apply)

      + health_check {
          + healthy_threshold   = (known after apply)
          + interval            = (known after apply)
          + target              = (known after apply)
          + timeout             = (known after apply)
          + unhealthy_threshold = (known after apply)
        }

      + listener {
          + instance_port     = 80
          + instance_protocol = "http"
          + lb_port           = 80
          + lb_protocol       = "http"
        }
    }

  # aws_instance.nginx2 will be created
  + resource "aws_instance" "nginx2" {
      + ami                          = "ami-087099ed8e934cdf1"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = (known after apply)
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = "tfkey"
      + outpost_arn                  = (known after apply)
      + password_data                = (known after apply)
      + placement_group              = (known after apply)
      + primary_network_interface_id = (known after apply)
      + private_dns                  = (known after apply)
      + private_ip                   = (known after apply)
      + public_dns                   = (known after apply)
      + public_ip                    = (known after apply)
      + secondary_private_ips        = (known after apply)
      + security_groups              = (known after apply)
      + source_dest_check            = true
      + subnet_id                    = (known after apply)
      + tenancy                      = (known after apply)
      + vpc_security_group_ids       = [
          + "sg-0ebac88bf142c3692",
        ]

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = (known after apply)
          + device_index          = (known after apply)
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + tags                  = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }
    }

  # aws_route_table_association.rta-subnet2 will be created
  + resource "aws_route_table_association" "rta-subnet2" {
      + id             = (known after apply)
      + route_table_id = "rtb-0b0a422fc339f024a"
      + subnet_id      = (known after apply)
    }

  # aws_security_group.elb-sg will be created
  + resource "aws_security_group" "elb-sg" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
      + name                   = "nginx_elb_sg"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + vpc_id                 = "vpc-0a8534e9866d67b8a"
    }

  # aws_security_group.nginx-sg will be updated in-place
  ~ resource "aws_security_group" "nginx-sg" {
        id                     = "sg-0ebac88bf142c3692"
      ~ ingress                = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = ""
              - from_port        = 22
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 22
            },
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - description      = ""
              - from_port        = 80
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 80
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = null
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
          + {
              + cidr_blocks      = [
                  + "10.1.0.0/16",
                ]
              + description      = ""
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
            },
        ]
        name                   = "nginx-sg"
        tags                   = {}
        # (6 unchanged attributes hidden)
    }

  # aws_subnet.subnet2 will be created
  + resource "aws_subnet" "subnet2" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "us-east-1b"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.1.1.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = true
      + owner_id                        = (known after apply)
      + tags_all                        = (known after apply)
      + vpc_id                          = "vpc-0a8534e9866d67b8a"
    }

Plan: 5 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  ~ aws_instance_public_dns = "ec2-52-55-93-62.compute-1.amazonaws.com" -> (known after apply)

------------------------------------------------------------------------

This plan was saved to: webapp.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "webapp.tfplan"
```

When you are happy with the proposed changes use `apply` argument to executed the change and provision the infrastructure.

```bash
terraform apply "webapp.tfplan"
aws_subnet.subnet2: Creating...
aws_security_group.elb-sg: Creating...
aws_security_group.nginx-sg: Modifying... [id=sg-0ebac88bf142c3692]
aws_security_group.nginx-sg: Modifications complete after 3s [id=sg-0ebac88bf142c3692]
aws_subnet.subnet2: Still creating... [10s elapsed]
aws_security_group.elb-sg: Still creating... [10s elapsed]
aws_security_group.elb-sg: Creation complete after 14s [id=sg-0435f1072ca08c78f]
aws_subnet.subnet2: Creation complete after 14s [id=subnet-002fdb836192e8420]
aws_route_table_association.rta-subnet2: Creating...
aws_instance.nginx2: Creating...
aws_route_table_association.rta-subnet2: Creation complete after 1s [id=rtbassoc-0224545ee24f980ab]
aws_instance.nginx2: Still creating... [10s elapsed]
#
# Output Omitted
#
Apply complete! Resources: 5 added, 1 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

aws_instance_public_dns = "nginx-elb-1997202815.us-east-1.elb.amazonaws.com"
```

Once the deployment is completed, you can inspect the `.tfstate` file to retrieve the current state along with all details.

Finally, after few minutes verify the web applications by targeting ELB CNAME record and inspecing the reponse body.

```bash
# Blue team
curl nginx-elb-1997202815.us-east-1.elb.amazonaws.com
<html><head><title>Blue Team Server</title></head><body style="background-color:#1F778D"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Blue Team</span></span></p></body></html>

# Green team
curl nginx-elb-1997202815.us-east-1.elb.amazonaws.com
<html><head><title>Green Team Server</title></head><body style="background-color:#77A032"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Green Team</span></span></p></body></html>
```


## Hashicorp Configuration Language

HashiCorp Configuration Language (HCL) is a domain specific language used within Terraform configuration files `.tf`. It is human readable and editable and supports conditionals, functions and templates.

### Blocks

Terraform uses `blocks` to define an object. The basic syntax for this construct is as follows:

```bash
block_type label_one label_two {
  key = value
  embedded_block {
    key = value
  }
}
```

Block type can be `variable`, `provider`, `data`, `resource`, `output`. For example block for AWS VPC Route Table is as follows:

```json
resource "aws_route_table" "my-route-table" {
  vpc_id = "vpc-0a8534e9866d67b8a"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-05493650d45f1aa09"
  }
}
```

### Object Types

There are different object types available in HCL. For example, the below resource's embedded `ingress` block uses `number` to define ports and `string` to define protocol and `list` to define cidr_blocks, which contain only one element at the moment.

```json
resource "aws_security_group" "elb-sg" {
    name = "nginx_elb_sg"
    vpc_id = aws_vpc.vpc.id

    # HTTP access from anywhere
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
```

Next, an example of a `bool` object type is used for enable_dns_hostnames key property.

```bash
resource "aws_vpc" "vpc" {
    cidr_block = var.network_address_space
    enable_dns_hostnames = true
}
```

The last object type is `map`. This includes key value pairs which are comma separated.

```bash
map = {ec2 = "nginx1", type = "t2.micro", start = true}
```

### References

To reference an existing object within the configuration `tf` file you need to use references. In example below, we are referencing `aws_access_key`, `aws_secret_key` and `region` variables from `provider` object type called `aws`.

```bash
provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region = var.region
}
```

To access a value of an object we are referencing we need to postfix it with property name. For example to retrieve `id` of object `subnet1` of type `aws_subnet` we would use the following syntax:

```bash
resource "aws_instance" "nginx1" {
    ami = data.aws_ami.aws-linux.id
    instance_type = "t2.micro"
    subnet_id = aws_subnet.subnet1.id
    vpc_security_group_ids = [aws_security_group.nginx-sg.id]
    key_name = var.key_name
```

There are also special types of objects such as `local`, `self` and `module`.

To concatenate a value within variable you need to leverage string interpolation. For example to generate output full URL for application we would use the following syntax:

```bash
output "aws_webapp_url" {
    value = "http://${aws_elb.web.dns_name}"
}
```