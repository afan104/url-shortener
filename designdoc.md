## Design

#### App:
- Takes a url from the user and maps it to a unique, shorter generated code stored in a database. It maps the shortened code to the original longer one.
- DynamoDB: Good for small scale project and NoSQL which works since there are no complex relationships to track and 1 primary key. Works well with AWS.
- Compared to relational (SQL) databases: has joins which link data across tables with relationships. Since this is a simple 1 to 1 linked mapping, there's no complex relationship that would require a SQL database
- Future Considerations: could potentially include an additional SQL database if other information such as user data, metrics, and reporting were involved later on (e.g. Aurora Serverless v2). Or potentially add additional dynamodb tables that are precomputed depending on the simplicity of metrics.


### Containerizing the App
- Setup docker image and push to AWS to make sure it runs properly.

### Creating the AWS infra for running image 
- Use Terraform to setup the ECR for reproducibility
    - VPC: we want to avoid using the default VPC which is in a public subnet. For security, we'll set this up with Terraform to use private IPs.
    - subnets
    - security groups
    - IAM roles
    - DynamoDB
    - ECR
    - ECS cluster: to pull the docker image from ECR to VPC
    - task definition
    - service
    - Note: Much faster to set all this up and teardown with Terraform
- Alternative: CDK
    - better for pure AWS, but we want extensibility with GitHub Actions
