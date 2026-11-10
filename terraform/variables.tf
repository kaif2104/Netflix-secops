variable "aws_region" {
  description = "AWS Region to deploy resources into"
  type        = string
  default     = "ap-south-1" # Elastic IP 13.203.5.121 is located in ap-south-1 (Mumbai)
}

variable "subnet_id" {
  description = "Optional custom Subnet ID. If empty, the default subnet for the first available AZ will be automatically restored/used."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of the existing AWS Key Pair to attach to EC2 instances"
  type        = string
  default     = "task"
}

variable "elastic_ip" {
  description = "Existing Elastic IP to associate with the Jenkins server (e.g. 13.203.5.121)"
  type        = string
  default     = "13.203.5.121"
}

variable "allowed_cidr_blocks" {
  description = "CIDR block permitted to access inbound management ports (use your own IP in production e.g. ['203.0.113.50/32'])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for the Jenkins / DevSecOps server"
  type        = string
  default     = "c7i-flex.large"
}

variable "k8s_instance_type" {
  description = "EC2 instance type for Kubernetes Master and Worker nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "enable_k8s_cluster" {
  description = "Set to true to also provision Kubernetes Master and Worker EC2 instances"
  type        = bool
  default     = false
}

variable "install_tools_via_userdata" {
  description = "If true, automatically executes installation scripts (Jenkins, Docker, SonarQube, Trivy, Prometheus, Grafana, Node Exporter) on first boot"
  type        = bool
  default     = false
}
