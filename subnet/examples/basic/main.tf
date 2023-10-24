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

output "subnet_object" {
    value = module.subnet.subnet
}

output "sl_object" {
    value = module.subnet.security_list
}

output "rt_object" {
    value = module.subnet.route_table
}



# logic


# resource or mixed module blocks


module "vcn" {
    # https://developer.hashicorp.com/terraform/language/modules/sources#module-sources
   source = "../../../network"

    compartment_id = var.compartment_id
    vcn_display_name = var.vcn_display_name
    cidr_blocks = ["10.0.0.0/16"]
    vcn_dns_label = "mydomain"

    create_internet_gateway = true 
    create_nat_gateway = true 
    create_service_gateway = true
}

module "subnet" {
    source = "../../"

    compartment_id = var.compartment_id
    network = module.vcn
    prefix = "basic"
    ssh_cidr = "0.0.0.0/0"
    cidr_block = "10.0.1.0/24"
    
}