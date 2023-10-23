


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



# outputs

output "subnet" {
  value = oci_core_subnet.this
}



# logic

locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"


  # trim dns label to be no more than 15 characters
  subnet_dns_label = substr(var.subnet_dns_label, 0, 15)

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

  route_table_id    = local.route_table_id
  security_list_ids = local.security_ids_list
}




