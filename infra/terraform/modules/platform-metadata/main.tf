locals {
  metadata = jsonencode({
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  })
}
