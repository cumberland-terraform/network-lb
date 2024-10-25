module "platform" {
  source                = "git::ssh://git@source.mdthink.maryland.gov:22/etm/mdt-eter-platform.git?ref=v1.0.19&depth=1"

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

  source                = "git::ssh://mdt.global@source.mdthink.maryland.gov:22/etm/mdt-eter-core-storage-s3.git?depth=1"

  platform              = local.platform
  s3                    = local.log_bucket
}