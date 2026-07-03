## Design

#### App:
- Takes a url from the user and maps it to a unique, shorter generated code stored in a database. It maps the shortened code to the original longer one.
- DynamoDB: Good for small scale project and NoSQL which works since there are no complex relationships to track and 1 primary key. Works well with AWS.
- Compared to relational (SQL) databases: has joins which link data across tables with relationships. Since this is a simple 1 to 1 linked mapping, there's no complex relationship that would require a SQL database
- Future Considerations: could potentially include an additional SQL database if other information such as user data, metrics, and reporting were involved later on (e.g. Aurora Serverless v2). Or potentially add additional dynamodb tables that are precomputed depending on the simplicity of metrics.


### Containerizing the App
- Setup docker image and push to AWS ECR. Use docker image for reproducibility, consistency, and as standard practice.
- App gets containerized into an image so that it can run as a container later on.

### Creating the AWS infra for the image 
- Use Terraform
    - sets up: vpc, internet gateway, subnets, route tables, security group, iam roles, ecr repo, ecs cluster, dynamodb
- VPC: Want to avoid using the default VPC which is in a public subnet. For security, set this up with Terraform to use private IPs. Contains the EC2 cluster. Subnets, route tables, and security groups are defined in the VPC and used to route traffic. Internet gateway is attached at the boundary of the VPC and used to let traffic into VPC.
- route tables
    - Only need two rules to route internal versus internet traffic
    - rule 1: local - will route dest IP that are local to VPC
        - dest 10.0.0.0/16, target local
    - rule 2: IGW - anything non-local to VPC will be sent out to internet via IGW
        - dest 0.0.0.0/0, target iwgw-xxxx
- security group (virtual firewall)
    - port 22 open at EC2 IP to allow ssh in
    - port 8000 open from anywhere so people can reach this app
    - can send out traffic to any target 
        - to respond to any user requests
        - to reach the ECR
    - Note: everything is denied by default, so these allow things in
- IAM roles
    - Attached a given resource, allows actions to/from some other resource
    - In this case, we only need one role attached to EC2 with 2 policies
    - Policy 1: (relating to DyanmoDB) allow gets and puts to/from DynamoDB
    - Policy 2: (relating to ECR) allow getting login token from ECR, pulling the image from ECR, and pulling image layers from ECR
- DynamoDB: a table is initialized by terraform
- ECR Repository: holds the docker image once docker pushes to ECR. EC2 later pulls the image from ECR.
- ECS EC2 cluster: Pulls image from ECR and cuns the container from the image. See next section for justification.
- Note: Much faster to set this up and teardown with Terraform because of all the parts

### Running the container from the image
- Reads docker image, creates isolated env of filesystem/network/process space, and executes uvicorn app.main:app --host 0.0.0.0 --port 8000 to run the app in the containeer and listen on port 8000
-  ECS Fargate v. EC2
    - EC2: What I plan to use here. Will allow me to work with a real server, ssh in and see what's going on. I can manually add features on there as well for learning.
    - ECS Fargate: Not a real VM and will take a part of a real host. Won't be able to ssh in or do manual maintenance because not real. 
