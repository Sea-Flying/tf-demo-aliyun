terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.105.0"
    }
  }
}

provider "alicloud" {
  access_key = var.AK
  secret_key = var.SK
  region     = var.REGION
}

#新建一个VPC
resource "alicloud_vpc" "vpc" {
  name       = "tf-test-vpc"
  cidr_block = "10.0.0.0/8"
}

resource "alicloud_vswitch" "main" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "10.7.0.0/16"
  availability_zone = var.AZ
}

resource "alicloud_security_group" "default" {
  name = "default"
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_22_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}

#建一个规格ecs.n2.small 镜像ubuntu18.04的ECS
resource "alicloud_instance" "instance" {
  # cn-beijing
  availability_zone = var.AZ
  security_groups = alicloud_security_group.default.*.id

  # series III
  instance_type        = "ecs.n2.small"
  system_disk_category = "cloud_efficiency"
  image_id             = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name        = "tf-test-ecs"
  vswitch_id = alicloud_vswitch.main.id
  internet_max_bandwidth_out =10
  password = "FooBar123"
}

#建一个规格rds.mysql.t1.small, 存储10G的MySQL5.6
resource "alicloud_db_instance" "instance" {
  engine           = "MySQL"
  engine_version   = "5.6"
  instance_type    = "rds.mysql.t1.small"
  instance_storage = "10"
  vswitch_id       = alicloud_vswitch.main.id
}

resource "alicloud_db_account" "account" {
  instance_id = alicloud_db_instance.instance.id
  name        = "tf_account"
  password    = "!Test@123456"
}

resource "alicloud_db_database" "db" {
  instance_id = alicloud_db_instance.instance.id
  name        = "tf_database"
}

resource "alicloud_db_account_privilege" "privilege" {
  instance_id  = alicloud_db_instance.instance.id
  account_name = alicloud_db_account.account.name
  db_names     = [alicloud_db_database.db.name]
}

resource "alicloud_db_connection" "connection" {
  instance_id       = alicloud_db_instance.instance.id
  connection_prefix = "tf-example"
}

#建一个SLB, 添加一个监听tcp  21:2111, 带宽5M
resource "alicloud_slb" "slb" {
  name                 = "slb_test"
  specification        = "slb.s2.small"
  vswitch_id           = alicloud_vswitch.main.id
  internet_charge_type = "PayByTraffic"
}

resource "alicloud_slb_listener" "listener" {
  load_balancer_id = alicloud_slb.slb.id
  backend_port     = "2111"
  frontend_port    = "21"
  protocol         = "tcp"
  bandwidth        = "5"
}
