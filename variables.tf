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
      default_action        = object({
        type                = optional(string, "forward")
        target_group_arn    = string
      })
      rules                 = optional(list(object({
        type                = optional(string, "forward")
        target_group_arn    = string
      })), [])
      certificate_arn       = optional(string, null)
    })), [])    
  })
}