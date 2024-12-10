output "backet" {
 value = yandex_storage_bucket.my_bucket.bucket_domain_name
}

output "picture_key" {
  value = yandex_storage_object.picture.key
}
# output "lb_ip_address" {
#   value       =  yandex_lb_network_load_balancer.lb-1.listener.*.external_address_spec[0].*.address
#   description = "IP-адрес сетевого балансировщика"
# }