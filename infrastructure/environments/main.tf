/******************************************************************************
* VPC
*******************************************************************************/

/**
* The VPC is the private cloud that provides the network infrastructure into
* which we can launch our aws resources.  This is effectively the root of our
* private network.
*/
resource "aws_vpc" "main_vpc" {
  cidr_block            = "172.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Application         = "ceros-ski" 
    Environment         = var.environment
    Name                = "ceros-ski-${var.environment}-main_vpc"
    Resource            = "modules.environment.aws_vpc.main_vpc"
  }
}

/**
* Provides a connection between the VPC and the public internet, allowing
* traffic to flow in and out of the VPC and translating IP addresses to public
* addresses.
*/
resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id        = aws_vpc.main_vpc.id

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-main_internet_gateway"
    Resource    = "modules.environment.aws_internet_gateway.main_internet_gateway"
  }
}

/**
* An elastic IP address to be used by the NAT Gateway defined below.  The NAT
* gateway acts as a gateway between our private subnets and the public
* internet, providing access out to the internet from with in those subnets,
* while denying access in to them from the public internet.  This IP address
* acts as the IP address from which all the outbound traffic from the private
* subnets will originate.
*/
resource "aws_eip" "eip_for_the_nat_gateway" {
  vpc = true

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name        = "ceros-ski-${var.environment}-us-east-1a-eip_for_the_nat_gateway"
    Resource    = "modules.availability_zone.aws_eip.eip_for_the_nat_gateway"
  }
}

/******************************************************************************
* Public Subnet 
*******************************************************************************/

/**
* A public subnet with in our VPC that we can launch resources into that we
* want to be auto-assigned public ip addresses.  These resources will be
* exposed to the public internet, with public IPs, by default.  They don't need
* to go through, and aren't shielded by, the NAT Gateway.
*/
resource "aws_subnet" "public_subnets" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, 2 + count.index)
    availability_zone       = element(var.availability_zones, count.index)
    map_public_ip_on_launch = true
    count                   = var.public_subnets_count
    tags = {
        Name                = "ceros-ski-${count.index * 2 +1}.0_${element(var.availability_zones, count.index)}"
        Application         = "ceros-ski" 
        Resource            = "modules.availability_zone.aws_subnet.public_subnet"
        Environment         = var.environment
 }
}
/**
* A NAT Gateway that lives in our public subnet and provides an interface
* between our private subnets and the public internet.  It allows traffic to
* exit our private subnets, but prevents traffic from entering them.
*/

resource "aws_nat_gateway" "nat_gateway" {
    allocation_id = aws_eip.eip_for_the_nat_gateway.id
    subnet_id     = element(aws_subnet.public_subnets.*.id, 0)
    
    tags = {
      Application = "ceros-ski" 
      Environment = var.environment 
      Name        = "ceros-ski-${var.environment}-us-east-1a"
      Resource    = "modules.availability_zone.aws_nat_gateway.nat_gateway"
 }
}

/**
* A route table for our public subnet.
*/
resource "aws_route_table" "public_route_table" {
  vpc_id        = aws_vpc.main_vpc.id 

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name        = "ceros-ski-${var.environment}-us-east-1a-public"
    Resource    = "modules.availability_zone.aws_route_table.public_route_table"
  }
}

/**
* A route from the public route table out to the internet through the internet
* gateway.
*/
resource "aws_route_table" "public_rt" {
    vpc_id         = aws_vpc.main_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_internet_gateway.id
    }
}

/**
* Associate the public route table with the public subnets.
*/
resource "aws_route_table_association" "public" {
    count          = var.public_subnets_count
    subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
    route_table_id = aws_route_table.public_rt.id
}




/******************************************************************************
* Private Subnet 
*******************************************************************************/

/** 
* A private subnet for pieces of the infrastructure that we don't want to be
* directly exposed to the public internet.  Infrastructure launched into this
* subnet will not have public IP addresses, and can access the public internet
* only through the route to the NAT Gateway.
*/


resource "aws_subnet" "private_subnets" {
    vpc_id                  = aws_vpc.main_vpc.id
    cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 8, count.index)
    availability_zone       = element(var.availability_zones, count.index)
    map_public_ip_on_launch = false
    count                   = var.private_subnets_count

    tags = {
        Name                = "ceros-ski-${count.index *2}.0_${element(var.availability_zones, count.index)}"
        Application         = "ceros-ski" 
        Environment         = var.environment
        Resource            = "modules.availability_zone.aws_subnet.private_subnet"
 }
}

