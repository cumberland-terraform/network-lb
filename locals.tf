locals {
    ## CONDITIONS
    #   Configuration object containing boolean calculations that correspond
    #       to different deployment configurations.
    conditions                          = {
        provision_log_bucket            = var.lb.connection_logs.enabled || var.lb.access_logs.enabled
        provision_key                   = var.lb.kms_key == null

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

    kms_key                             = local.conditions.provision_key ? (
                                            module.kms[0].key
                                        ) : !var.lb.kms_key.aws_managed ? ( 
                                            var.lb.kms_key
                                        ): null
                                        
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

    # NOTE: have to override log bucket name, because the access policy has to be defined at the level
    #       of this module. Access policy needs to know the ARN of the bucket, so have to force the name
    #       at this level, rather than letting it get set by S3 module, in order to prevent an infinite
    #       cycle.
    bucket_name                         = lower(join("-",[
                                            "s3",
                                            module.platform.prefixes.network.lb.name,
                                            var.lb.suffix,
                                            "logs"
                                        ]))
    log_bucket                          = {
        name_override                   = local.bucket_name
        purpose                         = "Log bucket for ${local.lb.name} load balancer"
        kms_key                         = local.kms_key
        versioning                      = false
        policy                          = try(data.aws_iam_policy_document.log_access_policy[0].json, null)
        public_access_block             = false
    }

    platform                            = merge({
        # TODO: LB specific properties
    }, var.platform)

    tags                                = merge({
        # TODO: LB specific tags
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