# RDS-IAM-AUTH
---
# VERSIONS

Configured in _providers.tf

* Terraform - ">1.5.1, <1.6.0"
* AWS Provider - "> 5.0.0, <6.0.0"
* Random - "~> 3.5.1"

Configured in vpc.tf

* VPC module - "~> 5.1.1"


## PURPOSE

This project demonstrates how to setup IAM authentication into a PSQL, MYSQL, and MariaDB RDS instance to increase your security posture inside AWS.
For a deeper dive checkout the AWS Support Docs [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html).

This project was brought about because I recently had to complete this very project where I work. In looking around on the internet to see how others had done this, I was not having much luck. I was able to piece together what should be done but that was from looking through a lot of AWS docs and half written tutorials on the subject. Here I have put together the steps for all 3 RDS types that accept IAM authentication. Feel free to fork and rework this code to fit your needs. This is a very basic use case and should not represent something you would use in your production environment without adding security measures. For simplicity and ease of understanding, I have made this fairly insecure on purpose. There are a few notes in the code that will point out things you should change to make this more secure.

<br/>

---

<br/>

## PROS AND CONS

### PROS

* Network traffic to and from the database is encrypted using Secure Socket Layer (SSL) / Transport Layer Security (TLS).
* You can use IAM to centrally manage access to your database resources, instead of managing access individually on each DB instance. This can be extrapolated out to being managed by SSO like Okta
* For applications running on Amazon EC2, you can use profile credentials specific to your EC2 instance to access your database instead of a password, for greater security.

### CONS

* In general, consider using IAM database authentication when your applications create fewer than 200 connections per second, and you don't want to manage usernames and passwords directly in your application code.
* This will likely be a new way of connecting to a database for most developers so there might be a slight learning curve. I have not run into any issues that the AWS documentation could not help me with.

<br/>

---

<br/>

## RESOURCES CREATED

* IAM user
* IAM Access Key
* IAM Role & Policy
* EC2 Instance to be used as a Bastion
* RDS Instances
* SSM Parameter for storing the `admin` user's password.
* Security Groups
* VPC

<br/>

---

<br/>

## SETUP AND USAGE

### TERRAFORM SETTINGS

There are a few variables that you will want to pay attention to in this stack. For general vars see the `variables.tf` file in the root of the repo. For RDS type specific vars see the `variable.tf` files located in th respective module directories.

* General:
    * `rds-iam-auth/variables.tf`

* Module Specific:
    * `modules/mariadb/variables.tf`
    * `modules/mysql/variables.tf`
    * `modules/psql/variables.tf

In the `scripts/bastion.tpl` file you will notice that a MariaDB client is not installed. The regular mysql client will work just fine for this use case. Installing `mariadb-client-core-10.3` will cause issues with the `--enable-cleartext-plugin` flag and you will get an error that looks similar to this, `mysql: unknown option '--enable-cleartext-plugin'`.

<br/>

### GETTING SETUP

You will need to fully apply the Terraform code provided for the type of RDS instance you need. This will build out the resources needed for a basic RDS setup. Note that you will need to refer to several of the outputs given in the following steps. I would suggest building your terraform code in a separate terminal than the one you try to connect to the database with. Note that this process could also be automated with a simple script that is executed when the Terraform apply is run but that is for another demo.

<br/>

!!!IF YOU APPLY THE TERRAFORM AS IS YOU WILL BUILD ALL THREE RDS INSTANCES!!!

<br/>

Once the terraform code has been applied you will need to connect to the Bastion instance. Very basically, you will add your SSH key to your local keychain and then connect to the Bastion instance. Your commands may differ based on your local working OS but my steps look like this:
* `ssh-add ~/.ssh/my_key`
* ` ssh -A ubuntu@123.123.123.123` (This is the public facing IP address of your Bastion instance. For production use you should have this instance locked down more with a security group or behind a VPN and you would also have an EIP attached that is connected to a Route53 record. If the instance went down and came back up you would have a script that reattaches the EIP and the R53 record would still point to your instance.)
* ` sudo su -` to become root

Once you have successfully connected to the Bastion as the `admin` user which is named and created from the variables.tf file. The following steps of creating the user and granting permissions is done for you in the `mysql.tf` file now. These are the manual steps that you would need to do so these are good to know anyways. You will connect to the database and create a new user, `dev`, that will be given the `rds_iam` permission so that IAM users who are allowed via their role assignment, will be able to log into this RDS instance.

Grab the admin password:
* `aws ssm --region us-east-1 get-parameters --names "PATH_OF_YOUR_SSM_PARAMETER" | grep Value`

See below for instructions on how to connect to your specific RDS instance...

<br/>

---

<br/>

### CONNECT TO THE PSQL DATABASE

While still as the root user on your bastion, run the following commands:
* `export RDSHOST="INSERT_ENDPOINT_HOST_NAME"` (An example might look like this: `iam-auth-demo-postgres.sdfv8356vhkj.us-east-1.rds.amazonaws.com`)
* `psql -h $RDSHOST -p 5432 -U admin -d postgres` (You are connecting as the `admin` user here first.)

<br/>

Once connected to the database run these commands:
* `CREATE USER dev WITH LOGIN;` (Creates the user `dev`)
* `GRANT rds_iam TO dev;` (Allows IAM users to connect as `dev` using IAM roles)
    * Optional steps that you may want to go ahead and do but are not required for the `dev` user to be able to connect"
        * `CREATE DATABASE your_database;`
        * `GRANT CONNECT ON DATABASE your_database TO dev;`

<br/>

Quit out of the connection and setup the environment to connect as your `dev` user. There are a few different ways you can pass in AWS secret keys to your bastion to be able to connect. You can give permissions through the IAM role for the Bastion as well. For simplicity we will paste in our keys like below. Do not do this in your production environment!!

* `export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"` (The key for our John.Smith IAM user we created with the Terraform code)
* `export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"`
* `export REGION="us-east-1"` (The default_region defined in variables.tf)
* `export RDSUSER="dev"`
* `export PGPASSWORD="$(aws rds generate-db-auth-token --hostname $RDSHOST --port 5432 --region $REGION --username $RDSUSER)"` (This is the session token. It is created based on the values above and only lasts for 15 minutes. If you connect to the the DB and 15 minutes elapse and you disconnect, you will need to regenerate this token to connect again. If you are connected and time elapses you are not kicked off the instance. See [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Connecting.html) for more information about session tokens for RDS.)
* `echo $PGPASSWORD` (Verify that your token was created correctly.)
* `psql "host=$RDSHOST port=5432 sslmode=verify-full sslrootcert=/opt/global-bundle.pem dbname=postgres user=$RDSUSER password=$PGPASSWORD"` (Command to finally connect as the `dev` user. Notice that we use SSL here. The global RDS cert is installed for you on the bastion on Terraform apply. This is required for IAM authentication. For more info on that see [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) and [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html).)

