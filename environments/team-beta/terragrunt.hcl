# Team Beta environment
# To onboard a new team, copy this file to a new directory and update the inputs.

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/team-environment"
}

inputs = {
  team_name     = "beta"
  environment   = "dev"
  vpc_cidr      = "10.2.0.0/16"
  instance_type = "t4g.micro"
  allowed_ip    = "REPLACE_WITH_YOUR_IP/32" # curl -s https://checkip.amazonaws.com
}
