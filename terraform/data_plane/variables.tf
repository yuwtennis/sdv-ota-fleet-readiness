variable "vpc_id" {
  description = ""
  type        = string
}

variable "region_name" {
  description = ""
  type        = string
}

variable "zone_name" {
  description = ""
  type        = string
}

variable "project" {
  description = ""
  type        = object({
    id=string,
    number=number
  })
}