# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.



# inputs

variable "compartment_id" {
  type = string
}

variable "vcn_display_name" {
  type = string
}

# outputs

output "vcn_object" {
    value = module.vcn.vcn 
}

output "service_gateway_object" {
  value = module.vcn.service_gateway
}

output "service_cidr_object" {
  value = module.vcn.service_cidr
}

output " nat_gateway_object" {
  value = module.vcn.nat_gateway
}

output "internet_gateway_object" {
  value = module.vcn.internet_gateway
}



# logic


# resource or mixed module blocks


module "vcn" {
    # https://developer.hashicorp.com/terraform/language/modules/sources#module-sources
   source = "../../"

    compartment_id = var.compartment_id
    vcn_display_name = var.vcn_display_name
    cidr_blocks = ["10.0.0.0/16"]
    vcn_dns_label = "mydomain"

    create_internet_gateway = true 
    create_nat_gateway = true 
    create_service_gateway = true
}