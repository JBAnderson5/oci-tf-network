# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.



# inputs

variable "compartment_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

# outputs



# logic


# resource or mixed module blocks



module "function" {
    source = "../../"

    compartment_id = var.compartment_id 

    app_name = "test-app"

    subnet_ids = [var.subnet_id]

    app_config = {"key" : "value"}

    create_apm_domain = true
    
}