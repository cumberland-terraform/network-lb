locals {
    ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                          = {
        provision_connection_log_bucket = var.connection_logs.enabled || var.access_logs.enabled
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
    prefix                              = var.lb.load_balancer_type == "application" ? "ALB" : "NLB"

    lb                                  = {
        name                            = upper(join("-",[
                                            local.prefix,
                                            module.platform.prefixes.network.lb.name,
                                            var.lb.suffix
                                        ]))
        security_groups                 = concat(
                                            var.lb.security_groups,
                                            [
                                                # TODO: determine if LBs need platform security groups!
                                            ]
                                        )
    }

    log_bucket                          = {
        suffix                              =  module.platform.prefixes.network.lb.name
        purpose                             = "Log bucket for ${local.lb.name} load balancer"
    }

    platform                            = merge({

    }, var.platform)
    tags                                = merge({

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

    ## CERTIFICATE MAPPING
    listener_certificates               = flatten([
        for l_index, listener in var.lb.listeners: [
            for c_index, certificate_arn in listener.certificate_arns: {
                listener_index          = l_index
                certificate_arn         = certificate_arn
            }
        ]
    ])
    
    # NOTE: The `target_group.target_id` attribute has to be made optional and then filtered
    #           on null values for this reason: when deploying ECS services, the attachment
    #           of containers to target groups is handled on the AWS side. However, the target
    #           must exist. Therefore, this module has to create the target group for the ECS module
    #           but NOT the target group attachment. When using ECS, the target group being passed in
    #           through `lb.target_groups` should NOT contain `target_id` for this reason. In other words,
    #           the target group attachment will not be provisioned unless the `target_id` for that target 
    #           group is specified.
    provisioned_attachments             = { for index, target_group in var.lb.target_groups: 
                                            index => target_group 
                                            if target_group.target_ids != null  }

    ## ATTACHMENTS
    target_group_attachments            = flatten([
        for tgrp_index, target_group in local.provisioned_attachments: [
            for t_id in target_group.target_ids: {
                port                    = target_group.port
                target_group_index      = tgrp_index
                target_id               = t_id
            }
        ]
    ])
}