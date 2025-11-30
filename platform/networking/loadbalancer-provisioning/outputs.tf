output "ingress_lb_public_ip" {
  description = "Public IP address for the Ingress Controller Load Balancer (use for wildcard DNS)"
  value       = aws_eip.ingress_lb.public_ip
}

output "ingress_lb_allocation_id" {
  description = "Allocation ID of the Elastic IP for reference"
  value       = aws_eip.ingress_lb.allocation_id
}

output "dns_record_value" {
  description = "Value to use for the wildcard DNS A record (*.fawkes.idp)"
  value       = aws_eip.ingress_lb.public_ip
}
