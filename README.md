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

- (Terraform Providers)[https://registry.terraform.io/browse/providers]

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





