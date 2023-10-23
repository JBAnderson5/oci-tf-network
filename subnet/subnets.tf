


# inputs

variable "compartment_id" {
  type        = string
  description = "ocid of the compartment to create resources in."
}

# subnet
variable "prefix" {
  type        = string
  default     = null
  description = "the prefix to append to each resource's name"
}
variable "subnet_dns_label" {
  type    = string
  default = null
}
variable "cidr_block" {
  type        = string
  description = "cidr block value to assign to this subnet"
}


# routing
# TODO: needs to be implemented, but need to understand DRG, attachments, DRG route tables and route advertisements, and create network connection module first
/*
variable "dynamic_routing_gateway_list" {
  type        = list(string)
  default     = []
  description = "creates a route rule for each drg ocid in the list"
}
*/
variable "egress_traffic_location" {
  type        = string
  default     = "0.0.0.0/0"
  description = "cidr block. destination used for traffic leaving through an internet or nat gateway"
}




# outputs

output "subnet" {
  value = oci_core_subnet.this
}

output "route_table" {
  value = oci_core_route_table.this
}

# logic

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"


  # trim dns label to be no more than 15 characters
  subnet_dns_label = substr(var.subnet_dns_label, 0, 15)


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
      destination       = var.egress_traffic_location
      destination_type  = "CIDR_BLOCK"
    } } : {},

    local.internet_access == "full" ? { "internet_gateway" = {
      network_entity_id = local.internet_gateway.id
      description       = "Allow Internet Gateway routing"
      destination       = var.egress_traffic_location
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


resource "oci_core_subnet" "this" {

  cidr_block     = var.cidr_block
  compartment_id = var.compartment_id
  vcn_id         = local.vcn.id


  display_name = "${local.prefix}SN"
  dns_label    = local.subnet_dns_label

  #dns_label    = var.subnet_dns_label

  prohibit_public_ip_on_vnic = local.internet_access != "full" ? true : false

  route_table_id    = oci_core_route_table.this.id
  security_list_ids = [oci_core_security_list.this.id]
}


resource "oci_core_route_table" "this" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn

  display_name = "${local.prefix}RT"

  dynamic "route_rules" {
    for_each = local.routing_rules
    content {
      network_entity_id = each.value.network_entity_id

      description      = each.value.description
      destination      = each.value.destination
      destination_type = each.value.destination_type
    }
  }


}

