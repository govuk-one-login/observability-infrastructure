module "storage" {
  source = "./modules/storage"

  name = var.name
  tags = var.tags
}

module "secrets" {
  source = "./modules/secrets"

  name = var.name
  tags = var.tags
}