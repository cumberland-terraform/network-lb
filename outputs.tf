output "target_groups" {
    description         = "Target groups associated with the Load Balancer listeners"

    value               = aws_lb_target_group.this
}