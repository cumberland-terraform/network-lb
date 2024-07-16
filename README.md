# Enterprise Terraform 
## AWS Core TEMPLATE
### Overview

TODO

### Usage

The bare minimum deployment can be achieved with the following configuration,

```
module "<service>" {
	source          		= "ssh://git@source.mdthink.maryland.gov:22/et/mdt-eter-aws-core-<component>-<service>.git"
	
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

	<service>			= {
        # TODO
	}
}
```

`platform` is a parameter for *all* **MDThink Enterprise Terraform** modules. For more information about the `platform`, in particular the permitted values of the nested fields, see the [mdt-eter-platform documentation](https://source.mdthink.maryland.gov/projects/ET/repos/mdt-eter-platform/browse). The following section goes into more detail regarding the `<service>` variable.

### Parameters

TODO

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

Ensure each item on the following checklist is complete before updating any tenant deployments with a new version of the ``mdt-eter-core-compute-eks`` module,

- [] Update Changelog
- [] Open PR into `test` branch
- [] Ensure tests are passing in Jenkins
- [] Increment `git tag` version
- [] Merge PR into `test`
- [] Open PR from `test` into `master` branch
- [] Get approval from lead
- [] Merge into `master`
- [] Publish latest version on Confluence