# UPGRADE_NOTES

**Scope:** Upgrade legacy Terraform configs (~> 0.12.29 + aws ~> 3.1.0) to Terraform ~> 1.0 + aws ~> 4.x, keep S3 backend, and fix Ansible/Docker provisioning across mixed Ubuntu hosts (bionic/focal/jammy).

---

## 0) Prep & Safety
- Create a new branch from the environment you’re upgrading.
- Install multiple Terraform versions with **tfenv** so you can switch as needed.
- Confirm AWS CLI access to the state bucket:
  ```bash
  aws s3 ls s3://<state-bucket>
  ```

---

## 1) Terraform Upgrade Path

### 1.1 Update configuration to modern provider syntax
Add/adjust `required_version` and `required_providers` in the *root* module:
```hcl
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
```

> If coming from 0.12, use Terraform 0.13 once to run `terraform 0.13upgrade` which rewrites legacy provider addresses (fixes the “Invalid legacy provider address” error).

### 1.2 Re-initialize against the existing S3 backend
From the env directory:
```bash
terraform init -reconfigure
terraform init -upgrade
```
> **Do not** use `-migrate-state` unless you’re actually changing backends.

### 1.3 Backend credentials: use one method consistently
Pick **one** of these and use it locally and in CI:
```bash
# A) Profiles file
export AWS_SHARED_CREDENTIALS_FILE=/path/to/credentials
export AWS_PROFILE=<profile>

# B) Static keys
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
# export AWS_SESSION_TOKEN=...   # if using STS
```

### 1.4 Provider blocks & aliases
Provide **one unaliased** provider in the root module (or pin every resource to an alias):
```hcl
provider "aws" {
  region  = "us-east-2"
  profile = "default-profile" # optional if CI env variables set
}

provider "aws" {
  alias   = "compute"
  region  = "us-east-2"
  profile = "compute-profile"
}

provider "aws" {
  alias   = "network"
  region  = "us-east-1"
  profile = "network-profile"
}
```
Pin resources/modules that live in non-default accounts/regions:
```hcl
resource "aws_s3_bucket" "backup" {
  provider = aws.compute
  bucket   = var.backup_bucket
}

resource "aws_s3_bucket_versioning" "backup" {
  provider = aws.compute
  bucket   = aws_s3_bucket.backup.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  provider = aws.compute
  bucket   = aws_s3_bucket.backup.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
```

### 1.5 Refresh-only plan to validate state vs. config
```bash
terraform plan -refresh-only
```
Fixes common:
- **Invalid legacy provider address** → run `terraform 0.13upgrade` then re-init.
- **Provider requires explicit configuration / region required** → ensure a default provider in root or explicit `provider = aws.alias` on all resources.

### 1.6 Import existing resources (avoid unwanted creates)
If plan shows creates for existing infra, import them first. Examples:
```bash
terraform import 'module.<env>.aws_s3_bucket.backup'                      <bucket>
terraform import 'module.<env>.aws_s3_bucket_versioning.backup'          <bucket>
terraform import 'module.<env>.aws_s3_bucket_server_side_encryption_configuration.backup' <bucket>
terraform import 'module.<env>.aws_ec2_instance_state.app-state'           i-xxxxxxxxxxxxxxxxx
```
> The destination **module path must exist** in code before import.

---

## 2) CI Consistency
Ensure CI uses the same:
- Terraform version.
- Backend config (no accidental migrate).
- AWS credentials method (`AWS_SHARED_CREDENTIALS_FILE` + `AWS_PROFILE` recommended).
- Provider alias mapping as in code.

Grant CI user/role S3 permissions as needed (min):
- `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`
- `s3:GetBucketVersioning`, `s3:PutBucketVersioning`
- `s3:GetEncryptionConfiguration`, `s3:PutEncryptionConfiguration`

---

## 3) Ansible Provisioning (Docker) — Mixed Ubuntu Hosts

### 3.1 Facts first
We use `gather_facts: false` + an explicit `- setup:` in `pre_tasks`, so we can rely on:
`ansible_distribution_release` (bionic/focal/jammy).

### 3.2 Clean up stale Docker repos (idempotent)
Remove any `download.docker.com` lines from `/etc/apt/sources.list` and from `*.list` files under `/etc/apt/sources.list.d/` before adding correct repos.

### 3.3 Choose install strategy per codename
- **bionic (18.04)** → use **Ubuntu’s `docker.io`** (Docker CE pins no longer published for bionic). Do **not** add Docker’s repo for bionic.
- **focal/jammy** → use Docker’s official repo; optionally pin a specific CE version.

### 3.4 Safe Jinja for optional pinning
Avoid precedence errors by precomputing a boolean:
```yaml
vars:
  pin_docker: "{{ ((docker_version | default('') | string | length) > 0) }}"
  docker_packages:
    - "{{ pin_docker | ternary('docker-ce=' ~ docker_version, 'docker-ce') }}"
    - "{{ pin_docker | ternary('docker-ce-cli=' ~ docker_version, 'docker-ce-cli') }}"
    - "{{ pin_docker | ternary('docker-ce-rootless-extras=' ~ docker_version, 'docker-ce-rootless-extras') }}"
  docker_packages_state: present
```

