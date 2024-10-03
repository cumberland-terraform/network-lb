data "aws_iam_policy_document" "log_access_policy" {
  count                     = local.conditions.provision_log_bucket? 1 : 0


  statement {
    sid                     = "EnableLogStream"
    effect                  = "Allow"
    actions                 = [ "s3:PutObject" ]
    resources               = [  
                                "arn:aws:s3:::${local.bucket_name}",
                                "arn:aws:s3:::${local.bucket_name}/access/AWSLogs/${module.platform.aws.account_id}/*",
                                "arn:aws:s3:::${local.bucket_name}/connection/AWSLogs/${module.platform.aws.account_id}/*"
                            ]

    principals {
      type                  =  "Service"
      identifiers           = [ "logdelivery.elasticloadbalancing.amazonaws.com" ]
    }
  }
}