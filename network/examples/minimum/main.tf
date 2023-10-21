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
    description = ""
}

# logic


# resource or mixed module blocks


module "vcn" {
    # https://developer.hashicorp.com/terraform/language/modules/sources#module-sources
   source = "../../"

    compartment_id = var.compartment_id
    vcn_display_name = var.vcn_display_name
}