variable "name" {
  description = "Component strings of resource names."
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Product")
    error_message = "Tags must contain the Key Product."
  }

  validation {
    condition     = contains(keys(var.tags), "System")
    error_message = "Tags must contain the Key System."
  }

  validation {
    condition     = contains(keys(var.tags), "Environment")
    error_message = "Tags must contain the Key Environment."
  }

  validation {
    condition     = contains(keys(var.tags), "Owner")
    error_message = "Tags must contain the Key Owner."
  }
}