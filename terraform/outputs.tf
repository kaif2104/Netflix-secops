locals {
  jenkins_ip = var.elastic_ip != "" ? var.elastic_ip : aws_instance.jenkins_server.public_ip
}

# -------------------------------------------------------------
# EC2 Public IPs & SSH Commands
# -------------------------------------------------------------
output "jenkins_server_public_ip" {
  description = "Public Elastic IP of the Jenkins / DevSecOps server"
  value       = local.jenkins_ip
}

output "ssh_command_jenkins" {
  description = "Ready-to-run SSH command for Jenkins server"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${local.jenkins_ip}"
}

output "k8s_master_public_ip" {
  description = "Public IP of the Kubernetes Master node (if enabled)"
  value       = var.enable_k8s_cluster ? aws_instance.k8s_master[0].public_ip : null
}

output "ssh_command_k8s_master" {
  description = "SSH command for Kubernetes Master node"
  value       = var.enable_k8s_cluster ? "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.k8s_master[0].public_ip}" : null
}

output "k8s_worker_public_ip" {
  description = "Public IP of the Kubernetes Worker node (if enabled)"
  value       = var.enable_k8s_cluster ? aws_instance.k8s_worker[0].public_ip : null
}

output "ssh_command_k8s_worker" {
  description = "SSH command for Kubernetes Worker node"
  value       = var.enable_k8s_cluster ? "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.k8s_worker[0].public_ip}" : null
}

# -------------------------------------------------------------
# Service Web URLs (Built with Elastic IP)
# -------------------------------------------------------------
output "jenkins_url" {
  description = "Web URL for Jenkins Console"
  value       = "http://${local.jenkins_ip}:8080"
}

output "sonarqube_url" {
  description = "Web URL for SonarQube Dashboard"
  value       = "http://${local.jenkins_ip}:9000"
}

output "grafana_url" {
  description = "Web URL for Grafana Monitoring Dashboard"
  value       = "http://${local.jenkins_ip}:3000"
}

output "prometheus_url" {
  description = "Web URL for Prometheus Server"
  value       = "http://${local.jenkins_ip}:9090"
}

output "netflix_docker_app_url" {
  description = "Web URL for Netflix Docker Container direct run"
  value       = "http://${local.jenkins_ip}:8081"
}

output "netflix_k8s_nodeport_url" {
  description = "Web URL for Netflix deployed on Kubernetes (NodePort 30007)"
  value       = var.enable_k8s_cluster ? "http://${aws_instance.k8s_worker[0].public_ip}:30007" : null
}
