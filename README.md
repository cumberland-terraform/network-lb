# Enterprise Terraform 
## AWS Core Compute Elastic Load Balancer
### Overview

TODO

**NOTE**: The Load Balancer is one of the more complicated modules supported by the MDTHINK DevOps team. It is recommended to read through the sections below carefully before employing this module.

### Usage

**Application Load Balancer**

An ALB deployment can be achieved with the following configuration,

```
module "lb" {
	source          		= "ssh://git@source.mdthink.maryland.gov:22/etm/mdt-eter-aws-core-compute-lb.git"
	
	platform	                                = {
		aws_region                              = "<region-name>"
                account                                 = "<account-name>"
                acct_env                                = "<account-environment>"
                agency                                  = "<agency>"
                program                                 = "<program>"
                app                                     = "<>"
                app_env                                 = "<application-environment>"
                domain                                  = "<active-directory-domain>"
                pca                                     = "<pca-code>"
                availability_zones                      = [ "<availability-zones>" ]
	}

	lb			                        = {
                listeners                               = [{
                        port                            = 80
                        protocol                        = "HTTP"
                        default_action                  = {
                                type                    = "forward"
                                target_group_index      = 0
                        }
                        rules                           = [{
                                action                  = "forward"
                                target_group_index      = 0
                        }]
                }]
                security_groups                         = [ "sg-id" ]
                target_groups                           = [{
                        port                            = 80
                        protocol                        = "HTTP"
                        target_id                       = "<target-id>"
                }]
    }
}
```

**Network Load Balancer**

TODO

`platform` is a parameter for *all* **MDThink Enterprise Terraform** modules. For more information about the `platform`, in particular the permitted values of the nested fields, see the [mdt-eter-platform documentation](https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-platform/browse). The following section goes into more detail regarding the `lb` variable.

### Parameters

Module input are organized through the `lb` variable. The following bullet-pointed list details the hierarchy of this variable and the purpose of each property in its hierarchy. For the most part, these are simply the properties exposed by Terraform, as these values are passed directly to their corresponding resource. If the following explanations are insufficient, refer to the official Terraform documentation for [lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb), [lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener), [lb_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule), [lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) and [lb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment).

- `load_balancer_type`: *Optional*. Type of load balancer to deploy. Defaults to `application`.
- `security_groups`: *Optional*. List of security group IDs into which the load balancer deploys. Defaults to an empty list.
- `listeners`: *Optional*. A list of listener objects to associate with the load balancer. Technically optional, as the module can still be used without specifying any listeners, but it is not very useful in this case.
        - `port`: *Required*. Port on which the listener listens.
        - `protocol`: *Required*. Protocol on which the listener listens.
        - `certificate_arn`: *Optional*. Certificate ARN of the SSL/TLS certificate for the listener. Required if listener is listening on port 443. 
        - `default_action`: *Optional*. Default action listener should apply to incoming requests. Defaults to forwarding to the first target group.
                - `type`: *Optional*. Defaults to `forward`.
                - `target_group_index`: Index of the Target Group to which the rule will apply its action.
        - `rules`: List of rules for the listener to evaluate to determine how to handle incoming requests. The priority is determined by the order of the list. In other words, the first rule in the list is given the highest priority, with each subsequent item in the list given a lower priority than the one that preceded it. 
                - `type`: *Optional*. Defaults to `forward`.
                - `target_group_index`: Index of the Target Group to which the rule will apply its action.
- `target_groups`: A list of target groups to provision.
        - `port`: Port on which the target is listening.
        - `protocol`: Protocol on which the target is listening.
        - `target_id`: Target ID of the target group. This could be an IP address, the ARN of a Lambda function, etc. See AWS and Terraform documentation for more information.
        - `target_type`: Type of target. See AWS and Terraform documentation for more information.
        - `group_index`: The group to associate this target with. Defaults to `0`. This property should map to the `listeners.\*.rules.\*.target_group_index`.
- `suffix`: *Optional*. Suffix to append to all resource names. Defaults to `web`.
        
## Notes

### Listener Target Group Attachments

The `var.lb.listeners[*].rules[*].target_group_index` parameter is the index of the target group defined in the `var.lb.target_groups` parameter. For example, the following values of the `lb` variable,

```
lb			                        = {
        listeners                               = [{
                port                            = 80
                protocol                        = "HTTP"
                default_action                  = {
                        type                    = "forward"
                        target_group_index      = 0
                }
                rules                           = [{
                        action                  = "forward"
                        target_group_index      = 0
                }, {
                        action                  = "forward"
                        target_group_index      = 1
                }]
        }]
        security_groups                         = [ "sg-id" ]
        target_groups                           = [{
                port                            = 80
                protocol                        = "HTTP"
                target_id                       = "<target-id-1>"
        }, {
                port                            = 81
                protocol                        = "HTTP"
                target_id                       = "<target-id-2>"
        }]
}
```

will create a load balancer with a listener that has a rule to forward to `<target-id-1>` (`target_group_index = 0` because it is the first target group defined in `var.lb.target_groups`), and then another rule to forward to `<target-id-2>` (`target_group_index = 1` because it is the second target group defined in `var.lb.target_groups`). The priority of the rules is determined by their order in the rules list. In other words, the `<target-id-1>` rule is evaluated before the `<target-id-2>` rule. 

### Accomodations for ECS Target Group Attachment

The `var.lb.target_groups.*.target_id` attribute has to be made optional and allowed to default to `null`.Then the null values must be filtered out when creating the attachment for a load balancer target group. This is done to accomodate ECS deployments through the `mdt-eter-core-compute-ecs-svc` module. When deploying ECS services, the attachment of containers to target groups is handled on the AWS side. However, the target group must exist and be passed into the `mdt-eter-core-compute-ecs-svc` module. Therefore, this module has to create the target group for the ECS module, but **not** the the target group attachment. When using ECS, the target group being passed in through `var.lb.target_groups.*` should NOT contain `target_id` property for this reason. In other words, the target group attachment will not be provisioned unless the `target_id` for that target group is specified.

### Complexity

This is one of the more complex modules maintained by MDTHINK. Please think twice before altering it.

## Contributing

Checkout master and pull the latest commits,

```bash
git checkout master
git pull
```

Append ``feature/`` to all new branches.

```bash
git checkout -b feature/newthing
```

After committing your changes, push them to your feature branch and then merge them into the `test` branch. 

```bash
git checkout test && git merge feature/newthing
```

Once the changes are in the `test` branch, the Jenkins job containing the unit tests, linting and security scans can be run. Once the tests are passing, tag the latest commit,

```bash
git tag v1.0.1
```

Once the commit has been tagged, a PR can be made from the `test` branch into the `master` branch.

### Pull Request Checklist

Ensure each item on the following checklist is complete before updating any tenant deployments with a new version of the ``mdt-eter-core-compute-lb`` module,

- [] Update Changelog
- [] Merge into `test` branch
- [] Ensure tests are passing in Jenkins
- [] Increment `git tag` version
- [] Open PR from `test` into `master` branch
- [] Get approval from lead
- [] Merge into `master`
- [] Publish latest version on Confluence

### TODOS

1. Currently, the `mdt-eter-core-compute-lb` module has only been tested for load balancers of type `application`. `network` load balancers should also be supported by this module, but they need to be tested. This will require reworking how the listener rules are generated!