data "aws_iam_policy_document" "log_access_policy" {
  count                     = local.conditions.provision_log_bucket? 1 : 0


  statement {
    sid                     = "EnableLogStream"
    effect                  = "Allow"
    actions                 = [ "s3:*" ]
    resources               = [  
                                "arn:aws:s3:::${local.bucket_name}",
                                "arn:aws:s3:::${local.bucket_name}/*",
                                "arn:aws:s3:::${local.bucket_name}/access/AWSLogs/${module.platform.aws.account_id}/*",
                                "arn:aws:s3:::${local.bucket_name}/connection/AWSLogs/${module.platform.aws.account_id}/*"
                            ]

    # The account ID in this principal is an AWS managed account, not an MDTHINK account. 
    #   See docs for more information: 
    #       https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
    # 
    #   Account ID must be changed based on region. For now, East Region ID is hardcoded.
    #   Future enhancement could be pulling these account numbers through the platform module.
    #   
    #   US Regional Accounts given below,
    #
    #       US East (N. Virginia) – 127311923021
    #       US East (Ohio) – 033677994240
    #       US West (N. California) – 027434742980
    #       US West (Oregon) – 797873946194
    principals {
        type                = "AWS"
        identifiers         = [ "arn:aws:iam::127311923021:root" ]
    }
  }
}