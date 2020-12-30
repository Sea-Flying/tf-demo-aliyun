variable "AK" {
    type = string
    description = "My Aliyun AccessKey ID"
}

variable "SK" {
    type = string
    description = "My Aliyun AccessKey Secret"
}

variable "REGION" {
    type = string
    description = "Example Aliyun Region ID"
    default = "cn-beijing"
}

variable "AZ" {
    type = string
    description = "Example Aliyun Availability Zone ID"
    default = "cn-beijing-b"
}