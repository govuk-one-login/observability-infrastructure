module "storage" {
  source = "./modules/storage"

  name = var.name
  tags = var.tags
}