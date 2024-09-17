# 3-Tier Web Application Infrastructure with Terraform

This project contains Terraform configurations to deploy a scalable and secure 3-tier web application infrastructure in AWS.

## Architecture Overview

The infrastructure consists of three tiers:

1. **Web Tier**: Public-facing load balancer and auto-scaling group of web servers
2. **Application Tier**: Private subnet with application servers
3. **Database Tier**: Private subnet with RDS MySQL instance

A bastion host is used for secure SSH access to the database tier.

## Project Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
```

- `main.tf`: Main configuration file containing resource definitions
- `variables.tf`: Input variables for the module
- `outputs.tf`: Output values after applying the configuration

## Accessing the Infrastructure

- Web Application: Access via the load balancer DNS name (available in Terraform outputs)
- Bastion Host: SSH using the key pair specified in the configuration
- Database: Connect through the bastion host using SSH tunneling

## Customization

Modify `variables.tf` to customize the deployment according to your requirements. Key variables include:

- `threetier_region`: AWS region for deployment
- `threetier_cidr`: CIDR block for the VPC
- `dbname`: Name of the RDS database
- `db_username`: Username for the RDS instance
- All other variable names should be changed to your desired name

## Security Considerations

- The bastion host is the only entry point for SSH access to the database tier
- All sensitive data should be encrypted at rest and in transit
- Ensure to regularly update and patch all instances