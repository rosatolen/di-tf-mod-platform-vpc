# ThoughtWorks-DPS/di-tf-mod-platform-vpc

## Abstract

Terraform module for managing the VPC and eventually security groups associated with the use of Kops as a kubernetes
managment pipeline.

## Need

## Recommendation(s)

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
 