/*
Диаграмма автоматизации развертывания (для генерации diagram.png из PlantUML):

@startuml
!theme plain

skinparam rectangle {
    BackgroundColor #E1F5FF
    BorderColor #0066CC
}

skinparam database {
    BackgroundColor #FFF4E1
    BorderColor #FF9900
}

rectangle "Terraform управляет" as Terraform
rectangle "Ручная настройка" as Manual

cloud "Интернет" as Internet

rectangle "VPC" as VPC {
    rectangle "Публичная подсеть" as PublicSubnet {
        database "App VM\n(публичный IP)" as AppVM
        database "Root диск\n20 GB" as AppRoot
        database "Data диск\n50 GB" as AppData
    }
    
    rectangle "Приватная подсеть" as PrivateSubnet {
        database "DB VM\n(только приватный IP)" as DBVM
        database "Root диск\n20 GB" as DBRoot
        database "Data диск\n100 GB" as DBData
    }
    
    rectangle "Egress Gateway\n(NAT)" as NAT
    rectangle "Security Groups" as SG
}

Terraform --> VPC
Terraform --> PublicSubnet
Terraform --> PrivateSubnet
Terraform --> AppVM
Terraform --> DBVM
Terraform --> AppRoot
Terraform --> AppData
Terraform --> DBRoot
Terraform --> DBData
Terraform --> NAT
Terraform --> SG

Internet --> AppVM : "SSH, HTTP"
AppVM --> DBVM : "DB порт\n(5432)"
PrivateSubnet --> NAT : "Исходящий трафик"
NAT --> Internet

Manual --> AppVM : "Установка приложения"
Manual --> DBVM : "Настройка БД"

note right of Terraform
  **Terraform создает:**
  - VPC и подсети
  - VM и диски
  - NAT Gateway
  - Security Groups
  - Маршрутизацию
end note

note right of Manual
  **Ручная настройка:**
  - Установка приложения на App VM
  - Настройка БД на DB VM
  - Конфигурация мониторинга
end note

@enduml

Для генерации diagram.png выполните:
1. Установите PlantUML
2. Сохраните диаграмму выше в файл diagram.puml
3. Выполните: plantuml diagram.puml
4. Переименуйте diagram.png в Task4/diagram.png
*/

terraform {
	required_version = ">= 1.5.0, < 2.0.0"
	required_providers {
		yandex = {
			source  = "yandex-cloud/yandex"
			version = "~> 0.115"
		}
	}
}

provider "yandex" {
	cloud_id  = var.cloud_id
	folder_id = var.folder_id
	zone      = var.zone
}

# VPC
resource "yandex_vpc_network" "main" {
	name = "${var.project}-network"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
	name           = "${var.project}-subnet-public"
	network_id     = yandex_vpc_network.main.id
	zone           = var.zone
	v4_cidr_blocks = [var.public_subnet_cidr]
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
	name           = "${var.project}-subnet-private"
	network_id     = yandex_vpc_network.main.id
	zone           = var.zone
	v4_cidr_blocks = [var.private_subnet_cidr]
	route_table_id = yandex_vpc_route_table.private.id
}

# Egress Gateway для NAT
resource "yandex_vpc_gateway" "egress" {
	name                 = "${var.project}-egress"
	shared_egress_gateway {}
}

# Таблица маршрутизации для приватной подсети
resource "yandex_vpc_route_table" "private" {
	network_id = yandex_vpc_network.main.id
	static_route {
		destination_prefix = "0.0.0.0/0"
		gateway_id         = yandex_vpc_gateway.egress.id
	}
}

# Security Group для App VM
resource "yandex_vpc_security_group" "app" {
	name       = "${var.project}-sg-app"
	network_id = yandex_vpc_network.main.id

	ingress {
		description    = "SSH"
		protocol       = "TCP"
		port           = 22
		v4_cidr_blocks = [var.ssh_ingress_cidr]
	}

	ingress {
		description    = "HTTP"
		protocol       = "TCP"
		port           = 80
		v4_cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		description    = "HTTPS"
		protocol       = "TCP"
		port           = 443
		v4_cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		description    = "Any"
		protocol       = "ANY"
		from_port      = 0
		to_port        = 65535
		v4_cidr_blocks = ["0.0.0.0/0"]
	}
}

# Security Group для DB VM
resource "yandex_vpc_security_group" "db" {
	name       = "${var.project}-sg-db"
	network_id = yandex_vpc_network.main.id

	ingress {
		description    = "PostgreSQL"
		protocol       = "TCP"
		port           = 5432
		security_group_id = yandex_vpc_security_group.app.id
	}

	egress {
		description    = "Any"
		protocol       = "ANY"
		from_port      = 0
		to_port        = 65535
		v4_cidr_blocks = ["0.0.0.0/0"]
	}
}

# Образ для VM
data "yandex_compute_image" "ubuntu" {
	family = var.image_family
}

# App VM
resource "yandex_compute_instance" "app" {
	name        = "${var.project}-app"
	platform_id = "standard-v3"

	resources {
		cores  = var.app_vm_cores
		memory = var.app_vm_memory
	}

	boot_disk {
		initialize_params {
			image_id = data.yandex_compute_image.ubuntu.id
			size     = var.app_root_disk_size
		}
	}

	secondary_disk {
		disk_id = yandex_compute_disk.app_data.id
	}

	network_interface {
		subnet_id          = yandex_vpc_subnet.public.id
		nat                = true
		security_group_ids = [yandex_vpc_security_group.app.id]
	}

	metadata = {
		ssh-keys = "ubuntu:${var.ssh_public_key}"
	}
}

# Data диск для App VM
resource "yandex_compute_disk" "app_data" {
	name     = "${var.project}-app-data"
	type     = "network-hdd"
	size     = var.app_data_disk_size
	zone     = var.zone
}

# DB VM
resource "yandex_compute_instance" "db" {
	name        = "${var.project}-db"
	platform_id = "standard-v3"

	resources {
		cores  = var.db_vm_cores
		memory = var.db_vm_memory
	}

	boot_disk {
		initialize_params {
			image_id = data.yandex_compute_image.ubuntu.id
			size     = var.db_root_disk_size
		}
	}

	secondary_disk {
		disk_id = yandex_compute_disk.db_data.id
	}

	network_interface {
		subnet_id          = yandex_vpc_subnet.private.id
		security_group_ids = [yandex_vpc_security_group.db.id]
	}

	metadata = {
		ssh-keys = "ubuntu:${var.ssh_public_key}"
	}
}

# Data диск для DB VM
resource "yandex_compute_disk" "db_data" {
	name     = "${var.project}-db-data"
	type     = "network-hdd"
	size     = var.db_data_disk_size
	zone     = var.zone
}

