platform                                = {
    aws_region                          = "US EAST 1"
    account                             = "ID ENGINEERING"
    acct_env                            = "NON-PRODUCTION 1"
    agency                              = "MARYLAND TOTAL HUMAN-SERVICES INTEGRATED NETWORK"
    program                             = "MDTHINK SHARED PLATFORM"
    app                                 = "KUBERNETES WORKER NODE"
    app_env                             = "NON PRODUCTION"
    domain                              = "ENGINEERING"
    pca                                 = "FE110"
    owner                               = "AWS DevOps Team"
    availability_zones                  = [ "A01", "C01" ]
}

lb                                      = {
    target_groups                       = [
        {
            port                        = 80
            protocol                    = "HTTP"
        }
    ]
}