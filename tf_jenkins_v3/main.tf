provider "aws" {
  region = "us-east-1"

}

resource "aws_eip" "nat" {
  count = 3

  vpc = true
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc-fargate"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  single_nat_gateway     = false
  one_nat_gateway_per_az = true             # one nat-gateway for az specified in the var.azs
  reuse_nat_ips          = true             # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids    = aws_eip.nat.*.id # <= IPs specified here as input to the module

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}

#Usage with Route53 DNS validation (recommended)

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = "pipline.site"
  zone_id     = "Z006005948DXAA1KI3M4"

  subject_alternative_names = [
    "*.pipline.site",
    "test.pipline.site"
    
  ]

  wait_for_validation = false

  tags = {
    Name = "my-domain.com"
  }
}

resource "aws_ssm_parameter" "jenkins-pwd" {
  name  = "jenkins-pwd"
  type  = "SecureString"
  value = "ecuser"
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "tf-serverless-jenkins-v3-bucket"

  versioning = {
    enabled = true
  }

}


module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name     = "tf-serverless-jenkins-v3-lock-table"
  hash_key = "LockID"
  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}