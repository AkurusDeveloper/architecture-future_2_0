output "vpc_id" {
	description = "ID VPC сети"
	value       = yandex_vpc_network.main.id
}

output "public_subnet_id" {
	description = "ID публичной подсети"
	value       = yandex_vpc_subnet.public.id
}

output "private_subnet_id" {
	description = "ID приватной подсети"
	value       = yandex_vpc_subnet.private.id
}

output "app_vm_public_ip" {
	description = "Публичный IP адрес App VM"
	value       = yandex_compute_instance.app.network_interface[0].nat_ip_address
}

output "app_vm_private_ip" {
	description = "Приватный IP адрес App VM"
	value       = yandex_compute_instance.app.network_interface[0].ip_address
}

output "db_vm_private_ip" {
	description = "Приватный IP адрес DB VM"
	value       = yandex_compute_instance.db.network_interface[0].ip_address
}

