variable "default_tags" {
    type = map(string)
    default = {
        Name: "ayush-tf",
        owner: "ayush",
        purpose: "ayush-tf",
  }
}

variable "cluster-name" {
  default = "cluster"
  type    = string
}

variable "enable_route53" {
  description = "enable route 53"
  type        = bool
  default = "1"
}


variable "protocol" {
  description = "find protcol of LB"
  type        = number
  default = "3000"
}

