# Enterprise Terraform 
## AWS Core Compute Elastic Load Balancer
### Overview

TODO

### Usage

The bare minimum deployment can be achieved with the following configuration,

```
module "lb" {
	source          		= "ssh://git@source.mdthink.maryland.gov:22/etm/mdt-eter-aws-core-compute-lb.git"
	
	platform	                = {
		aws_region              = "<region-name>"
                account                 = "<account-name>"
                acct_env                = "<account-environment>"
                agency                  = "<agency>"
                program                 = "<program>"
                app_env                 = "<application-environment>"
                domain                  = "<active-directory-domain>"
                pca                     = "<pca-code>"
                availability_zones      = [ "<availability-zones>" ]
	}

	lb			        = {
        # TODO
	}
}
```

`platform` is a parameter for *all* **MDThink Enterprise Terraform** modules. For more information about the `platform`, in particular the permitted values of the nested fields, see the [mdt-eter-platform documentation](https://source.mdthink.maryland.gov/projects/etm/repos/mdt-eter-platform/browse). The following section goes into more detail regarding the `lb` variable.

### Parameters

TODO

- `load_balancer_type`: TODO. Defaults to `application`.
- `security_groups`: TODO. Defaults to an empty list.
- `listeners`: TODO
        - `port`: TODO
        - `protocol`: TODO
        - `certificate_arn`: TODO
        - `default_action`: TODO
                - `type`: TODO. Defaults to `forward`.
                - `target_group_arn`: ARN of the Target Group to which the rule will apply its action.
        - `rules`: TODO. **NOTE**: The priority is determined by the order of the list. In other words, the first rule in the list is given the highest priority, with each subsequent item in the list given a lower priority than the one that preceded it. 
                - `type`: TODO. Defaults to `forward`
                - `target_group_arn`: ARN of the Target Group to which the rule will apply its action.
- `target_groups`: TODO
        - `port`: TODO
        - `protocol`: TODO
        - `target_id`: TODO
        - `target_type`: TODO
        
## Notes

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