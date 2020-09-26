variable "services_map" {
  type = map(string)

  default = {
    "10000" = "Root"
    "11000" = "Prod"
    "12000" = "Test"
  }
}

