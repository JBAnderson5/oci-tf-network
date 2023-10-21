# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.



# inputs


# outputs


# logic


# resource or mixed module blocks


module "vcn" {
    # https://developer.hashicorp.com/terraform/language/modules/sources#module-sources
   source = "../../"

    compartment_id = var.tenancy_ocid
    vcn_display_name = "MyVCN"
    create_nat_gateway = true 
    create_internet_gateway = true
}