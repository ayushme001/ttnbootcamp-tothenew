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
