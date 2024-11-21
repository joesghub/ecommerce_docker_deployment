# Ecommerce Docker Deployment
## PURPOSE

The purpose of this workload is to automate the deployment and management of a containerized e-commerce application using Docker, Terraform, and Jenkins. We utilize Terraform for provisioning infrastructure (VPC, EC2, RDS, etc.), Docker for containerizing the Django backend and React frontend applications, and Jenkins for CI/CD pipeline automation. This setup allows us to deploy the application securely within a private subnet, enhancing scalability and isolation.

### Key Benefits:
- **Docker**: Containers offer better resource management, portability, and consistency across environments, providing a more efficient and scalable way to deploy applications compared to using just Terraform and scripts.
- **Terraform**: Enables declarative infrastructure management, ensuring repeatable, consistent infrastructure provisioning across environments.
- **Jenkins**: Automates the process of building, testing, and deploying the application, reducing manual intervention and potential errors.

## STEPS

1. **Provision Infrastructure with Terraform**:  
   We created a custom VPC in `us-east-1`, configured multiple availability zones (AZ1 and AZ2), private and public subnets, and EC2 instances in each subnet for the Bastion host and application containers. Additionally, an RDS database and a load balancer were created to route traffic to the public subnets.

   - **Why it’s important**: Terraform provides a consistent, repeatable way to create and manage infrastructure resources. This ensures that all environments (dev, staging, production) are consistent.

2. **Setup Jenkins and Jenkins Node Agent**:
   - Created a `t3.micro` EC2 for Jenkins (Manager) and a `t3.medium` EC2 for Jenkins (Node).
   - Installed Jenkins, Java 17, Terraform, Docker, and AWS CLI on the instances.
   - Configured the Jenkins Node Agent to connect to the Jenkins Manager instance for executing the pipeline jobs.

   - **Why it’s important**: Jenkins automates the CI/CD pipeline, ensuring continuous integration and deployment without manual intervention.

3. **Build Docker Containers**:
   - Containerized the Django backend and React frontend using Docker. The application is deployed only in the private subnet of our Terraform-managed infrastructure.
   
   - **Why it’s important**: Docker ensures that the application runs in the same environment in all stages, from development to production, minimizing the "it works on my machine" problem.

4. **Configure and Execute Jenkins Pipeline**:
   - Set up stages in the Jenkinsfile to:
     - Build the backend and frontend applications.
     - Run tests with `pytest-django`.
     - Build and push Docker images to Docker Hub.
     - Deploy infrastructure using Terraform.

   - **Why it’s important**: The pipeline automates all tasks (build, test, deploy), allowing faster feedback and consistent deployments.

## SYSTEM DESIGN DIAGRAM

![System Design Diagram](https://github.com/joesghub/ecommerce_docker_deployment/blob/main/diagram.jpg?raw=true)

## ISSUES/TROUBLESHOOTING

1. **Terraform Infrastructure Setup**:  
   In a previous workload, I encountered issues while setting up the infrastructure with Terraform, resulting in failed deployments. However, in this workload, I successfully deployed the infrastructure, which included configuring the EC2s, VPC, subnets, load balancer, and RDS database.

   - **Solution**: Ensured that all necessary Terraform resource blocks were included, especially security groups and IAM roles for EC2 instances and RDS.

2. **Jenkins Node Agent Connection**:  
   There was a problem where the Jenkins Node Agent was not connecting correctly, causing pipeline failures.

   - **Solution**: Verified the SSH configuration for Jenkins and ensured that the private key for the Jenkins Node was correctly set up. The `Non verifying Verification Strategy` was used to bypass the host key verification.

## OPTIMIZATION

1. **Docker Image Optimization**:
   - Use multi-stage builds in Dockerfiles to reduce the size of images.
   - Utilize Docker layers efficiently to cache dependencies and speed up builds.

2. **Jenkins Pipeline Optimization**:
   - Implement parallel stages in Jenkins for testing and building frontend and backend, reducing overall pipeline execution time.
   - Use Jenkins shared libraries to refactor and reuse common steps across pipelines.

3. **Infrastructure Optimization**:
   - Consider implementing auto-scaling for the EC2 instances in the private subnets to handle varying traffic loads automatically.
   - Utilize AWS Fargate for container orchestration instead of managing EC2 instances directly.

4. **Security Optimization**:
   - Implement VPC peering or AWS PrivateLink to secure communication between services and databases.
   - Use IAM roles with the least privilege for all AWS resources.

## CONCLUSION

In this workload, I successfully containerized the e-commerce application using Docker, set up infrastructure with Terraform, and automated the deployment with Jenkins. By using Docker for containerization and Terraform for infrastructure as code, I was able to create a scalable, repeatable, and consistent deployment pipeline. Although there were a few troubleshooting steps, such as setting up the Jenkins Node Agent and configuring Terraform correctly, the workload provided valuable insights into improving infrastructure management and CI/CD automation.

Further optimization can be achieved through Docker image improvements, Jenkins pipeline parallelization, and additional security measures.