### 3.5 DOCKER_VERSION handling
- **Jammy (22.04):** e.g. `5:27.0.3-1~ubuntu.22.04~jammy`
- **Focal (20.04):** e.g. `5:27.0.3-1~ubuntu.20.04~focal`
- **Bionic (18.04):** leave empty and install `docker.io`.

If your controller’s entrypoint sets a default (e.g. jammy pin), override in CI per env or ignore it in the play on bionic.

---

## 4) Troubleshooting Cheatsheet

- **Invalid legacy provider address (aws/null)**
  - Run `terraform 0.13upgrade`, add `required_providers`, re-init.

- **Provider requires explicit configuration / region is required**
  - Add one default provider in root, or attach `provider = aws.<alias>` everywhere and remove the default.

- **AccessDenied on bucket versioning/encryption**
  - CI user lacks S3 perms; attach identity policy or use correct profile/role.

- **Terraform wants to create resources that exist**
  - `terraform import` those resources into state first.

- **Ansible Docker install fails on bionic**
  - Don’t pin CE; use `docker.io` and skip Docker’s repo for bionic.

- **Jinja error `'>' not supported between int and str'`**
  - Parenthesize the boolean or compute `pin_docker` as shown above.

- **State rollback**
  - Don’t `terraform state push` over a newer serial. If truly needed, restore the desired object *version* directly in S3, then re-init.

---

## 5) Command Recap
```bash
# Init & upgrade
terraform init -reconfigure
terraform init -upgrade
terraform plan -refresh-only

# Imports (examples)
terraform import 'module.storage.aws_s3_bucket.backup' <bucket>
terraform import 'module.storage.aws_s3_bucket_versioning.backup' <bucket>
terraform import 'module.storage.aws_s3_bucket_server_side_encryption_configuration.backup' <bucket>
terraform import 'module.<env>.aws_ec2_instance_state.app-state' i-xxxx

# Plan/apply
terraform plan
terraform apply
```

---

# ansible/vars/os-map.yml (include in repo)

Create `ansible/vars/os-map.yml` and load it in the play (e.g., via `vars_files:`) to centralize version pins and repo logic.

```yaml
# ansible/vars/os-map.yml
# Maps Ubuntu codename to Docker CE pin. Empty string = no pin.
# For bionic we intentionally avoid CE pinning (use docker.io).

docker_version_map:
  bionic: ""   # use distro docker.io
  focal:  "5:27.0.3-1~ubuntu.20.04~focal"
  jammy:  "5:27.0.3-1~ubuntu.22.04~jammy"

# Whether to add Docker’s official repo per codename
# (bionic uses distro repo only)
add_docker_repo_map:
  bionic: false
  focal:  true
  jammy:  true
```

### Example usage in playbook
```yaml
gather_facts: false

pre_tasks:
  - setup:

  - name: Load OS map
    include_vars:
      file: ansible/vars/os-map.yml

  - name: Determine codename
    set_fact:
      os_codename: "{{ ansible_distribution_release }}"

  - name: Decide repo & version pin
    set_fact:
      docker_add_repo: "{{ add_docker_repo_map[os_codename] | default(true) }}"
      docker_version:  "{{ docker_version_map[os_codename]  | default('') }}"
      pin_docker:      "{{ ((docker_version | string | length) > 0) }}"

  - name: Clean any docker.com entries from sources
    lineinfile:
      path: /etc/apt/sources.list
      regexp: '^deb\s+.*download\.docker\.com/linux/ubuntu'
      state: absent

  - name: Purge docker.com lines from .list files
    find:
      paths: /etc/apt/sources.list.d
      patterns: '*.list'
      file_type: file
    register: apt_lists

  - lineinfile:
      path: "{{ item.path }}"
      regexp: '^deb\s+.*download\.docker\.com/linux/ubuntu'
      state: absent
    loop: "{{ apt_lists.files }}"
    when: apt_lists.matched | default(0) | int > 0

  - name: Ensure apt keyrings dir (for non-bionic)
    file:
      path: /etc/apt/keyrings
      state: directory
      mode: '0755'
    when: docker_add_repo

  - name: Add Docker GPG key (non-bionic)
    get_url:
      url: https://download.docker.com/linux/ubuntu/gpg
      dest: /etc/apt/keyrings/docker.asc
      mode: '0644'
    when: docker_add_repo

  - name: Add Docker apt repo (non-bionic)
    apt_repository:
      filename: docker
      repo: >-
        deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc]
        https://download.docker.com/linux/ubuntu {{ os_codename }} stable
      state: present
      update_cache: yes
    when: docker_add_repo

vars:
  docker_packages:
    - "{{ pin_docker | ternary('docker-ce=' ~ docker_version, 'docker-ce') }}"
    - "{{ pin_docker | ternary('docker-ce-cli=' ~ docker_version, 'docker-ce-cli') }}"
    - "{{ pin_docker | ternary('docker-ce-rootless-extras=' ~ docker_version, 'docker-ce-rootless-extras') }}"
  docker_packages_state: present
```

> For **bionic**, skip adding Docker’s repo; elsewhere, add it and optionally pin CE using the map.

---

**Done.** This note + the `os-map.yml` should make future upgrades and mixed-OS deployments predictable and repeatable.

