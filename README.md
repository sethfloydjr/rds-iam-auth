# RDS-IAM-AUTH

---

## VERSIONS

Configured in `_providers.tf`:

* Terraform — `~> 1.14.1`
* AWS Provider — `>= 6.0.0, < 7.0.0`
* Random — `~> 3.5.1`
* MySQL Provider — `~> 1.9`
* PostgreSQL Provider — `~> 1.22`

Configured in `vpc.tf`:

* VPC module — `~> 5.1.1`

---

## PURPOSE

This project demonstrates how to set up IAM authentication for PostgreSQL, MySQL, and MariaDB RDS instances on AWS. For a deeper dive, see the [AWS IAM database authentication docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).

This project covers all three RDS engine types that support IAM authentication. The infrastructure is intentionally kept minimal to focus on the IAM auth pattern itself. It should be reviewed and adapted before use in a production environment — see the inline code comments for notes on what to adjust.

<br/>

---

<br/>

## PROS AND CONS

### PROS

* Network traffic to and from the database is encrypted using SSL/TLS.
* IAM centralizes access control across all your RDS instances instead of managing credentials per database. This integrates naturally with SSO providers like Okta.
* Applications running on EC2, EKS, or Lambda can use their instance/pod/function IAM role to authenticate without storing any database password.

### CONS

* IAM database authentication is best suited for workloads with fewer than 200 new connections per second. For high-throughput connection patterns, consider using RDS Proxy in front of your instances.
* Auth tokens expire after 15 minutes, so clients must regenerate them on reconnect. Most connection libraries and drivers handle this transparently.

<br/>

---

<br/>

## ESTIMATED COST

Costs below are for **us-east-1** and assume one RDS instance (`db.t4g.micro`, Multi-AZ, 20 GB gp3). Prices are approximate and subject to AWS pricing changes.

| Resource | Details | Est. Monthly Cost |
| --- | --- | --- |
| RDS instance | db.t4g.micro, Multi-AZ | ~$23 |
| RDS storage | 20 GB gp3 | ~$2 |
| NAT Gateway | 1 gateway (see note) | ~$33 |
| Secrets Manager | 1 secret | ~$0.40 |
| **Total** | | **~$58/month** |

> **NAT Gateway note:** The VPC module defaults to one NAT gateway per availability zone — three gateways for this configuration — which brings the NAT cost to ~$99/month and the total to ~$124/month. To reduce this, add `single_nat_gateway = true` to `vpc.tf` before applying.
>
> **All three instances:** Applying all three RDS modules as-is (PostgreSQL + MySQL + MariaDB, three NAT gateways) runs approximately **$175/month**. Comment out the modules you do not need in `rds.tf`.

<br/>

---

<br/>

## SETUP AND USAGE

### TERRAFORM SETTINGS

Key variables are split between the root module and each engine-specific module.

* Root variables: `_variables.tf`
* Engine-specific variables:
    * `modules/mariadb/_variables.tf`
    * `modules/mysql/_variables.tf`
    * `modules/psql/_variables.tf`

<br/>

### GETTING SETUP

Apply the Terraform code for the RDS engine type(s) you need. The `mysql` and `postgresql` Terraform providers will automatically create the IAM-authenticated database users during apply.

> **Warning: applying as-is will provision all three RDS instances (PostgreSQL, MySQL, MariaDB). To use only one engine type, comment out the unneeded module blocks in `rds.tf`, remove the corresponding ARNs from the IAM policy in `iam_access.tf`, and remove the corresponding provider from `_providers.tf`.**

**Network access requirement:** The RDS instances are deployed in private subnets and are not publicly accessible. To connect from your local machine you need network access into the VPC — typically via a VPN or AWS Client VPN. The same network access is required for `terraform apply` to run the `mysql` and `postgresql` providers that create the database users.

**Download the RDS global SSL certificate bundle** to your local machine. This is required for IAM authentication:

* `curl -o ~/global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem`

**Retrieve the admin password** from Secrets Manager (useful for initial verification or manual DBA access):

* `aws secretsmanager get-secret-value --secret-id rds-iam-auth/admin-password --region us-east-1 --query SecretString --output text`

**Configure your local AWS credentials** as the `john.smith` IAM user created by Terraform:

* `aws configure` — enter the Access Key ID and Secret retrieved with `terraform output -raw access_key_secret`

<br/>

---

<br/>

### CONNECT TO THE PSQL DATABASE

The `developer` and `read_only` database users are created automatically by `psql_users.tf` during `terraform apply`.

Set your environment variables:

```bash
export RDSHOST="$(terraform output -raw psql_rds_endpoint)"
export REGION="us-east-1"
export RDSUSER="developer"   # or: read_only
```

