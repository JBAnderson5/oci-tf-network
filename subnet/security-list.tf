


# inputs

variable "existing_sl_ids" {
  type = list(string)
  default = null 
  description = "a list of existing sl ids. If provided, a security list will not be made"
}



variable "sl_rules" {
  description = "a map of security rule objects. required value is the destination/source cidr. direction: egress(default), ingress. protocols: tcp(default), udp, icmp. Recommended to specify a single port (min) or a range (min,max). Default allows access on all ports. icmp uses min for type and max(optional) for code"

  type = map(object({
    direction = optional (string) # egress(default) or ingress 
    stateless = optional(bool)
    dest_source_cidr = string # cidr block, special values: anywhere, service, vcn(1st cidr block)
    protocol = optional(string) # tcp(default), udp, or icmp 
    min = optional(number), # if not provided, provides traffic to every port. icmp type
    max = optional(number), # if not provided, provides traffic to just the min port specified. icmp code
    # source_min = optional(number) # not supported yet
    # source_max = optional(number) # not supported yet
    description = optional(string)
  }))
  default = {
      "egress_traffic" = {
      dest_source_cidr = "anywhere"
  },
  "service_gateway_traffic" = {
    dest_source_cidr = "service"
  },
  "ssh_traffic" = {
    dest_source_cidr = "vcn"
    min = 22
  },
    "icmp_service_traffic" = {
    protocol = "icmp"
    dest_source_cidr = "service"

  },
  "icmp_vcn" = {
    direction = "ingress"
    protocol = "icmp"
    dest_source_cidr = "vcn"
    min = 3
  }
  "icmp_anywhere" = {
    direction = "ingress"
    protocol = "icmp"
    dest_source_cidr = "anywhere"
    min = 3
    max = 4
  },


}

}


# outputs 


output "security_list" {
  value = var.existing_sl_ids != null ? null : oci_core_security_list.this[0]
}

# logic


locals {

  security_ids_list = var.existing_sl_ids != null ? var.existing_sl_ids : [oci_core_security_list.this[0].id]

}

# resource or mixed module blocks



resource "oci_core_security_list" "this" {
  count = var.existing_sl_ids == null ? 1 : 0
  #Required
  compartment_id = var.compartment_id
  vcn_id         = local.vcn.id

  display_name = "${local.prefix}SL"


# Egress Rules


dynamic "egress_security_rules" {
    for_each = {for key,value in var.sl_rules: key => value if value.direction == "egress" || value.direction == null}
    iterator = rule 
    content {
      protocol    = rule.value.protocol == "tcp" || rule.value.protocol == null ? "6" : rule.value.protocol == "udp" ? "17" : "1"
      destination = rule.value.dest_source_cidr == "service" ? local.service_cidr : rule.value.dest_source_cidr == "anywhere" ? var.anywhere : rule.value.dest_source_cidr == "vcn" ? local.vcn_cidrs[0] : rule.value.dest_source_cidr
      destination_type = rule.value.dest_source_cidr == "service" ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
      stateless = rule.value.stateless
      description = rule.value.description

      dynamic "tcp_options" {
        for_each = rule.value.protocol == "tcp" || rule.value.protocol == null ? rule.value.min != null ? rule : {} : {}
        iterator = rule
        content {
        min = rule.value.min 
        max = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }

      dynamic "udp_options" {
        for_each = rule.value.protocol == "udp" && rule.value.min != null ? rule : {}
        iterator = rule
        content {
        min = rule.value.min 
        max = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }

      dynamic "icmp_options" {
        for_each = rule.value.protocol == "icmp" && rule.value.min != null ? rule : {}
        iterator = rule
        content {
        code = rule.value.min 
        type = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }

    }
  }




# Ingress Rules

  # open ports
 dynamic "ingress_security_rules" {
    for_each = {for key,value in var.sl_rules: key => value if value.direction == "ingress"}
    iterator = rule 
    content {
      protocol    = rule.value.protocol == "tcp" || rule.value.protocol == null  ? "6" : rule.value.protocol == "udp" ? "17" : "1"
      source = rule.value.dest_source_cidr == "service" ? local.service_cidr : rule.value.dest_source_cidr == "anywhere" ? var.anywhere : rule.value.dest_source_cidr == "vcn" ? local.vcn_cidrs[0] : rule.value.dest_source_cidr
      source_type = rule.value.dest_source_cidr == "service" ? "SERVICE_CIDR_BLOCK" : "CIDR_BLOCK"
      stateless = rule.value.stateless
      description = rule.value.description

      dynamic "tcp_options" {
        for_each = rule.value.protocol == "tcp" || rule.value.protocol == null ? rule.value.min != null ? rule : {} : {}
        iterator = rule
        content {
        min = rule.value.min 
        max = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }

      dynamic "udp_options" {
        for_each = rule.value.protocol == "udp" && rule.value.min != null ? rule : {}
        iterator = rule
        content {
        min = rule.value.min 
        max = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }

      dynamic "icmp_options" {
        for_each = rule.value.protocol == "icmp" && rule.value.min != null ? rule : {}
        iterator = rule
        content {
        code = rule.value.min 
        type = rule.value.max != null ? rule.value.max : rule.value.min
        }
      }
    }
  }

}
