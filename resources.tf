resource "aws_lb" "this" {
    lifecycle {
      ignore_changes                = [ tags  ]
    }

    enable_deletion_protection      = local.platform_defaults.lb.enable_deletion_protection
    internal                        = local.platform_defaults.lb.internal
    load_balancer_type              = var.lb.load_balancer_type
    name                            = local.lb.name
    security_groups                 = local.lb.security_groups
    subnets                         = module.platform.network.subnets.ids
    tags                            = local.tags
}

resource "aws_lb_listener" "this" {
    for_each                        = { for index, lb in var.lb.listeners: 
                                        index => lb }

    load_balancer_arn               = aws_lb.this.arn
    port                            = each.value.port
    protocol                        = each.value.protocol
    ssl_policy                      = each.value.certificate_arn != null ? (
                                        local.platform_defaults.listener.ssl_policy
                                    ) : null
    certificate_arn                 = each.value.certificate_arn

    default_action {
        type                        = each.value.default_action.type
        target_group_arn            = each.value.default_action.type != "redirect" ? (
                                        aws_lb_target_group.this[
                                            tostring(each.value.default_action.target_group_index)
                                        ].arn ) : null

        dynamic "redirect" {
            # NOTE: dynamic block requires an iterable, so iterate over dummy index if rule type is `redirect`
            #       in order to generate a redirect rule block.
            for_each                = each.value.default_action.type == "redirect" ? (
                                        toset([1]) 
                                    ) : toset([])

            content {
                host                = each.value.default_action.host
                path                = each.value.default_action.path
                port                = each.value.default_action.port
                protocol            = each.value.default_action.protocol
                status_code         = each.value.default_action.status_code
                query               = each.value.default_action.query
            }
        }
    }
}

resource "aws_lb_target_group" "this" {
    for_each                        = { for index, target_group in var.lb.target_groups: 
                                        index => target_group }

    lifecycle {
        ignore_changes              = [ tags ]
    }
    
    name                            = upper(join("-", [
                                        module.platform.prefixes.network.lb.target_group,
                                        var.lb.suffix,
                                        "0${each.key}"
                                    ]))
    target_type                     = each.value.target_type
    port                            = each.value.port
    protocol                        = each.value.protocol
    vpc_id                          = module.platform.network.vpc.id
    tags                            = local.tags

    health_check {
        path                        = each.value.health_check.path
        port                        = each.value.health_check.port
        healthy_threshold           = each.value.health_check.healthy_threshold
        unhealthy_threshold         = each.value.health_check.unhealthy_threshold
        timeout                     = each.value.health_check.timeout
        interval                    = each.value.health_check.interval
        matcher                     = each.value.health_check.matcher
    }
}

resource "aws_lb_target_group_attachment" "this" {
    depends_on                      = [ aws_lb_target_group.this ]
    for_each                        = { for index, attachment in local.target_group_attachments:
                                        index => attachment }

    target_group_arn                = aws_lb_target_group.this[each.value.target_group_index].arn
    target_id                       = each.value.target_id
    port                            = each.value.port
}

resource "aws_lb_listener_rule" "this" {
    for_each                        = { for index, mapping in local.listener_rule_mappings:
                                        index => mapping }
  
    listener_arn                    = aws_lb_listener.this[tostring(each.value.l_i)].arn
    # NOTE: mapping priority to position of rule in list, but index starts at 0, so add 1!
    priority                        = each.value.r_i + 1 

    action {
        type                        = var.lb.listeners[each.value.l_i].rules[each.value.r_i].type
        target_group_arn            = var.lb.listeners[each.value.l_i].rules[each.value.r_i].type != "redirect" ? (
                                        aws_lb_target_group.this[
                                            var.lb.listeners[each.value.l_i].rules[each.value.r_i].target_group_index
                                        ].arn ) : null

        dynamic "redirect" {
            # NOTE: dynamic block requires an iterable, so iterate over dummy index if rule 
            #       type is `redirect` in order to generate a redirect rule block.
            for_each                = var.lb.listeners[each.value.l_i].rules[each.value.r_i].type == "redirect" ? (
                                        toset([1]) 
                                    ) : toset([])

            content {
                host                = var.lb.listeners[each.value.l_i].rules[each.value.r_i].host
                path                = var.lb.listeners[each.value.l_i].rules[each.value.r_i].path
                port                = var.lb.listeners[each.value.l_i].rules[each.value.r_i].port
                protocol            = var.lb.listeners[each.value.l_i].rules[each.value.r_i].protocol
                status_code         = var.lb.listeners[each.value.l_i].rules[each.value.r_i].status_code
                query               = var.lb.listeners[each.value.l_i].rules[each.value.r_i].query
            }
        }
    }

    dynamic "condition" {
        for_each                = { for index, condition in var.lb.listeners[each.value.l_i].rules[each.value.r_i].conditions:
                                    index => condition }

        content {

            dynamic "host_header" {
                # NOTE: dynamic block requires an iterable, so iterate over dummy index if rule 
                #       type is `redirect` in order to generate a redirect rule block.
                for_each                = condition.value.host_header != null ? (
                                            toset([1]) 
                                        ) : toset([])
                
                content {
                    values              = condition.value.host_header.values
                }
            }

            dynamic "path_pattern" {
                # NOTE: dynamic block requires an iterable, so iterate over dummy index if rule 
                #       type is `redirect` in order to generate a redirect rule block.
                for_each                = condition.value.path_pattern != null ? (
                                            toset([1]) 
                                        ) : toset([])
                
                content {
                    values              = condition.value.path_pattern.values
                }
            }
        }
    }
}