# Enterprise Terraform 
## AWS Core Compute Elastic Load Balancer
### Overview

This is the Terraform Module for MDTHINK Platform compliant load balancers.

**NOTE**: `mdt-eter-core-network-lb` is one of the more complicated modules supported by the MDTHINK DevOps team. It is recommended to read through the sections below carefully before employing this module.

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

TODO: Module does not currently support load balancers of type `network`.

`platform` is a parameter for *all* **MDThink Enterprise Terraform** modules. For more information about the `platform`, in particular the permitted values of the nested fields, see the [mdt-eter-platform documentation](https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-platform/browse). The following section goes into more detail regarding the `lb` variable.

### Parameters

Module input are organized through the `lb` variable. The following bullet-pointed list details the hierarchy of this variable and the purpose of each property in its hierarchy. For the most part, these are simply the properties exposed by Terraform, as these values are passed directly to their corresponding resource. If the following explanations are insufficient, refer to the official Terraform documentation for [lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb), [lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener), [lb_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule), [lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) and [lb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment).

- `load_balancer_type`: *Optional*. Type of load balancer to deploy. Defaults to `application`.
- `security_groups`: *Optional*. List of security group IDs to attach to the load balancer. Defaults to an empty list.
- `listeners`: *Optional*. A list of listener objects to associate with the load balancer. Technically optional, as the module can still be used without specifying any listeners, but it is not very useful without them.
        - `port`: *Required*. Port on which the listener listens.
        - `protocol`: *Required*. Protocol on which the listener listens.
        - `certificate_arn`: *Optional*. Certificate ARN of the SSL/TLS certificate for the listener. Required if listener is listening on port 443. 
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

## Contributing
The below instructions are to be performed within Git Bash. Installation and setup of Git Bash can be found [here](https://git-scm.com/downloads/win)

### Step 1 Clone or Update the Repo on your Machine
Clone the repository to your local machine. Details on this process can be found [here](https://support.atlassian.com/bitbucket-cloud/docs/clone-a-git-repository/)

If you already have the repository cloned locally, execute the following commands to update your local repo:
```bash
git checkout master
git pull
```

### Step 2 Create a Branch
Create a branch from the `master` branch to store your work. The branch name needs be formatted as follows:
```bash
feature/TICKET_NUMBER
```
Where the value of TICKET_NUMBER is the ticket for which your work is associated. 
The basic command for creating a branch is as follows:
```bash
git checkout -b feature/TICKET_NUMBER
```
For questions please refer to the documentation [here](https://docs.gitlab.com/ee/tutorials/make_first_git_commit/#create-a-branch-and-make-changes)

### Step 3 Make your Changes
Make your changes and addition to the module on any IDE of your choice. Most of the team uses VSCode and the offical Terraform plugin for this work.

### Step 4 Commit your Changes
After you've made your code changes and saved the changes. You need to commit the changes to your branch. This can be done as many times as you deem necessary.
The basic command to commit code appears as follows. Note each commit must begin with the ticket number associated with the completed work.
```bash
git commit -am "TICKET_NUMBER - description of changes"
```
More information on commits can be found in the documentation [here](https://docs.gitlab.com/ee/tutorials/make_first_git_commit/#commit-and-push-your-changes)

### Step 5 Push your Branch to the BitBucket (Remote) Repo
After commiting your changes, to protect your work from any issues while resolving merge conflicts and the like, push your branch to the remote repository by executing the following:
```bash
git push origin BRANCH_NAME
```
Note, BRANCH_NAME here is the name you set for your branch in step 2. For more information on pushing yopur changes refer to the documentation [here](https://docs.gitlab.com/ee/tutorials/make_first_git_commit/#commit-and-push-your-changes)

### Step 6 Merge Latest Master into your Branch Within your Local Machine
To have your branch approved and avoid merge conflicts your branch must be up to date with the latest commits to the `master` branch. To accomnplish this, execute the following within git bash:
```bash
git checkout master
git pull
git checkout YOUR_BRANCH
git merge master
```

Note: The above steps do the following. 
`git checkout master` Switches from your branch to the master branch, 
`git pull` updates your local master branch with the remote master branch, 
`git checkout YOUR_BRANCH` switches back to your branch, 
`git merge master` merges the updated master branch into your branch
Once the above are completed you must resolve any merge conflicts before proceeding. Documentation on all of the above can be found [here](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)

### Step 7 Push your Branch to the BitBucket (Remote) Repo (again)
After updating your branch with latest master (and resolving any merge conflicts) push your branch from local to remote as defined in step 5

### Step 8 Open a Pull Request
To open a pull request within bitbucket between your branch and the master branch complete the following:

    From the open repository, select the Create button and select Pull request in the This repository section of the dropdown menu.

    Fill out the rest of the pull request form. 

    Click Create pull request.
Assign a team member to review your code, some may already be assigned by default. More information on this can be found [here](https://www.atlassian.com/git/tutorials/making-a-pull-request)

Once the pull request is opened a set of linting, security scanning and testing tasks will execute against your code, as soon as the job is complete a status will appear on your pull request.

### Step 9 Complete Code Review and Resolve Any Issues
Before any pull request can be merged it must
1. Have approval from a team member
2. Have a passing sec/lint/test job

You may need to rework some of your code to satisfy the above two requirements. This will require you to repeat steps 3-7.


### Done!

Once the above checks are completed the code can be merged and a tag will be applied to signify the latest version of the module. To apply a tag, after your code has been approved/merged complete the following

```bash
git tag v1.0.1
git push tag v1.0.1
```

The tag number needs to be the next iteration from the modules current version. For example the next version from the above example would be v1.0.2 etc.


### Pull Request Checklist

Ensure each item on the following checklist is complete before updating any tenant deployments with a new version of this module,

- [] Merge `master` into feature branch
- [] Open PR from feature branch into `master` branch
- [] Ensure tests are passing in Jenkins
- [] Get approval from lead
- [] Merge into `master`
- [] Increment `git tag` version
- [] Update Changelog
- [] Publish latest version on Confluence


### TODOS

1. Currently, the `mdt-eter-core-compute-lb` module has only been tested for load balancers of type `application`. `network` load balancers should also be supported by this module, but they need to be tested. This will require reworking how the listener rules are generated!