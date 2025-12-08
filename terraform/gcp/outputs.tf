output "instance_name" {
  value       = google_compute_instance.student_app_vm.name
  description = "The name of the VM instance"
}

output "instance_external_ip" {
  value       = google_compute_address.static_ip.address
  description = "The external IP address of the VM instance"
}

output "instance_internal_ip" {
  value       = google_compute_instance.student_app_vm.network_interface.0.network_ip
  description = "The internal IP address of the VM instance"
}

output "instance_zone" {
  value       = google_compute_instance.student_app_vm.zone
  description = "The zone where the VM instance is deployed"
}
