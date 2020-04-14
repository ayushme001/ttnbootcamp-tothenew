variable "default_tags" {
    type = map(string)
    default = {
        Name: "ayush-tf",
        owner: "ayush",
        purpose: "ayush-tf",
  }
}

