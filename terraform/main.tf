module "messaging_module" {
  source                  = "./modules/messaging"
  fruits_topic_name       = "fruits"
  audit_fruits_queue_name = "audit-fruits"
}

module "storage_module" {
  source             = "./modules/storage"
  fruits_table       = "fruits"
  audit_fruits_table = "audit-fruits"
}