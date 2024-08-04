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
        # TODO: platform defaults go here
    }
    
    ## CALCULATED PROPERTIES
    #   Properties that change based on deployment configurations
    tags                                = merge({
        # TODO: service specific tags go here
    }, module.platform.tags)


}