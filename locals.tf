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
            enable_deletion_protection  = false
            internal                    = true
        }
        listener                        = {
            ssl_policy                  = "ELBSecurityPolicy-2016-08"
        }
    }
    
    ## CALCULATED PROPERTIES
    #   Properties that change based on deployment configurations
    lb                                  = {
        name                            = lower(join("-",[
                                            module.platform.prefixes.compute.lb.name,
                                            var.lb.suffix
                                        ]))
        security_groups                 = concat(
                                            var.lb.security_groups,
                                            [
                                                # TODO: determine if LBs need platform security groups!
                                            ]
                                        )
    }
    platform                            = merge({

    }, var.platform)
    tags                                = merge({
        # TODO: service specific tags go here
    }, module.platform.tags)

    ## LISTENER-RULE MAPPING
    # This is a technique for generating a flat list of { listener_index, rule_index } 
    #   objects so the `aws_lb_listener_rule` resources can be generated more
    #   efficiently.
    # See: https://developer.hashicorp.com/terraform/language/functions/flatten
    listener_rule_mappings              = flatten([
        for l_index, listener in var.lb.listeners: [
            for r_index, rule in listener.rules: {
                l_i                     = l_index
                r_i                     = r_index
            } 
        ]
    ])

}