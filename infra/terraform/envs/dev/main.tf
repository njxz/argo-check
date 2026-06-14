module "platform_metadata" {
  source = "../../modules/platform-metadata"

  environment = var.environment
  owner       = var.owner
}

