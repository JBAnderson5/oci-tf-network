# Copyright © 2022, Oracle and/or its affiliates.
# All rights reserved. Licensed under the Universal Permissive License (UPL), Version 1.0 as shown at https://oss.oracle.com/licenses/upl.


# creates a Virtual Cloud Network (vcn) in the supplied compartment
# allows configuration of 3 standard network gateways
# Internet Gateway (igw) allows access to and from the internet
# Nat Gateway (nat) allows traffic originating from the vcn out to the internet
# Service Gateway (sgw) allows access to services in the Oracle Services Network

# option to lockdown default security list and remove default allowrules
# default to one public and one private RT? or one per subnet-type defined with subnets?



# inputs

variable "compartment_id" {
  type = string
}

# vcn
variable "vcn_display_name" {
  type = string
}
variable "cidr_blocks" {
  type = list(string)
  default = ["10.0.0.0/16"]
}

variable "vcn_dns_label" {
  type    = string
  default = null
}

variable "lockdown_defaults" {
  type        = bool
  default     = true
  description = "restricts vcn default security list and route table. recommended configuration for production workloads"
}


variable "create_service_gateway" {
    type = bool 
    default = false
    description = "provides access to services in the Oracle Services Network: https://www.oracle.com/cloud/networking/service-gateway/service-gateway-supported-services/"
}
variable "only_object_storage" {
    type = bool 
    default = false 
    description = "if true, Service gateway will only provides access to object storage. Otherwise it will provide access to all services"
  
}
variable "create_nat_gateway" {
    type = bool
    default = false
}
variable "allow_nat_traffic" {
  type = bool 
  default = true
  description = "useful toggle to temporarily block routing to the NGW regardless of route/security rules"
}
variable "create_internet_gateway" {
    type = bool
    default = false
}
variable "allow_internet_traffic" {
    type = bool 
    default = true
    description = "useful toggle to temporarily block routing to the IGW regardless of route/security rules"
}


# outputs

output "vcn" {
  value = oci_core_vcn.this
  description = "https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn#attributes-reference"
}

output "service_gateway" {
  value = var.create_service_gateway ? oci_core_service_gateway.this[0] : null
  description = "https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_service_gateway#attributes-reference"
}

output "service_cidr" {
  value = var.create_service_gateway ? data.oci_core_services.this[0].services[0] : null
  description = "https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_services#attributes-reference"
}

output "nat_gateway" {
  value = var.create_nat_gateway ? oci_core_nat_gateway.this[0] : null
  description = "https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_nat_gateway#attributes-reference"
}

output "internet_gateway" {
  value = var.create_internet_gateway ? oci_core_internet_gateway.this[0] : null
  description = "https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway#attributes-reference"
}


# locals


locals {
  vcn_dns_label = var.vcn_dns_label != null ? substr (var.vcn_dns_label, 0, 15) : null
}

# resource or mixed module blocks


# vcn
resource "oci_core_vcn" "this" {

  compartment_id = var.compartment_id
  display_name   = var.vcn_display_name

  cidr_blocks = var.cidr_blocks
  dns_label   = local.vcn_dns_label
}


# defaults
resource "oci_core_default_route_table" "this" {
  count                      = var.lockdown_defaults ? 1 : 0
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id

}
resource "oci_core_default_security_list" "this" {
  count                      = var.lockdown_defaults ? 1 : 0
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
}
/*
Not sure what we should do with dns/DHCP resolution
resource "oci_core_default_dhcp_options" "this" {
  count = var.lockdown_defaults ? 1 : 0
  manage_default_resource_id = oci_core_vcn.vcn.default_dhcp_options_id

}
*/


# SGW
data "oci_core_services" "this" {
    count = var.create_service_gateway == true ? 1 : 0

  filter {
    name   = "name"
    values = var.only_object_storage ? ["OCI .* Object Storage"] : ["All .* Services In Oracle Services Network"]
    regex  = true
  }
  
}
resource "oci_core_service_gateway" "this" {
    count = var.create_service_gateway == true ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id = oci_core_vcn.this.id

  services {
    service_id = data.oci_core_services.this[0].services[0].id
  }

}



# NGW

resource "oci_core_nat_gateway" "this" {
    count = var.create_nat_gateway ? 1 : 0

    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.this.id

    block_traffic = !var.allow_nat_traffic
    
}


# IGW


resource "oci_core_internet_gateway" "this" {
    count = var.create_internet_gateway ? 1 : 0

    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.this.id

    enabled = var.allow_internet_traffic

}




terraform {

  required_version = ">1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">7.9.0"
    }
  }
}