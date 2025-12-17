output "proxy_public_ip" {
  value = module.proxy.public_ip
}

output "gatekeeper_public_ip" {
  value = module.gatekeeper.public_ip
}
