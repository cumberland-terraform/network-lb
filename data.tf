data "aws_iam_policy_document" "log_access_policy" {
    count                       = local.conditions.provision_log_bucket? 1 : 0


    statement {
        sid                     = "EnableAWSAccount"
        effect                  = "Allow"
        actions                 = [ "s3:*" ]
        resources               = [  
                                    "arn:aws:s3:::${local.bucket_name}",
                                    "arn:aws:s3:::${local.bucket_name}/*",
                                    "arn:aws:s3:::${local.bucket_name}/AWSLogs/${module.platform.aws.account_id}/*",
                                    "arn:aws:s3:::${local.bucket_name}/${var.lb.connection_logs.prefix}/AWSLogs/${module.platform.aws.account_id}/*",
                                    "arn:aws:s3:::${local.bucket_name}/${var.lb.access_logs.prefix}/AWSLogs/${module.platform.aws.account_id}/*"
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

  statement {
        sid                     = "EnableService"
        effect                  = "Allow"
        actions                 = ["s3:*"]
        resources               = [  
                                    "arn:aws:s3:::${local.bucket_name}",
                                    "arn:aws:s3:::${local.bucket_name}/*",
                                    "arn:aws:s3:::${local.bucket_name}/AWSLogs/${module.platform.aws.account_id}/*",
                                    "arn:aws:s3:::${local.bucket_name}/${var.lb.connection_logs.prefix}/AWSLogs/${module.platform.aws.account_id}/*",
                                    "arn:aws:s3:::${local.bucket_name}${var.lb.access_logs.prefix}/AWSLogs/${module.platform.aws.account_id}/*"
                                ]
        
        principals {
            type                = "Service"
            identifiers         = [
                                    "logdelivery.elasticloadbalancing.amazonaws.com",
                                    "delivery.logs.amazonaws.com"
                                ]
        }
  }
}

/**
 {
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::mdt-mdh-splunk-elblogs/AWSLogs/529969433113/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::mdt-mdh-splunk-elblogs"
        }
*/