variable "smb_username" {
  type = string
  default = ""
}

variable "smb_password" {
  type = string
  default = ""
}

variable "backup_target" {
  type = string
  default = "cifs://ironman.christianbingman.com/Longhorn"
}
