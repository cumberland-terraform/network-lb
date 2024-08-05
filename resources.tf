resource "aws_lb" "this" {
    lifecycle {
      ignore_changes                = [ tags  ]
    }

    enable_deletion_protection      = local.platform_defaults.lb.enable_deletion_protection
    internal                        = local.platform_defaults.lb.internal
    load_balancer_type              = var.lb.load_balancer_type
    name                            = module.platform.prefixes.compute.lb.name
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
        target_group_arn            = aws_lb_target_group.this[each.value.default_action.target_group_index].arn
    }
}

resource "aws_lb_target_group" "this" {
    for_each                        = { for index, target_group in var.lb.target_groups: 
                                        index => target_group }

    lifecycle {
      ignore_changes                = [ tags ]
    }
    
    name                            = module.platform.prefixes.compute.lb.target_group
    target_type                     = each.value.target_type
    port                            = each.value.port
    protocol                        = each.value.protocol
    vpc_id                          = module.platform.network.vpc.id
    tags                            = local.tags
}

resource "aws_lb_listener_rule" "this" {
    for_each                        = { for index, mapping in local.listener_rule_mappings:
                                        index => mapping }
  
    listener_arn                    = aws_lb_listener.this[tostring(each.value.l_i)].arn
    # NOTE: mapping priority to position of rule in list, but index starts at 0, so add 1!
    priority                        = each.value.r_i + 1 

    action {
        type                        = var.lb.listeners[each.value.l_i].rules[each.value.r_i].type
        target_group_arn            = aws_lb_target_group.this[var.lb.listeners[each.value.l_i].rules[each.value.r_i].target_group_index].arn
    }

    # TODO: parameterize this block
    condition {
        host_header {
            values                  = ["*"]
        }
    }
}