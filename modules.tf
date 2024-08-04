module "platform" {
  source                = "git::ssh://git@source.mdthink.maryland.gov:22/etm/mdt-eter-platform.git"

  platform              = merge({
    # SERVICE SPECIFIC PLATFORM ARGS GO HERE, IF ANY.
  }, var.platform)
}
