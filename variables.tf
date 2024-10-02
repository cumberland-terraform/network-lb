variable "platform" {
  description               = "Platform metadata configuration object. See [Platform Module] (https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-platform/browse) for detailed information about the permitted values for each field."
  type                      = object({
    account                 = string
    acct_env                = string
    agency                  = string
    program                 = string
    app_env                 = string
    availability_zones      = list(string)
    pca                     = string
    app                     = optional(string, null)
    aws_region              = optional(string, "US EAST 1")
    domain                  = optional(string, null)
    subnet_type             = optional(string, "PRIVATE")
  })
}

variable "lb" {
  description               = "Load Balancer configuration object. See [README] (https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-core-compute-lb/browse) for detailed information about the permitted values for each field"
  type                      = object({
    load_balancer_type      = optional(string, "application")
    security_groups         = optional(list(string), [])

    listeners               = optional(list(object({
      port                  = number
      protocol              = string
      certificate_arns      = optional(list(string), [])
      # <PROPERTY: `listeners[i].default_action`>
      default_action        = optional(object({
        type                = optional(string, "forward")
        target_group_index  = optional(number, 0)
        # NOTE: if `type == "redirect"`, then the redirect block will use 
        #       the following properties to configure the redirect action.
        #       These properties default to redirecting to HTTPS. 
        host                = optional(string, "#{host}")
        path                = optional(string, "/#{path}")
        port                = optional(number, 443)
        protocol            = optional(string, "HTTPS")
        status_code         = optional(string, "HTTP_301")
        query               = optional(string, "#{query}")
      }), {
        # <DEFAULT VALUES>
        type                = "forward"
        target_group_index  = 0
        # </DEFAULT VALUES>
      })
      # </PROPERTY: `listeners[i].default_action`>
      # <PROPERTY: `listeners[i].rules`>
      rules                 = optional(list(object({
        type                = optional(string, "forward")
        target_group_index  = optional(number, 0)
        # NOTE: if `type == "redirect"`, then the redirect block will use 
        #       the following properties to configure the redirect action.
        #       These properties default to redirecting to HTTPS. 
        host                = optional(string, "#{host}")
        path                = optional(string, "/#{path}")
        port                = optional(number, 443)
        protocol            = optional(string, "HTTPS")
        status_code         = optional(string, "HTTP_301")
        query               = optional(string, "#{query}")
        # NOTE: conditions are optional!
        # <PROPERTY: `listeners[i].rules.conditions`>
        conditions          = optional(list(object({
          host_header       = optional(object({
            values          = list(string)
          }), null)
          path_pattern      = optional(object({
            values          = list(string)
          }), null)
        })), [{
          # <DEFAULT VALUES: `listeners[i].rules.conditions`>
          path_pattern      = {
            values          = [ "*" ]
          }
          # </DEFAULT VALUES: `listeners[i].rules.conditions`>
        }])
        # </PROPERTY: `listeners[i].rules.conditions`>
      })), [{
        # <DEFAULT VALUES>
        type                = "forward"
        target_group_index  = 0
        conditions          = [{
          path_pattern      = {
            values          = [ "*" ]
          }
        }]
        # </DEFAULT VALUES>
      }])
    })), [])
    # </PROPERTY: `listeners[i].rules`>
    # <PROPERTY: `listeners[i].target_groups`>
    target_groups           = list(object({
      port                  = number
      protocol              = string
      target_ids            = optional(list(string), null)
      target_type           = optional(string, "ip")
      health_check          = optional(object({
        path                = optional(string, "/")
        port                = optional(string, "traffic-port")
        protocol            = optional(string, "HTTP")
        healthy_threshold   = optional(number, 6)
        unhealthy_threshold = optional(number, 2)
        timeout             = optional(number, 3)
        interval            = optional(number, 30)
        matcher             = optional(string, "200-299")
      }), {
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        healthy_threshold   = 6
        unhealthy_threshold = 2
        timeout             = 3
        interval            = 30
        matcher             = "200-299"
      })
    }))
    # <PROPERTY: `listeners[i].target_groups`>
    suffix                  = optional(string, "web")
  })
}