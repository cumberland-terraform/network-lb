# Enterprise Terraform 
## Cumberland Cloud Platform
## AWS Network - Load Balancing

This Terraform module provisions load balancers.

**NOTE**: `mdt-eter-core-network-lb` is one of the more complicated modules offered by the Cumberland Cloud. It is recommended to read through the sections below carefully before employing this module.

### Usage

**Application Load Balancer**

An ALB deployment can be achieved with the following configuration,

**providers.tf**

```hcl
provider "aws" {
	alias 					= "tenant"
	region					= "us-east-1"

	assume_role {
		role_arn 			= "arn:aws:iam::<tenant-account>:role/<role-name>"
	}
}
```

**modules.tf**

```
module "lb" {
	source          		                = "github.com/cumberland-terraform/network-lb.git"
	
	platform	                                = {
		client                                  = "<client>"
                environment                             = "<environment>"
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
                security_groups                         = [ "<sg-id>" ]
                target_groups                           = [{
                        port                            = 80
                        protocol                        = "HTTP"
                        target_id                       = "<target-id>"
                }]
    }
}
```

**Network Load Balancer**

TODO: Module does not currently support load balancers of type `network`.

`platform` is a parameter for *all* **Cumberland Cloud Terraform** modules. For more information about the `platform`, in particular the permitted values of the nested fields, see the Platform module documentation for more infromation. The following section goes into more detail regarding the `lb` variable.

### Parameters

Module input are organized through the `lb` variable. The following bullet-pointed list details the hierarchy of this variable and the purpose of each property in its hierarchy. For the most part, these are simply the properties exposed by Terraform, as these values are passed directly to their corresponding resource. If the following explanations are insufficient, refer to the official Terraform documentation for [lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb), [lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener), [lb_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule), [lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) and [lb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment).

- `load_balancer_type`: *Optional*. Type of load balancer to deploy. Defaults to `application`.
- `security_groups`: *Optional*. List of security group IDs to attach to the load balancer. Defaults to an empty list.
- `listeners`: *Optional*. A list of listener objects to associate with the load balancer. Technically optional, as the module can still be used without specifying any listeners, but it is not very useful without them.
        - `port`: *Required*. Port on which the listener listens.
        - `protocol`: *Required*. Protocol on which the listener listens.
        - `certificate_arns`: *Optional*. List of certificate ARNs of the SSL/TLS certificate for the listener. Required if listener is listening on port 443. The first certificate in the list becomes the default SSL certificate. The other certificates are mapped to the listeners through extra certificate associations.
        - `default_action`: *Optional*. Default action listener should apply to incoming requests. Defaults to forwarding to the first target group.
                - `type`: Defaults to `forward`.
                - `target_group_index`: Index of the Target Group to which the rule will apply its action. Defaults to `0`
                - `host`: Only applies if `type == redirect`. Defaults to `#{host}`.
                - `path`: Only applies if `type == redirect`. Defaults to `/#{path}`.
                - `port`: Only applies if `type == redirect`. Defaults to `443`
                - `protocol`: Only applies if `type == redirect`. Defaults to `HTTPS`
                - `status_code`: Only applies if `type == redirect`. Defaults to `HTTP_301`
                - `query`: Only applies if `type == redirect`. Defaults to `#{query}`
        - `rules`: List of rules for the listener to evaluate to determine how to handle incoming requests. The priority is determined by the order of the list. In other words, the first rule in the list is given the highest priority, with each subsequent item in the list given a lower priority than the one that preceded it. 
                - `type`: *Optional*. Defaults to `forward`.
                - `target_group_index`: Index of the Target Group to which the rule will apply its action.
                - `host`: Only applies if `type == redirect`. Defaults to `#{host}`.
                - `path`: Only applies if `type == redirect`. Defaults to `/#{path}`.
                - `port`: Only applies if `type == redirect`. Defaults to `443`
                - `protocol`: Only applies if `type == redirect`. Defaults to `HTTPS`
                - `status_code`: Only applies if `type == redirect`. Defaults to `HTTP_301`
                - `query`: Only applies if `type == redirect`. Defaults to `#{query}`
                - `conditions`: *Optional*. List of condition objects to add apply to the listener rule. Note, by default, a condition with a `path_pattern.values == [ "*" ]` is set, meaning the listener rule will apply to all paths.
                       - `host_header`: Object representing the conditions to apply to the host header on the request being handled by the listener.
                                - `values`: List of hosts for which to filter.
                        - `path_pattern`: Object representing the conditions to apply to the request path on the request being handled by the listener.
- `target_groups`: A list of target groups to provision.
        - `port`: Port on which the target is listening.
        - `protocol`: Protocol on which the target is listening.
        - `target_id`: Target ID of the target group. This could be an IP address, the ARN of a Lambda function, etc. See AWS and Terraform documentation for more information.
        - `target_type`: Type of target. Defaults to `ip`.
        - `health_check`: Object representing the Health Check configuration for the target group.
                - `path`: Path of the healthcheck. Defaults to `/`.
                - `port`: Port of the healthcheck. Defaults to `traffic-port`.
                - `healthy_threshold`: Number of successful health checks required for a health target. Defaults to `6`.
                - `unhealthy_threshold`: Number of failed health checks for an unhealthy target. Defaults to `2`.
                - `timeout`: Length of time before healthcheck times out. Defaults to `3`.
                - `interval`: Length of time between successive healthchecks. Defaults to `30`.
                - `matcher`: Status codes that are considered healthy. Defaults to `200-299`.
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