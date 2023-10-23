


# inputs

variable "existing_sl_ids" {
  type = list(string)
  default = null 
  description = "a list of existing sl ids"
}


# egress
variable "all_outbound_traffic" {
  type        = bool
  default     = true
  description = "creates security rule allowing all egress traffic out to anywhere"
}

variable "custom_tcp_egress_rules" {
  type = map(object({
    dest_cidr = string,
    min = number,
    max = number
  }))
  
  default = {}
  description = "creates statefull tcp security list rules from a range of destination ports to any port with a specific destination cidr"
}
variable "tcp_all_ports_egress_cidrs" {
  type = list(string)
  default = []
  description = "used to creste stateful rcp security list rules from all destination ports to the given list of source cidrs"
}

variable "custom_udp_egress_rules" {
    type = map(object({
        dest_cidr   = string,
        min = number,
        max = number,
  }))
   default = {}
  description = "creates stateful udp security list rules from a range of destination ports to any port with a specific destination cidr"
}

variable "icmp_egress_cidrs" {
  type = list(string)
  default = []
  description = "list of cidr blocks to allow all icmp traffic out to"
}

variable "icmp_egress_service" {
  type = bool 
  default = false 
  description = "if true, allows all icmp traffic out to oracle services network"
}




# ingress

variable "ssh_cidr" {
  type        = string
  default     = null
  description = "the cidr block to allow ssh traffic on. Common values are 0.0.0.0/0 your vcn cidr or your bastion subnet cidr"
}




variable "custom_tcp_ingress_rules" {
  type = map(object({
        source_cidr   = string,
        min = number,
        max = number,
  }))

  default = {}
  description = "creates stateful tcp security list rules to a range of destination ports from any port with a specific source cidr"
}
variable "tcp_all_ports_ingress_cidrs" {
  type = list(string)
  default = []
  description = "used to create stateful tcp security list rules to all destination ports from the given list of source cidrs"
}


variable "custom_udp_ingress_rules" {
    type = map(object({
        source_cidr   = string,
        min = number,
        max = number,
  }))
   default = {}
  description = "creates stateful udp security list rules to a range of destination ports from any port with a specific source cidr"
}

variable "standard_icmp" {
  type        = bool
  default     = true
  description = "if true, turns on some standard icmp traffic"
}

variable "icmp_ingress_cidrs" {
  type = list(string)
  default = []
  description = "list of cidr blocks to allow all icmp traffic from"
}




# outputs 


output "security_list" {
  value = oci_core_security_list.this
}

# logic


locals {

  security_ids_list = var.existing_sl_ids != null ? var.existing_sl_ids : [oci_core_security_list.this.id]


  # 8 configurations for security rule dynamic blocks
  # egress
  #   - general - all ports for a given protocol
  #   - tcp
  #   - udp
  #   - icmp
  # ingress 
  #   - general - all ports for a given protocol
  #   - tcp
  #   - udp
  #   - icmp

  general_egress_security_rules = merge (
    var.all_outbound_traffic ? { "egress_traffic" = {
      protocol    = "all"
      destination = var.egress_traffic_location
      description = "allow all types of outbound traffic anywhere"
    } } : {},
    {for destination in var.tcp_all_ports_egress_cidrs : destination => {
      protocol = "6"
      destination = destination
      description = "statefull tcp egress traffic to destination"
    }},
    


  )


  general_ingress_security_rules = merge (

  )

}

# resource or mixed module blocks



resource "oci_core_security_list" "this" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn

  display_name = "${local.prefix}SL"


# Egress Rules

  dynamic "egress_security_rules" {
    for_each = local.general_egress_security_rules
    content {
      protocol    = egress_security_rules.value.protocol
      destination = egress_security_rules.value.destination
      description = egress_security_rules.value.description
    }
  }

  
  dynamic "egress_security_rules" {
    //allow custom tcp traffic to specific ports from any port in a specific cidr range
    for_each = var.custom_tcp_egress_rules
    content {
      protocol = "6"
      destination   = egress_security_rules.value.dest_cidr
      tcp_options {
          min = egress_security_rules.value.min
          max = egress_security_rules.value.max
      }
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.icmp_egress_service ? { "create" = true } : {}
    content {
      protocol    = "1"
      destination_type = "SERVICE_CIDR_BLOCK"
      destination = local.service_cidr
      description = "allow all outbound icmp traffic to oracle services network"
    }
  }
  
  dynamic "egress_security_rules" {
    for_each = toset(var.icmp_egress_cidrs)
    content {
      protocol    = "1"
      destination = egress_security_rules.value
      description = "allow all outbound icmp traffic to given cidr"
    }
  }

  dynamic "egress_security_rules" {
    //allow traffic to the Oracle Services Network via SGW
    for_each = var.service_gateway && local.internet_access != "full" ? { "create" = true } : {}
    content {
      protocol = "6"
      destination_type = "SERVICE_CIDR_BLOCK"
      destination   = local.service_cidr
    }
  }

  dynamic "egress_security_rules" {
    //allow custom udp traffic to specific ports from any port in a specific cidr range
    for_each = var.custom_udp_egress_rules
    content {
      protocol = "17"
      destination   = egress_security_rules.value.dest_cidr
      udp_options {
          min = egress_security_rules.value.min
          max = egress_security_rules.value.max
      }
    }
  }



# Ingress Rules

  dynamic "ingress_security_rules" {
    for_each = var.ssh_cidr != null ? { "create" = true } : {}
    content {
      protocol = "6"
      source   = var.ssh_cidr
      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = var.standard_icmp ? { "create" = true } : {}
    content {
      // allow ICMP for all type 3 code 4
      protocol = "1"
      source   = "0.0.0.0/0"

      icmp_options {
        type = "3"
        code = "4"
      }
    }
  }

  dynamic "ingress_security_rules" {
    //allow type 3 ICMP from all VCN CIDRs
    for_each = var.standard_icmp ? toset(local.cidr_blocks) : toset([])
    content {
      protocol = "1"
      source   = ingress_security_rules.value # might be more readable to use an iterator
      icmp_options {
        type = "3"
        code = null #no code reverts to -1
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = toset(var.icmp_ingress_cidrs)
    content {
      protocol    = "1"
      source = ingress_security_rules.value
      description = "allow all inbound icmp traffic from given cidr"
    }
  }

dynamic "ingress_security_rules" {
    //allow traffic to the Oracle Services Network via SGW
    for_each = var.service_gateway && local.internet_access != "full" ? { "create" = true } : {}
    content {
      protocol = "6"
      source_type = "SERVICE_CIDR_BLOCK"
      source   = local.service_cidr
    }
  }


  dynamic "ingress_security_rules" {
    //allow custom tcp traffic to specific ports from any port in a specific cidr range
    for_each = var.custom_tcp_ingress_rules
    content {
      protocol = "6"
      source   = ingress_security_rules.value.source_cidr

      tcp_options { # TODO: should we add explicit destination port range object
          min = ingress_security_rules.value.min
          max = ingress_security_rules.value.max
      }
    }
  }
  dynamic "ingress_security_rules" {
    //allows tcp traffic to all ports
    for_each = toset(var.tcp_all_ports_ingress_cidrs)
    content {
      protocol = "6"
      source = ingress_security_rules.value
    }
  }

  dynamic "ingress_security_rules" {
    // allows udp traffic to specific ports from any port in a specific cidr range
    for_each = var.custom_udp_ingress_rules
    content{
      protocol = "17"
      source = ingress_security_rules.value.source_cidr 

      udp_options {
        min = ingress_security_rules.value.min 
        max = ingress_security_rules.value.max 
      }
    }
  }

}
