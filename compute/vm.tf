
# inputs

variable "compartment_id" {
  type        = string
  description = "ocid of the compartment to create resources in."
}

variable "instance_name" {
    type = string
}


variable "instance_ad" {
  description = "Select availability domain where the compute instance will be created."
}
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}
locals {
  ad_id = [for ad in data.oci_identity_availability_domains.this.availability_domains :
    ad.id
    if ad.name == var.instance_ad
  ][0]
}

variable "instance_image" {

}

variable "instance_shape" {

}

variable "subnet_id" {

}

variable "ssh_key_list" {
	
}

# outputs


# logic


# resource or mixed module blocks





resource "oci_core_instance" "this" {
    display_name = var.instance_name

    compartment_id = var.compartment_id

    # Placement
    availability_domain = var.instance_ad
    # Fault Domain
    # Capacity Type
    
    # Security
    # Shielded Instance
    # Confidential Computing


    # Image and Shape
    source_details {
		source_id = var.instance_image
		source_type = "image"
	}
    shape = var.instance_shape

    # Vnic info
    create_vnic_details {
		assign_private_dns_record = "true"
		assign_public_ip = "false"
		#nsg_ids = [nsg ocids]
		subnet_id = var.subnet_id
	}
    # IPV6
    # DNS
    # VCN/Subnet Tags?

    
    ## SSH keys
    metadata = {
		# "user_data" = 
		"ssh_authorized_keys" = var.ssh_key_list
	}

    # Boot Volume
    # custom size and performance
    is_pv_encryption_in_transit_enabled = "true"
    # custom encryption key


    # management
    instance_options { 
		are_legacy_imds_endpoints_disabled = "false" # auth header. Does IMDSv1 vs v2 matter?
	}
    # tagging

    # Availability Configuration
    availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
    # live migration

    # Oracle Cloud Agent
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Oracle Java Management Service"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "OS Management Service Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Management Agent"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Custom Logs Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute RDMA GPU Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Run Command"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute HPC RDMA Auto-Configuration"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute HPC RDMA Authentication"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Block Volume Management"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
		}
	}

}
