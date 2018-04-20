# ThoughtWorks-DPS/di-tf-mod-platform-vpc

## Abstract

Terraform module for managing the VPC and eventually security groups associated with the use of Kops as a kubernetes
managment pipeline.

## Need

There are several reasons for needing to self manage the underlying vpc structure in a kops managed kubernetes cluster,
such as routing tables for vpn or direct connections. This module manages a single or multi-az structure designed to support
kops managed clusters with a likely default configuration and easy customization.

## Recommendation(s)

Default vpc structure

vpc                              | us-east-1b   | us-east-1c   | us-east-1d   | us-east-1e   | mask          | addr
---------------------------------|--------------|--------------|--------------|--------------|---------------|----------
vpc-example                      |              |              |              |              | /19           | 8190
subnet-vpc-example-public-(az)   | 10.x.0.0/22  | 10.x.4.0/22  | 10.x.8.0/22  | 10.x.12.0/22 | 255.255.252.0 | 1022
subnet-vpc-example-nat-(az)      | 10.x.16.0/23 | 10.x.18.0/23 | 10.x.20.0/23 | 10.x.22.0/23 | 255.255.254.0 | 510
subnet-vpc-example-internal-(az) | 10.x.24.0/22 | 10.x.26.0/22 | 10.x.28.0/22 | 10.x.30.0/22 | 255.255.252.0 | 1022


### usage

#### Module Input Variables

required  
- `k8_cluster_name` - name of the kubernetes cluster kops will manage on this vpc  
- `name` - vpc name  
- `azs` - list of AZs in which to distribute subnets  

optional    
- `cidr_reservation_start` - starting class b offset, default = 0  
- `cidr_reservation_size` - size of the vpc, default = 19 ('/19' or 8192 addresses)  
- `cidr_reservation_offset` - starting class c offset, default = 0  
- `nat_subnet_size` - size of the nat subnet (private network with natgw outbound route), default = 22 (1024 addresses)  
- `nat_subnet_start` - starting class c offsets for up to 4 availability zones, default = ["0","4","8","12"]  
- `public_subnet_size` - size of the public subnet (public network with igw outbound route), default = 23 (512 addresses)  
- `public_subnet_start` - starting class c offsets for up to 4 availability zones, default = ["16","18","20","22"]  
- `internal_subnet_size` - size of the internal subnet (private network with no outbound route, )default = 22 (512 addresses)  
- `internal_subnet_start` - starting class c offsets for up to 4 availability zones, default = ["24","26","28","30"]  
- `enable_dns_hostnames` - should be false if you do not want to use private DNS within the VPC, default = true  
- `enable_dns_support` - should be false if you do not want to use private DNS within the VPC, default = true  
- `enable_nat_gateway` - should be true if you want to provision NAT Gateways for each of your private networks, default = false  
- `map_public_ip_on_launch` - should be true if you want to auto-assign public IP on launch, default = false  
- `private_propagating_vgws` - list of VGWs the private route table should propagate  
- `public_propagating_vgws` - list of VGWs the public route table should propagate  
- `tags` - dictionary of tags that will be added to resources created by the module  


#### typical use in di-baseline-aws-resources pipeline

```hcl
module "vpc" {
  source = "github.com/ThoughtWorks-DPS/di-tf-mod-platform-vpc"

  name = "${var.cluster_vpc_name}"
  k8_cluster_name = "${var.k8_cluster_name}"
  cidr_reservation_start = "${var.cluster_cidr_reservation_start}"
  azs = "${var.cluster_azs}"

  enable_nat_gateway = "${var.cluster_enable_nat_gateway}"

  tags {
    "di" = "true"
    "terraform" = "true"
  }
}
```

#### Outputs

 - `vpc_cidr` - vpc cidr  
 - `azs` list of azs  
 - `public_subnet_cidrs` - list of public subnet cidrs  
 - `public_subnet_ids`  - list of public subnet ids  
 - `nat_subnet_cidrs` - list of nat subnet cidrs  
 - `nat_subnet_ids` - list of nat subnet ids  
 - `internal_subnet_cidrs` - list of internal subnet cidrs  
 - `internal_subnet_ids` - list of internal subnet ids  
 - `igw_id` - internet gateway id  
 - `nat_eips_public_ips` - list of nat subnet nat gateway public eips  
 - `natgw_ids` - list of nat subnet nat gateway ids  
 - `natgw_objects` - map of nat subnet nat gateway ids  
 - `public_route_table_ids` - list of public subnet route table ids  
 - `nat_route_table_ids` - list of nat subnet route table ids  
 - `internal_route_table_ids` - list of internal subnet route table ids  

_maps for use in json output for kops template rendering in di-baseline-platform-aws-k8 pipeline_   
 - `vpc` - map of vpc id and cidr  
 - `nat_subnet_objects` - map of nat subnet, id, az, cidr  
 - `public_subnet_objects` - map of nat subnet, id, az, cidr  
 - `internal_subnet_objects` - map of nat subnet, id, az, cidr  
 - `k8_cluster_name` - map of cluster name  
 