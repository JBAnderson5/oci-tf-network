

# inputs

variable "existing_route_table_id" {
  type = string 
  default = null 
  description = "if provided, the subnet will use this route table instead of creating one"
  
}


# TODO: needs to be implemented, but need to understand DRG, attachments, DRG route tables and route advertisements, and create network connection module first
/*
variable "dynamic_routing_gateway_list" {
  type        = list(string)
  default     = []
  description = "creates a route rule for each drg ocid in the list"
}
*/
variable "anywhere" {
  type        = string
  default     = "0.0.0.0/0"
  description = "cidr block. destination used for traffic leaving through an internet or nat gateway"
}

# outputs

output "route_table" {
  value = oci_core_route_table.this
}

# logic

locals {

    route_table_id = var.existing_route_table_id != null ? var.existing_route_table_id : oci_core_route_table.this[0].id

    routing_rules = merge(
    local.service_gateway != null ? { "service_gateway" = {
      network_entity_id = local.service_gateway.id

      description      = "Allow Service Gateway routing"
      destination      = local.service_cidr
      destination_type = "SERVICE_CIDR_BLOCK"
    } } : {},

    local.nat_gateway != null ? { "nat_gateway" = {
      network_entity_id = local.nat_gateway.id
      description       = "Allow Nat Gateway routing for egress internet traffic"
      destination       = var.anywhere
      destination_type  = "CIDR_BLOCK"
    } } : {},

    local.internet_access == "full" ? { "internet_gateway" = {
      network_entity_id = local.internet_gateway.id
      description       = "Allow Internet Gateway routing"
      destination       = var.anywhere
      destination_type  = "CIDR_BLOCK"
    } } : {},

    /*

dynamic "route_rules" {
    for_each = toset(var.dynamic_routing_gateway_list)
    content {
      network_entity_id = route_rules.value
      description       = "DRG route rule"
      destination       = "TODO how do we get this value"
      destination_type  = "CIDR_BLOCK"
    }
  }
  */

  )
}

# resource or mixed module blocks


resource "oci_core_route_table" "this" {
    count = var.existing_route_table_id == null ? 1 : 0
  #Required
  compartment_id = var.compartment_id
  vcn_id         = local.vcn.id

  display_name = "${local.prefix}RT"

  dynamic "route_rules" {
    for_each = local.routing_rules
    content {
      network_entity_id = route_rules.value.network_entity_id

      description      = route_rules.value.description
      destination      = route_rules.value.destination
      destination_type = route_rules.value.destination_type
    }
  }


}