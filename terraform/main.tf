terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------------------------------------------------
# AWS Provider: Explicitly set to ap-south-1 (Mumbai)
# -------------------------------------------------------------
provider "aws" {
  region = var.aws_region # Defaults to ap-south-1
}

# -------------------------------------------------------------
# Data Sources: Default VPC & Ubuntu AMI in ap-south-1
# -------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

# Recreates / adopts default subnet in ap-south-1a
resource "aws_default_subnet" "default_az1" {
  availability_zone = "ap-south-1a"

  tags = {
    Name   = "Default-Subnet-ap-south-1a"
    Region = "ap-south-1"
  }
}

locals {
  selected_subnet_id = var.subnet_id != "" ? var.subnet_id : aws_default_subnet.default_az1.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------------------------------------------
# Security Group: Jenkins / DevSecOps & Monitoring (ap-south-1)
# -------------------------------------------------------------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-devsecops-sg"
  description = "Security group for Jenkins, SonarQube, Prometheus, Grafana, and Docker app in ap-south-1"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Jenkins Web Console
  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # SonarQube Server
  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Grafana Dashboard
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Prometheus Server
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Node Exporter Metrics
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Netflix App Container Direct Run
  ingress {
    description = "Netflix Docker App Direct Run"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Outbound Rule (allow all egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "Jenkins-DevSecOps-SG"
    Region = "ap-south-1"
  }
}

# -------------------------------------------------------------
# Security Group: Kubernetes Cluster Master & Worker (ap-south-1)
# -------------------------------------------------------------
resource "aws_security_group" "k8s_sg" {
  count       = var.enable_k8s_cluster ? 1 : 0
  name        = "k8s-cluster-sg"
  description = "Security group for Kubernetes Master and Worker nodes in ap-south-1"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # NodePort Services (including Netflix NodePort 30007)
  ingress {
    description = "K8s NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Node Exporter on K8s Nodes
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow all internal communication between cluster nodes & Jenkins SG
  ingress {
    description     = "Internal Cluster & Jenkins Traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.jenkins_sg.id]
    self            = true
  }

  # Outbound Rule (allow all egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "K8s-Cluster-SG"
    Region = "ap-south-1"
  }
}

# -------------------------------------------------------------
# EC2: Jenkins / DevSecOps & Monitoring Server (ap-south-1)
# -------------------------------------------------------------
resource "aws_instance" "jenkins_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = var.install_tools_via_userdata ? file("${path.module}/userdata-jenkins.sh") : null

  tags = {
    Name   = "Jenkins-DevSecOps-Server"
    Region = "ap-south-1"
  }
}

# -------------------------------------------------------------
# Elastic IP Association: 13.203.5.121 in ap-south-1
# -------------------------------------------------------------
data "aws_eip" "existing_jenkins_eip" {
  count     = var.elastic_ip != "" ? 1 : 0
  public_ip = var.elastic_ip
}

resource "aws_eip_association" "jenkins_eip_assoc" {
  count         = var.elastic_ip != "" ? 1 : 0
  instance_id   = aws_instance.jenkins_server.id
  allocation_id = data.aws_eip.existing_jenkins_eip[0].id
}

# -------------------------------------------------------------
# EC2: Kubernetes Master Node in ap-south-1 
# -------------------------------------------------------------
resource "aws_instance" "k8s_master" {
  count                       = var.enable_k8s_cluster ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k8s_instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.k8s_sg[0].id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "K8s-Master"
    Region = "ap-south-1"
  }
}

# -------------------------------------------------------------
# EC2: Kubernetes Worker Node in ap-south-1 
# -------------------------------------------------------------
resource "aws_instance" "k8s_worker" {
  count                       = var.enable_k8s_cluster ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.k8s_instance_type
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.k8s_sg[0].id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name   = "K8s-Worker"
    Region = "ap-south-1"
  }
}