/**
* A route table for the private subnet.
*/
resource "aws_route_table" "private_route_table" {
  vpc_id        = aws_vpc.main_vpc.id 

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name        = "ceros-ski-${var.environment}-us-east-1a-private"
    Resource    = "modules.availability_zone.aws_route_table.private_route_table"
  }
}

/**
* A route from the private route table out to the internet through the NAT  
* Gateway.
*/

resource "aws_route_table" "private_rt" {
    vpc_id             = aws_vpc.main_vpc.id
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_gateway.id
 }
}

/**
* Associate the private route table with the private subnet.
*/
resource "aws_route_table_association" "private" {
    count          = var.private_subnets_count
    subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
    route_table_id = aws_route_table.private_rt.id
}


/******************************************************************************
* Bastion Host
*******************************************************************************/
/**
* A security group to allow SSH access into our bastion instance.
*/
resource "aws_security_group" "bastion" {
  name          = "bastion-security-group"
  vpc_id        = aws_vpc.main_vpc.id 

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource    = "modules.availability_zone.aws_security_group.bastion"
  }

}

/**
* The public key for the key pair we'll use to ssh into our bastion instance.
*/
resource "aws_key_pair" "bastion" {
  key_name    = "ceros-ski-bastion-key-us-east-1a"
  public_key  = file(var.public_key_path) 
}

/**
* This parameter contains the AMI ID for the most recent Amazon Linux 2 ami,
* managed by AWS.
*/
data "aws_ssm_parameter" "linux2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs"
}

/**
* Launch a bastion instance we can use to gain access to the private subnets of
* this availabilty zone.
*/
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.linux2_ami.value
  key_name                    = aws_key_pair.bastion.key_name 
  instance_type               = "t3.micro"

  associate_public_ip_address = true
  subnet_id                   = element(aws_subnet.public_subnets, 0).id
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  tags = {
    Application               = "ceros-ski" 
    Environment               = var.environment 
    Name                      = "ceros-ski-${var.environment}-us-east-1a-bastion"
    Resource                  = "modules.availability_zone.aws_instance.bastion"
  }
}

/******************************************************************************
* ECS Cluster
*
* Create ECS Cluster and its supporting services, in this case EC2 instances in
* and Autoscaling group.
*
* *****************************************************************************/

/**
* The ECS Cluster and its services and task groups. 
*
* The ECS Cluster has no dependencies, but will be referenced in the launch
* configuration, may as well define it first for clarity's sake.
*/

resource "aws_ecs_cluster" "cluster" {
  name          = "ceros-ski-${var.environment}"

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.ecs.cluster.aws_ecs_cluster.cluster"
  }
}

/*******************************************************************************
* AutoScaling Group
*
* The autoscaling group that will generate the instances used by the ECS
* cluster.
*
********************************************************************************/

/**
* The IAM policy needed by the ecs agent to allow it to manage the instances
* that back the cluster.  This is the terraform structure that defines the
* policy.
*/
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

/**
* The policy resource itself.  Uses the policy document defined above.
*/
resource "aws_iam_policy" "ecs_agent" {
  name        = "ceros-ski-ecs-agent-policy"
  path        = "/"
  description = "Access policy for the EC2 instances backing the ECS cluster."

  policy      = data.aws_iam_policy_document.ecs_agent.json
}

