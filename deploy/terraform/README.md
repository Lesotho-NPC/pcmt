# Terraform

## Usage

1. Usage is recommended through Docker containers.  If anything in here is 
  changed it's recommended to re-build the docker container locally with 
  `./build.sh` or push to CI, wait for the image to be built and published, and 
  then pull with `docker pull pcmt/terraform`.  Better yet, prefer to run these 
  in CD pipelines.
1. See [CD Deploy](../README.md)

## Layout

The terraform layout here borrows heavily from [TERRAFORM, VPC, AND WHY YOU WANT A TFSTATE FILE PER ENV][charity-majors].

[charity-majors]: https://charity.wtf/2016/03/30/terraform-vpc-and-why-you-want-a-tfstate-file-per-env/

## Highlighted practices:

1. Separate tfstate file per environment.
1. Apply changes through CD pipelines.  Use Docker container to `plan` changes.
  This keeps things clean (e.g. use the same terraform version).
1. Shared resources (e.g. VPC, security groups, etc), should go in a separate
  environment.
1. Use remote states, especially to query other environments (e.g. for VPC).
1. Don't forget to `terraform fmt`.

## Quick Reference
Direct usage of Terraform is not advised.  Instead prefer to use the CI/CD jobs.

### Destroy instance: 

```
cd <env>
terraform destroy -target module.pcmt.aws_instance.app
```

### Taint, so that app is re-deployed (destructive):

```
cd <env>
terraform taint module.pcmt.null_resource.deploy-docker
terraform apply
```
Note:  if the module can't be found durring `terraform taint` then run
`terraform state list` and copy the one that ends in `docker-deploy`, using
it in the `terraform taint` command.


## Not used

- Not using `aws_key_pair` as using this resource in TF results in the key-pair
  either forcing the key-pair to be recreated if not manually imported, and
  will also break between different environments where taking one down will
  try to remove the key pair.  Not using until this [bug][aws_key_pair_bug] is 
  resolved.

[aws_key_pair_bug]: https://github.com/terraform-providers/terraform-provider-aws/issues/1092


## Upgrading

## 1.1 to 1.8

1. At `1.1`, run `./run-docker.sh <env> plan`, be sure no changes are planned.
2. Upgrade Dockerfile to `1.8`
   1. Check aws version is at `~> 4.0`
   2. Check aws vpc version is at `~> 3.0`
   3. Update tf version to `~> 1.0`
1. Run `./run-docker.sh <env> init -upgrade`
4. Delete `.terraform` directory for env
5. Run `./run-docker.sh <env> plan`, double check no changes to make.
6. Run `./run-docker.sh <env> apply -auto-approve`


## 0.15 to 1.1

1. At `0.15`, run `./run-docker.sh <env> plan`, be sure no changes are planned.
2. Upgrade Dockerfile to `1.1.9`
   1. Check aws version is at `~> 4.0`
   2. Check aws vpc version is at `~> 3.0`
   3. Update tf version to `~> 1.1.0`
1. Run `./run-docker.sh <env> init -upgrade`
4. Delete `.terraform` directory for env
5. Run `./run-docker.sh <env> plan`, double check no changes to make.
6. Run `./run-docker.sh <env> apply -auto-approve`

## 0.14 to 0.15

1. At `0.14`, run `./run-docker.sh <env> plan`, be sure no changes are planned.
2. Upgrade Dockerfile to `0.15.5`
   1. Check aws version is at `~> 4.0`
   2. Check aws vpc version is at `~> 3.0`
   3. Update tf version to `~> 0.15.0`
# 3. Delete any `.terraform.lock.hcl` for env
4. Delete `.terraform` directory for env
5. Run `./run-docker.sh <env> plan`, double check no changes to make.
6. Run `./run-docker.sh <env> apply -auto-approve`

## 0.13 to 0.14

1. At `0.13`, run `./run-docker.sh <env> plan`, be sure no changes are planned.
   - Exception:  if the change is to the lifecycle rule on the S3 bucket, proceed, and double check
     the bucket affter `apply`.
2. Upgrade Dockerfile to `0.14.11`
   1. Update aws version to `~> 4.0`
   2. Check aws vpc version is at `~> 3.0`
   3. Update tf version to `~> 0.14.0`
3. Delete any `.terraform.lock.hcl` for env
4. Delete `.terraform` directory for env
5. Run `./run-docker.sh <env> plan`, double check no changes to make.
6. Run `./run-docker.sh <env> apply -auto-approve`

## 0.12 to 0.13

1. At 0.12: `terraform plan` - check no changes, Fix and `apply` so that `plan` reports no changes 
   before upgrade.
2. Upgrade to `~> 0.13`
3. delete from the top module:  `.terraform`.
4. Run `./run-docker.sh <env> 0.13upgrade -yes`
5. Fix any warnings, remove the TF version from `main.tf` as it'll now be in `versions.tf` after
   upgrade script is ran.

Upgrade AWS version:

1. Delete the `.terraform` dir
2. Update AWS provider and module versions to `~> 3.0`
3. Run `./run-docker.sh <env> init`
4. Run `./run-docker.sh <env> plan`
5. Ensure no changes, warnings or errors.
6. Run `./run-docker.sh <env> apply -auto-approve`

---
Copyright (c) 2019, VillageReach.  Licensed CC BY-SA 4.0:  https://creativecommons.org/licenses/by-sa/4.0/
