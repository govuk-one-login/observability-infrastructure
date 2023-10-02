variable "name" {
  description = "Component strings of resource names."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
}