/**
* A policy document defining the assume role policy for the IAM role below.
* This is required.
*/
data "aws_iam_policy_document" "ecs_agent_assume_role_policy" {
  statement {
    actions       = [
                    "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

/**
* The IAM role that will be used by the instances that back the ECS Cluster.
*/
resource "aws_iam_role" "ecs_agent" {
  name               = "ceros-ski-ecs-agent"
  path               = "/"

  assume_role_policy = data.aws_iam_policy_document.ecs_agent_assume_role_policy.json
}

/**
* Attatch the ecs_agent policy to the role.  The assume_role policy is attached
* above in the role itself.
*/
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name 
  policy_arn = aws_iam_policy.ecs_agent.arn 
}

/**
* The Instance Profile that associates the IAM resources we just finished
* defining with the launch configuration.
*/
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ceros-ski-ecs-agent"
  role = aws_iam_role.ecs_agent.name 
}

/**
* A security group for the instances in the autoscaling group allowing HTTP
* ingress.  With out this the Target Group won't be able to reach the instances
* (and thus the containers) and the health checks will fail, causing the
* instances to be deregistered.
*/
resource "aws_security_group" "autoscaling_group" {
  name              = "ceros-ski-${var.environment}-autoscaling_group"
  description       = "Security Group for the Autoscaling group which provides the instances for the ECS Cluster."
  vpc_id            = aws_vpc.main_vpc.id 

  ingress {
    description     = "HTTP Ingress"
    from_port       = 80 
    to_port         = 80 
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  depends_on        = [
                      aws_security_group.lb
  ]

  tags = {
    Application     = "ceros-ski"
    Environment     = var.environment
    Resource        = "modules.ecs.cluster.aws_security_group.autoscaling_group"
  }
}

/** 
* This parameter contains the AMI ID of the ECS Optimized version of Amazon
* Linux 2 maintained by AWS.  We'll use it to launch the instances that back
* our ECS cluster.
*/


data "aws_ssm_parameter" "cluster_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

/**
* The launch configuration for the autoscaling group that backs our cluster.  
*/
resource "aws_launch_configuration" "cluster_laucher" {
  name                 = "ceros-ski-${var.environment}-cluster"
  image_id             = data.aws_ssm_parameter.cluster_ami_id.value 
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.autoscaling_group.id]

  // Register our EC2 instances with the correct ECS cluster.
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOF
}

/**
* The autoscaling group that backs our ECS cluster.
*/
resource "aws_autoscaling_group" "cluster" {
  name                 = "ceros-ski-${var.environment}-cluster"
  min_size             = 1
  max_size             = 2 
  
  vpc_zone_identifier  = [for subnet in aws_subnet.private_subnets : subnet.id] 
  launch_configuration = aws_launch_configuration.cluster_laucher.name 

  tags = [{
    "key"                 = "Application"
    "value"               = "ceros-ski"
    "propagate_at_launch" = true
  },
  {
    "key"                 = "Environment"
    "value"               = var.environment
    "propagate_at_launch" = true
  },
  {
    "key"                 = "Resource"
    "value"               = "modules.ecs.cluster.aws_autoscaling_group.cluster"
    "propagate_at_launch" = true
  }]
}

/**
* Create the task definition for the ceros-ski backend, in this case a thin
* wrapper around the container definition.
*/
resource "aws_ecs_task_definition" "backend" {
  family                = "ceros-ski-${var.environment}-backend"
  network_mode          = "awsvpc"

  container_definitions = <<EOF
[
  {
    "name": "ceros-ski",
    "image": "${var.repository_url}:latest",
    "environment": [
      {
        "name": "PORT",
        "value": "80"
      }
    ],
    "cpu": 512,
    "memoryReservation": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name        = "ceros-ski-${var.environment}-backend"
    Resource    = "modules.environment.aws_ecs_task_definition.backend"
  }
}

/**
* Create the ECS Service that will wrap the task definition.  Used primarily to
* define the connections to the load balancer and the placement strategies and
* constraints on the tasks.
*/
resource "aws_ecs_service" "backend" {
  name            = "ceros-ski-${var.environment}-backend"
  cluster         = aws_ecs_cluster.cluster.id 
  task_definition = aws_ecs_task_definition.backend.arn
  
  desired_count                       = 2 
  deployment_minimum_healthy_percent  = 50
  deployment_maximum_percent          = 100

  network_configuration {
    security_groups   = [aws_security_group.autoscaling_group.id]
    subnets           = aws_subnet.private_subnets.*.id
  }
  load_balancer {
    target_group_arn  = aws_lb_target_group.ceros-ski.id
    container_name    = "ceros-ski"
    container_port    = 80
  }
  depends_on          = [
                        aws_lb_listener.ceros-ski
  ]
 
  ordered_placement_strategy {
    type              = "binpack"
    field             = "cpu"
  }

  tags = {
    Application       = "ceros-ski" 
    Environment       = var.environment 
    Resource          = "modules.environment.aws_ecs_service.backend"
  }
}
/**
*Load Balancer to be attached to the ECS cluster to distribute the load among instances
*/
resource "aws_lb" "default" {
  name            = "ecs-lb"
  subnets         = aws_subnet.public_subnets.*.id
  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "ceros-ski" {
  name        = "ceros-ski-target"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "ceros-ski" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ceros-ski.id
    type             = "forward"
  }
}

resource "aws_security_group" "lb" {
  name          = "ecs-alb-security-group"
  vpc_id        = aws_vpc.main_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}