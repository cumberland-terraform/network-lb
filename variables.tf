variable "platform" {
  description               = "Platform metadata configuration object. See [Platform Module] (https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-platform/browse) for detailed information about the permitted values for each field."
  type                      = object({
    aws_region              = string 
    account                 = string
    acct_env                = string
    agency                  = string
    program                 = string
    app                     = string
    app_env                 = string
    domain                  = string
    availability_zones      = list(string)
    pca                     = string
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
      certificate_arn       = optional(string, null)
      # <PROPERTY: `listeners[i].default_action`>
      default_action        = optional(object({
        type                = optional(string, "forward")
        target_group_index  = optional(number, 0)
        # NOTE: if `type == "redirect"`, then the redirect block will use 
        #       the following properties to configure the redirect action.
        #       These properties default to redirecting to HTTPS. 
        port                = optional(number, 443)
        protocol            = optional(string, "HTTPS")
        status_code         = optional(string, "HTTP_301")
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
        port                = optional(number, 443)
        protocol            = optional(string, "HTTPS")
        status_code         = optional(string, "HTTP_301")
      })), [{
        # <DEFAULT VALUES>
        type                = "forward"
        target_group_index  = 0
        # </DEFAULT VALUES>
      }])
    })), [])
    # </PROPERTY: `listeners[i].rules`>
    # <PROPERTY: `listeners[i].target_groups`>
    target_groups           = list(object({
      port                  = number
      protocol              = string
      target_id             = optional(string, null)
      target_type           = optional(string, "ip")
    }))
    # <PROPERTY: `listeners[i].target_groups`>
    suffix                  = optional(string, "web")
  })
}