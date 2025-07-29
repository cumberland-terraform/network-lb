module "platform" {
  source                = "github.com/cumberland-terraform/platform.git"

  platform              = local.platform
  hydration             = {
    vpc_query           = true
    subnets_query       = true
    dmem_sg_query       = false
    rhel_sg_query       = false
    eks_ami_query       = false
  }
}

module "log_bucket" {
  count                 = local.conditions.provision_log_bucket ? 1 : 0

  source                = "github.com/cumberland-terraform/storage-s3.git"

  platform              = local.platform
  s3                    = local.log_bucket
}