Should you want to use a tool like `pgadmin` look [here](https://aws.amazon.com/blogs/database/using-iam-authentication-to-connect-with-pgadmin-amazon-aurora-postgresql-or-amazon-rds-for-postgresql/) for help on setting that up. Scroll all the way down to the **Connecting** section. Note that whatever machine you want to connect from, it needs to be allowed in the security group for the RDS instance.

<br/>

---

<br/>

### CONNECT TO THE MYSQL AND MARIADB DATABASES

The steps and instructions are the exact same for the MYSQL and MariaDB database types.

<br/>

While still as the root user on your bastion, run the following commands:
* `export RDSHOST="INSERT_ENDPOINT_HOST_NAME"` (An example might look like this: `iam-auth-demo-mysql.sdfv8356vhkj.us-east-1.rds.amazonaws.com`)
* `mysql -h $RDSHOST -P 3306 -u admin -p` (You are connecting as the `admin` user here first.)

Once connected to the database run these commands:
* `CREATE USER dev IDENTIFIED WITH AWSAuthenticationPlugin as 'RDS';` (Creates the user `dev`)
* From here the `dev` user is able to connect. You may want to pre-setup any databases or grants at this time.

<br/>

Quit out of the connection and setup the environment to connect as your `dev` user. There are a few different ways you can pass in AWS secret keys to your bastion to be able to connect. You can give permissions through the IAM role for the Bastion as well. For simplicity we will paste in our keys like below. Do not do this in your production environment!!

* `export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY_ID"` (The key for our John.Smith IAM user we created with the Terraform code)
* `export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS_KEY"`
* `export REGION="us-east-1"` (The default_region defined in variables.tf)
* `export RDSUSER="dev"`
* `export TOKEN="$(aws rds generate-db-auth-token --hostname $RDSHOST --port 3306 --region us-east-1 --username $RDSUSER)"` (This is the session token. It is created based on the values above and only lasts for 15 minutes. If you connect to the the DB and 15 minutes elapse and you disconnect, you will need to regenerate this token to connect again. If you are connected and time elapses you are not kicked off the instance. See [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.Connecting.html) for more information about session tokens for RDS.)
* `echo $TOKEN` (Verify that your token was created correctly.)
* `mysql --host=$RDSHOST --port=3306 --ssl-ca=/opt/global-bundle.pem --enable-cleartext-plugin --user=$RDSUSER --password=$TOKEN` (Command to finally connect as the `dev` user. Notice that we use SSL here. The global RDS cert is installed for you on the bastion on Terraform apply. This is required for IAM authentication. For more info on that see [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html) and [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html).)


Should you want to use a tool like `SQL Workbench` look [here](https://aws.amazon.com/blogs/database/use-iam-authentication-to-connect-with-sql-workbenchj-to-amazon-aurora-mysql-or-amazon-rds-for-mysql/) for help on setting that up. Scroll all the way down to the **Connecting** section. Note that whatever machine you want to connect from, it needs to be allowed in the security group for the RDS instance.

<br/>

---

<br/>

### EKS TO RDS ACCESS

At work we have a somewhat unique setup for EKS clusters. Some developers need to be able to access these databases from the EKS cluster for application purposes. For deeper help you will want to look [here](https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html) in the AWS docs for EKS. Below is a sample of what we have done to make this work in our unique setup and it might help you get started as well. Be sure to look here for help with getting your pods setup to access the RDS instance as well, [here](https://docs.aws.amazon.com/eks/latest/userguide/pod-configuration.html)

```
#Allows access from the EKS cluster to RDS instance
# This block essentially does what is outlined here:
# https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html
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
      values = [
        "system:serviceaccount:${var.environment}-${var.namespace}:${var.service_name}"
      ]
    }
  }
}
```