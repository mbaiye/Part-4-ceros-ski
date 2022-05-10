# Usage

There are two separate infrastructures defined here.  The first defines the ECR
Repository and the second the actual ECS Environment.  The ECR Repository must
be created first, and the `repository_url` output taken and used as an input
variable for the ECS Environment.

### Creating the ECR Repository

To create the ECR Repository, you'll need to first initialize it with a .tfvars
file defining the credentials you want to use to access AWS and the region
you'd like to deploy to.

You can inspect `infrastructure/repositories/variables.tf` for a list of
required variables and attendant descriptions.  An example is shown below.

Example `infrastructure/repositories/terraform.tfvars`:
```
// Path to your .aws/credentials file.
aws_credentials_file = "/Users/malcolmreynolds/.aws/credentials"

// The name of the profile from your aws credentials file you'd like to use.
aws_profile = "serenity"

// The region we'll create the repository in
aws_region = "us-east-2"
```

Once you've created your tfvars file, you can run `terraform init` to
initialize terraform for this infrastructure.  You'll need to ensure you have
Terraform version 0.14+ installed.  Then you can run `terraform apply` to
create it.

After terraform has run it will output the repository URL, which you will need
to push an initial docker image and to give to the ECS stack to pull the image.

### Pushing an Initial Docker Image

Before you can build the ECS infrastructure, you'll need to push an initial
docker image to the ECR repository.  The ECS infrastructure will pull the
`latest` tag, so you'll want to push that tag to the repository.

From the root project directory.
```
# Go to the app directory an build the docker image.
$ cd app

# Build the docker image.
$ docker build -t ceros-ski .

# Tag the docker image.
$ docker tag <repository_url>/ceros-ski:latest

# Login to ECR.  
$ aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <repository_url> 

# Push the docker image to ECR.
$ docker push <repository_url>/ceros-ski:latest
```

### Building the ECS Stack

Once you've built the repo and push the initial docker image, then you need to
build the ECS Stack.  Go to `infrastructure/environments`.  Run `terraform init` and
then populate the `terraform.tfvars` file.

Example `infrastructure/environments/terraform.tfvars`:
```
aws_credentials_file = "/Users/malcolmreynolds/.aws/credentials"
aws_profile = "serenity"
aws_region = "us-east-2"
repository_url = "<account #>.dkr.ecr.us-east-1.amazonaws.com/ceros-ski"
public_key_path = "/Users/malcolmreynolds/.ssh/id_rsa.pub"
```

Once you've initialized the infrastructure and created your .tfvars file, you
can use `terraform apply` to create the ECS infrastructure.

After running `terraform apply` there will be an output on the screen which is the
load balancer ip. copy and paste it in a browser you might see a "503 error", but wait for a minute or two then reload.

the ski game is fully functional
