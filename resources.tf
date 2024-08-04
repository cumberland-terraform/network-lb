resource "aws_lb" "this" {
    enable_deletion_protection      = local.platform_defaults.lb.enable_deletion_protection
    internal                        = local.platform_defaults.lb.internal
    load_balancer_type              = var.lb.load_balancer_type
    name                            = module.platform.prefixes.compute.load_balancer.name
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
    ssl_policy                      = local.platform_defaults.listener.ssl_policy
    certificate_arn                 = each.value.certificate_arn

    default_action {
        type                        = each.value.default_action.type
        target_group_arn            = each.value.default_action.target_group_arn
    }
}

resource "aws_lb_listener_rule" "this" {
    for_each                        = { for index, lb_rule in local.local.listener_rules:
                                        index => lb_rule }
  
    listener_arn                    = aws_lb_listener.this[
                                        tostring(each.value.listener_index)
                                    ].arn
    priority                        = each.value.rule_index

    action {
        type                        = var.lb.listeners[
                                        each.value.listener_index
                                    ].rules[each.value.rule_index].type
        target_group_arn            = var.lb.listeners[
                                        each.value.listener_index
                                    ].rules[each.value.rule_index].target_group_arn
    }

    # TODO: parameterize this block
    condition {
        host_header {
            values                  = ["*"]
        }
    }
}