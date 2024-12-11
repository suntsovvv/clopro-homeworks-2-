# Домашнее задание к занятию «Безопасность в облачных провайдерах»  

Используя конфигурации, выполненные в рамках предыдущих домашних заданий, нужно добавить возможность шифрования бакета.

---
## Задание 1. Yandex Cloud   

1. С помощью ключа в KMS необходимо зашифровать содержимое бакета:

 - создать ключ в KMS;
 - с помощью ключа зашифровать содержимое бакета, созданного ранее.

 Взял за основу наработки из прошлого задания и модифицировал манифест:
 ```yaml
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
  role      = "editor"
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
```
Применил:  
```bash
user@microk8s:~/clopro-homeworks-3$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_iam_service_account.service will be created
  + resource "yandex_iam_service_account" "service" {
      + created_at = (known after apply)
      + folder_id  = "b1gpta86451pk7tseq2b"
      + id         = (known after apply)
      + name       = "bucket-sa"
    }

  # yandex_iam_service_account_static_access_key.sa-static-key will be created
  + resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
      + access_key                   = (known after apply)
      + created_at                   = (known after apply)
      + description                  = "static access key for object storage"
      + encrypted_secret_key         = (known after apply)
      + id                           = (known after apply)
      + key_fingerprint              = (known after apply)
      + output_to_lockbox_version_id = (known after apply)
      + secret_key                   = (sensitive value)
      + service_account_id           = (known after apply)
    }

  # yandex_kms_symmetric_key.encryptkey will be created
  + resource "yandex_kms_symmetric_key" "encryptkey" {
      + created_at          = (known after apply)
      + default_algorithm   = "AES_256"
      + deletion_protection = false
      + folder_id           = (known after apply)
      + id                  = (known after apply)
      + name                = "encryptkey"
      + rotated_at          = (known after apply)
      + rotation_period     = "8760h"
      + status              = (known after apply)
    }

  # yandex_resourcemanager_folder_iam_member.bucket-editor will be created
  + resource "yandex_resourcemanager_folder_iam_member" "bucket-editor" {
      + folder_id = "b1gpta86451pk7tseq2b"
      + id        = (known after apply)
      + member    = (known after apply)
      + role      = "editor"
    }

  # yandex_storage_bucket.my_bucket will be created
  + resource "yandex_storage_bucket" "my_bucket" {
      + access_key            = (known after apply)
      + acl                   = "public-read"
      + bucket                = "suntsovvv-2024-12-04"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = true
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags (known after apply)

      + server_side_encryption_configuration {
          + rule {
              + apply_server_side_encryption_by_default {
                  + kms_master_key_id = (known after apply)
                  + sse_algorithm     = "aws:kms"
                }
            }
        }

      + versioning (known after apply)
    }

  # yandex_storage_object.picture will be created
  + resource "yandex_storage_object" "picture" {
      + access_key   = (known after apply)
      + acl          = "public-read"
      + bucket       = (known after apply)
      + content_type = (known after apply)
      + id           = (known after apply)
      + key          = "picture.jpg"
      + secret_key   = (sensitive value)
      + source       = "./picture.jpg"
    }

Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + backet      = (known after apply)
  + picture_key = "picture.jpg"

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

yandex_iam_service_account.service: Creating...
yandex_kms_symmetric_key.encryptkey: Creating...
yandex_kms_symmetric_key.encryptkey: Creation complete after 1s [id=abjnls9b0u0mqfbfbr9o]
yandex_iam_service_account.service: Creation complete after 3s [id=ajena37cocjo8i2cqfv6]
yandex_resourcemanager_folder_iam_member.bucket-editor: Creating...
yandex_iam_service_account_static_access_key.sa-static-key: Creating...
yandex_iam_service_account_static_access_key.sa-static-key: Creation complete after 2s [id=ajeqqrgvubj9014pekq7]
yandex_storage_bucket.my_bucket: Creating...
yandex_resourcemanager_folder_iam_member.bucket-editor: Creation complete after 3s [id=b1gpta86451pk7tseq2b/editor/serviceAccount:ajena37cocjo8i2cqfv6]
yandex_storage_bucket.my_bucket: Creation complete after 5s [id=suntsovvv-2024-12-04]
yandex_storage_object.picture: Creating...
yandex_storage_object.picture: Creation complete after 0s [id=picture.jpg]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

backet = "suntsovvv-2024-12-04.storage.yandexcloud.net"
picture_key = "picture.jpg"
user@microk8s:~/clopro-homeworks-3$ 
```
![image](https://github.com/user-attachments/assets/10c721be-0691-44b4-a2f4-24b67f30cf6b)

2. (Выполняется не в Terraform)* Создать статический сайт в Object Storage c собственным публичным адресом и сделать доступным по HTTPS:

 - создать сертификат;
 - создать статическую страницу в Object Storage и применить сертификат HTTPS;
 - в качестве результата предоставить скриншот на страницу с сертификатом в заголовке (замочек).
Купленного домена у меня нет.
Поэтому для интереса создал страницу, поместил в бакет.
![image](https://github.com/user-attachments/assets/27512b56-b82f-47cf-9514-b05d136f5518)
Яндекс в такой конфигурации оказыавется подставляет свой сертификат:
![image](https://github.com/user-attachments/assets/d21e85b1-b8c0-401d-b153-dd70ac1d5e0a)


