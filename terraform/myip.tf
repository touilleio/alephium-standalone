
module "myip" {
  source = "github.com/touilleio/terraform-public-ip"
  # Optional set a netmask, default to 32
  netmask = 24
}
