resource "yandex_iam_service_account" "service" {
  folder_id = var.folder_id
  name      = "bucket-sa"
}
#Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.service.id
  description        = "static access key for object storage"
}
# Назначение роли для сервисного аккаунта
resource "yandex_resourcemanager_folder_iam_member" "bucket-editor" {
  folder_id = var.folder_id
  role      = "editor"#,  kms.keys.encrypterDecrypter]
   
  #  for_each = toset(local.roles)

  
  # role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.service.id}"

  depends_on = [yandex_iam_service_account.service]


}

locals {
  roles = ["storage.admin", "kms.keys.encrypterDecrypter"]
}
#Создание симметричного ключа для бакета
resource "yandex_kms_symmetric_key" "encryptkey" {
  name              = "encryptkey"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

resource "yandex_storage_bucket" "my_bucket" {
    access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
    secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
    bucket = "suntsovvv-2024-12-04"    # Имя бакета
    acl    = "public-read"
    force_destroy = "true"
    
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = yandex_kms_symmetric_key.encryptkey.id
            sse_algorithm     = "aws:kms"
      }
    }
  }
 
}
resource "yandex_storage_object" "picture" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = yandex_storage_bucket.my_bucket.id
  key    = "picture.jpg"
  source = "./picture.jpg"
  acl = "public-read"

  depends_on = [yandex_storage_bucket.my_bucket]
}

