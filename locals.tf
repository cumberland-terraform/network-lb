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

    ## LISTENER-RULE MAPPING
    # This is a technique for generating a flat list of { role, policy } objects
    #   so the ``aws_iam_role_policy_attachment`` resources can be generated more
    #   efficiently. This local should not be altered. If you need to add a role
    #   to a baseline deployment, do so through the `service_roles` map above.
    #   Likewise with any policies that need attached to service roles.
    # See: https://developer.hashicorp.com/terraform/language/functions/flatten
    listener_rules                      = flatten([
        for l_index, listener in var.lb.listeners: [
            for r_index, rule in listener.rules: {
                listener_index          = l_index
                rule_index              = r_index
            } 
        ]
    ])

}