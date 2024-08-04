locals {
    ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                          = {
        # TODO: conditional calculations go here
    }

    ## LOAD BALANCER DEFAULTS
    #   These are platform defaults and should only be changed when the 
    #       platform itself changes.
    platform_defaults                   = {
        lb                              = {
            enable_deletion_protection  = true
            internal                    = true
        }
        listener                        = {
            ssl_policy                  = "ELBSecurityPolicy-2016-08"
        }
    }
    
    ## CALCULATED PROPERTIES
    #   Properties that change based on deployment configurations
    lb                                  = {
        security_groups                 = concat(
                                            var.lb.security_groups,
                                            [
                                                # TODO: determine if LBs need platform security groups!
                                            ]
                                        )
    }
    platform                            = merge({
        subnet_type                     = "NETWORK ADDRESS TRANSLATION"
    }, var.platform)
    tags                                = merge({
        # TODO: service specific tags go here
    }, module.platform.tags)


}