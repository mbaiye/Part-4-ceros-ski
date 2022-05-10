# Architecture

The infrastructure for the Ceros-ski game is constructed in two, interdependent
pieces that must be deployed separately.  The first is the ECR repository that
will store the built docker images for the ceros-ski container.  The second is
the ECS Cluster that will run those docker images.

The ECS Cluster is currently built to use an EC2 Autoscaling group that sits in
a private VPC in multiple availability zones.  It has a single service and a
single task definition. 

The ECS Cluster has a VPC, with both public and private subnets, the public
subnets holds the baiston host for trouble shooting and Nat gateway egress traffic from 
instances in the private subnets.

A load balancer was attached to the ECS service to distribute the load in a situation where 
there is high traffic to the node.js ski game.

I used a smaller base image for the Dockerfile in other to reduce the size of the image.

The ECR Repository is defined in `infrastructure/repositories`.

The ECS Cluster is defined in `infrastructure/environments`.

### Automated Deployment System for Docker Image
There are different tools that could be used to achieve this system, depending of strategy and flexibility of the party involved.
we could decide to use Jenkins as a system to achieve this. now using jenkins would mean that we would have to set up the server for the jenkins software, However that process can be eliminated using JCasC (Jenkins Configuration as Code). There are other managed systems such as CircleCI, or Github Actions that dont require you to do maintenance and manual setup of your automation/CICD server.

Not withstanding for this use case scenario, i would love to use Jenkins to explain, because of its flexibility and extensibility with plugins. Having set up a server that is going to run Jenkins. You can follow this steps below to automate the deployment of the docker image to dockerhub or ECR.

### STEP 1 
Install aws_pipeline, docker plugin. this will enable you to carryout some important steps later in you pipeline.

### STEP 2 
Configure crendentials (aws, docker) to enable you to authenticate during pipeline runtime.

### STEP 3 
create a jenkins file to hold your configuration for the pipeline.
Now this will include different stages;
- build stage
    to build and tag the docker image from the Dockerfile
- push stage
    to authenticate with ECR using created credentials and push the built image to aws ECR.

### STEP 4
Configure a web hook to github such that anytime a commit is made to the repo for the application, it will trigger the pipeline 
and all changes will be dockerized and deployed automatically.