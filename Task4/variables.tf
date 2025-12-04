variable "project" {
	description = "Название проекта"
	type        = string
	default     = "future20"
}

variable "cloud_id" {
	description = "Cloud ID Yandex Cloud"
	type        = string
}

variable "folder_id" {
	description = "Folder ID Yandex Cloud"
	type        = string
}

variable "zone" {
	description = "Зона размещения"
	type        = string
	default     = "ru-central1-a"
}

variable "public_subnet_cidr" {
	description = "CIDR публичной подсети"
	type        = string
	default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
	description = "CIDR приватной подсети"
	type        = string
	default     = "10.0.2.0/24"
}

variable "ssh_ingress_cidr" {
	description = "Разрешенный диапазон для SSH"
	type        = string
	default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
	description = "Публичный SSH ключ в формате OpenSSH"
	type        = string
}

variable "image_family" {
	description = "Семейство образов для VM"
	type        = string
	default     = "ubuntu-2004-lts"
}

variable "app_vm_cores" {
	description = "Количество ядер для App VM"
	type        = number
	default     = 2
}

variable "app_vm_memory" {
	description = "Объем памяти для App VM (GB)"
	type        = number
	default     = 4
}

variable "app_root_disk_size" {
	description = "Размер корневого диска App VM (GB)"
	type        = number
	default     = 20
}

variable "app_data_disk_size" {
	description = "Размер дополнительного диска App VM (GB)"
	type        = number
	default     = 50
}

variable "db_vm_cores" {
	description = "Количество ядер для DB VM"
	type        = number
	default     = 2
}

variable "db_vm_memory" {
	description = "Объем памяти для DB VM (GB)"
	type        = number
	default     = 4
}

variable "db_root_disk_size" {
	description = "Размер корневого диска DB VM (GB)"
	type        = number
	default     = 20
}

variable "db_data_disk_size" {
	description = "Размер дополнительного диска DB VM (GB)"
	type        = number
	default     = 100
}