Generate a 15-minute IAM auth token and connect:

```bash
export PGPASSWORD="$(aws rds generate-db-auth-token \
  --hostname $RDSHOST --port 5432 --region $REGION --username $RDSUSER)"

psql "host=$RDSHOST port=5432 sslmode=verify-full \
  sslrootcert=~/global-bundle.pem dbname=postgres \
  user=$RDSUSER password=$PGPASSWORD"
```

The token is valid for 15 minutes. If you disconnect and reconnect after it expires, regenerate it by re-running the `generate-db-auth-token` command. An active connection is not dropped when the token expires. For more detail, see the [IAM auth token docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Connecting.html) and [RDS SSL docs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html).

To use a GUI tool like pgAdmin, see [this AWS guide](https://aws.amazon.com/blogs/database/using-iam-authentication-to-connect-with-pgadmin-amazon-aurora-postgresql-or-amazon-rds-for-postgresql/). Your machine must be able to reach the RDS endpoint.

<br/>

---

<br/>

### CONNECT TO THE MYSQL AND MARIADB DATABASES

The connection steps are identical for MySQL and MariaDB. The `developer` and `read_only` database users are created automatically by `mysql.tf` during `terraform apply`.

> **Note:** Use the standard `mysql` client, not the `mariadb-client` package. The MariaDB client does not support the `--enable-cleartext-plugin` flag required for IAM authentication.

Set your environment variables:

```bash
export RDSHOST="$(terraform output -raw mysql_rds_endpoint)"   # or: mariadb_rds_endpoint
export REGION="us-east-1"
export RDSUSER="developer"   # or: read_only
```

Generate a 15-minute IAM auth token and connect:

```bash
export TOKEN="$(aws rds generate-db-auth-token \
  --hostname $RDSHOST --port 3306 --region $REGION --username $RDSUSER)"

mysql --host=$RDSHOST --port=3306 \
  --ssl-ca=~/global-bundle.pem \
  --enable-cleartext-plugin \
  --user=$RDSUSER \
  --password=$TOKEN
```

To use a GUI tool like SQL Workbench/J, see [this AWS guide](https://aws.amazon.com/blogs/database/use-iam-authentication-to-connect-with-sql-workbenchj-to-amazon-aurora-mysql-or-amazon-rds-for-mysql/). Your machine must be able to reach the RDS endpoint.

<br/>

---

<br/>

### EKS TO RDS ACCESS

For applications running inside an EKS cluster, pods can authenticate to RDS using their Kubernetes service account identity via IRSA (IAM Roles for Service Accounts). This eliminates the need for any stored credentials in your application.

For background, see the [EKS service accounts docs](https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html) and the [pod IAM configuration docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-configuration.html).

The following Terraform snippet shows how to create an IAM role that a specific Kubernetes service account can assume:

```hcl
resource "aws_iam_role" "rds_eks_access_role" {
  name               = "RDS_EKS_Access"
  assume_role_policy = data.aws_iam_policy_document.rds_eks_assume_role_policy.json
}

data "aws_iam_policy_document" "rds_eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.environment}-${var.namespace}:${var.service_name}"]
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.14.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0, < 7.0.0 |
| <a name="requirement_mysql"></a> [mysql](#requirement\_mysql) | ~> 1.9 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | ~> 1.22 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0, < 7.0.0 |
| <a name="provider_mysql"></a> [mysql](#provider\_mysql) | ~> 1.9 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | ~> 1.22 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mariadb_rds"></a> [mariadb\_rds](#module\_mariadb\_rds) | ./modules/mariadb | n/a |
| <a name="module_mysql_rds"></a> [mysql\_rds](#module\_mysql\_rds) | ./modules/mysql | n/a |
| <a name="module_psql_rds"></a> [psql\_rds](#module\_psql\_rds) | ./modules/psql | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.1.1 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_access_key.john_smith_access_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.john_smith_rds_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_user.john_smith](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.developer_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_secretsmanager_secret.db_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_admin_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [mysql_grant.iam_ro_user](https://registry.terraform.io/providers/terraform-providers/mysql/latest/docs/resources/grant) | resource |
| [mysql_grant.iam_user](https://registry.terraform.io/providers/terraform-providers/mysql/latest/docs/resources/grant) | resource |
| [mysql_user.iam_ro_user](https://registry.terraform.io/providers/terraform-providers/mysql/latest/docs/resources/user) | resource |
| [mysql_user.iam_user](https://registry.terraform.io/providers/terraform-providers/mysql/latest/docs/resources/user) | resource |
| [postgresql_grant.iam_dev_user_connect](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant.iam_ro_user_connect](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant) | resource |
| [postgresql_grant_role.iam_dev_user_rds_iam](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant_role) | resource |
| [postgresql_grant_role.iam_ro_user_rds_iam](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/grant_role) | resource |
| [postgresql_role.iam_dev_user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [postgresql_role.iam_ro_user](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/role) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Automation"></a> [Automation](#input\_Automation) | n/a | `string` | `"terraform"` | no |
| <a name="input_Owning_Team"></a> [Owning\_Team](#input\_Owning\_Team) | n/a | `string` | `"YourTeam"` | no |
| <a name="input_Service_Name"></a> [Service\_Name](#input\_Service\_Name) | n/a | `string` | `"rds-demo"` | no |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | n/a | `number` | `20` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | n/a | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | n/a | `bool` | `true` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Days to retain automated backups. Must be between 0 and 35. | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | Daily UTC time range for automated backups. Must not overlap with maintenance\_window. | `string` | `"05:30-07:30"` | no |
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | See here for more info:  https://aws.amazon.com/rds/instance-types/ | `string` | `"db.t4g.micro"` | no |
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | n/a | `string` | `"iam-auth-demo"` | no |
| <a name="input_db_secret_name"></a> [db\_secret\_name](#input\_db\_secret\_name) | AWS Secrets Manager secret name where the RDS admin password is stored. | `string` | `"rds-iam-auth/admin-password"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | n/a | `string` | `"admin"` | no |
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | n/a | `string` | `"us-east-1"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Prevents accidental database deletion. Must be disabled manually before destroy. | `bool` | `true` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Weekly UTC window for RDS maintenance. Syntax: ddd:hh24:mi-ddd:hh24:mi. | `string` | `"Sun:03:00-Sun:04:59"` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Deploy RDS in Multi-AZ mode for automatic failover. Doubles instance cost. | `bool` | `true` | no |
| <a name="input_rds_dev_user"></a> [rds\_dev\_user](#input\_rds\_dev\_user) | n/a | `string` | `"developer"` | no |
| <a name="input_rds_ro_user"></a> [rds\_ro\_user](#input\_rds\_ro\_user) | n/a | `string` | `"read_only"` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Set to true only for dev/test environments. Always false in production. | `bool` | `false` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Encrypt RDS storage at rest using KMS (AWS-managed key by default). | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | n/a | `string` | `"gp3"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | 16 available subnets - 4094 IP addresses per subnet | `string` | `"200.100.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | n/a | `string` | `"demo"` | no |
| <a name="input_vpc_subnets"></a> [vpc\_subnets](#input\_vpc\_subnets) | n/a | `map(list(string))` | <pre>{<br/>  "azs": [<br/>    "us-east-1a",<br/>    "us-east-1b",<br/>    "us-east-1c"<br/>  ],<br/>  "database_subnets": [<br/>    "200.100.96.0/20",<br/>    "200.100.112.0/20",<br/>    "200.100.128.0/20"<br/>  ],<br/>  "private_subnets": [<br/>    "200.100.0.0/20",<br/>    "200.100.16.0/20",<br/>    "200.100.32.0/20"<br/>  ],<br/>  "public_subnets": [<br/>    "200.100.48.0/20",<br/>    "200.100.64.0/20",<br/>    "200.100.80.0/20"<br/>  ]<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key_secret"></a> [access\_key\_secret](#output\_access\_key\_secret) | ############################################################################### USER OUTPUTS ############################################################################### |
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of availability\_zones available for the VPC |
| <a name="output_database_subnet_group_name"></a> [database\_subnet\_group\_name](#output\_database\_subnet\_group\_name) | Name of database subnet group |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | List of IDs of database subnets |
| <a name="output_mariadb_rds_endpoint"></a> [mariadb\_rds\_endpoint](#output\_mariadb\_rds\_endpoint) | ############################################################################### MARIADB RDS OUTPUTS ############################################################################### |
| <a name="output_mariadb_rds_resource_id"></a> [mariadb\_rds\_resource\_id](#output\_mariadb\_rds\_resource\_id) | n/a |
| <a name="output_mysql_rds_endpoint"></a> [mysql\_rds\_endpoint](#output\_mysql\_rds\_endpoint) | ############################################################################### MYSQL RDS OUTPUTS ############################################################################### |
| <a name="output_mysql_rds_resource_id"></a> [mysql\_rds\_resource\_id](#output\_mysql\_rds\_resource\_id) | n/a |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | List of public Elastic IPs created for AWS NAT Gateway |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_psql_rds_endpoint"></a> [psql\_rds\_endpoint](#output\_psql\_rds\_endpoint) | ############################################################################### PSQL RDS OUTPUTS ############################################################################### |
| <a name="output_psql_rds_resource_id"></a> [psql\_rds\_resource\_id](#output\_psql\_rds\_resource\_id) | n/a |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
