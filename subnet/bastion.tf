

# inputs

variable "enable_bastion" {
    type = bool
    default = false
}


variable "bastion_allowlist" {
    type = string 
    default = "[0.0.0.0/0]"
}

variable "dns_proxy" {
    type = bool 
    default = true
    description = "Flag to enable FQDN and SOCKS5 Proxy Support."
}

variable "max_ttl" {
    type = number
    default = 3 * 60 * 60
    description = "max time a bastion session can be active. Upper limit is 3 hours"
}


# outputs

# logic 

# resource or mixed module blocks

resource "oci_bastion_bastion" "this" {

    count = var.enable_bastion ? 1 : 0
    compartment_id = var.compartment_id

    name = "${local.prefix}Bastion"
    target_subnet_id = oci_core_subnet.this.id
    client_cidr_block_allow_list = var.bastion_allowlist

    dns_proxy_status = var.dns_proxy == true ? "ENABLED" : "DISABLED"
    max_session_ttl_in_seconds = var.max_ttl
    bastion_type = "Standard"
}