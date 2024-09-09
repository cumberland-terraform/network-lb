module "platform" {
  source                = "git::ssh://git@source.mdthink.maryland.gov:22/etm/mdt-eter-platform.git?ref=v1.0.13&depth=1"

  platform              = local.platform
  hydration             = {
    vpc_query           = true
    subnets_query       = true
    dmem_sg_query       = false
    rhel_sg_query       = false
    eks_ami_query       = false
  }
}
