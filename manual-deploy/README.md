## A simple project to explore manual containerized deployment on AWS

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Local Code     │────▶│   Docker Image  │────▶│    Amazon ECR   │
│  (HTML/CSS/JS)  │     │   (Container)   │     │   (Registry)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │    Browser      │◀────│    Amazon EC2   │
                        │  (User Access)  │     │   (Container)   │
                        └─────────────────┘     └─────────────────┘
```

### Create the Dockerfile

At the project root, at the same level as the `website/` folder, create a file named `Dockerfile`:

```bash
touch Dockerfile
```

### Build the Docker image

```bash
docker build -t meu-website:v1.0 .
```

### Verify the created image

```bash
docker images
```

### Run the container locally

```bash
docker run -d -p 8080:80 --name meu-website-container meu-website:v1.0
```

### Check whether the container is running

```bash
docker ps
```

### View container logs

```bash
docker logs meu-website-container
```

---

## Amazon ECR Setup

### Open ECR

1. In the top search bar, type "ECR".
2. Click "Elastic Container Registry".

### Create a repository

1. Click "Create repository".
2. Configure:
   - **Visibility settings**: Private
   - **Repository name**: `meu-website`
   - **Tag immutability**: Disabled (default)
   - **Scan on push**: Enabled (recommended for security)
3. Click "Create repository".

### Record the repository URI

After creation, you will see something like:

```text
123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website
```

---

## Push the Image to ECR

### Configure the AWS CLI

If you have not configured it yet, run:

```bash
aws configure
```

### Authenticate Docker with ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

**Replace**:
- `us-east-1` with your region
- `123456789012` with your Account ID

### Tag the image for ECR

```bash
docker tag meu-website:v1.0 123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website:v1.0
```

### Push the image

```bash
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website:v1.0
```

---

## EC2 Instance Provisioning

#### Name and tags
- **Name**: `meu-website-server`

#### Application and OS image
- **AMI**: Amazon Linux 2023 (Free tier eligible)

#### Instance type
- **Instance type**: t3.micro (Free tier eligible)

#### Key pair
- Click "Create new key pair"
- **Key pair name**: `meu-website-key`
- **Key pair type**: RSA
- **Private key file format**: .pem (Linux/Mac) or .ppk (Windows/PuTTY)
- Click "Create key pair" and save the file

#### Network settings
- **VPC**: Default
- **Subnet**: No preference
- **Auto-assign public IP**: Enable
- **Firewall (security groups)**: Create security group
  - **Security group name**: `meu-website-sg`
  - **Description**: Security group for website

#### Security group rules
Add the following rules:

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| SSH  | TCP      | 22         | My IP  |
| HTTP | TCP      | 80         | 0.0.0.0/0 |

#### Storage configuration
- **Volume**: 8 GiB gp3 (default)

### Step 6.3: Configure the IAM Role for ECR access

#### Create the IAM role
1. In "Advanced details", find "IAM instance profile".
2. Click "Create new IAM profile".
3. Or open the IAM console and:
   - Click "Roles" → "Create role"
   - **Trusted entity**: AWS service
   - **Use case**: EC2
   - **Permissions**: Add `AmazonEC2ContainerRegistryReadOnly`
   - **Role name**: `EC2-ECR-Role`
4. Return to the EC2 configuration and select the created role.

### Record important information

Write down:
- **Public IP**: e.g. 54.123.45.67
- **Instance ID**: e.g. i-0abc123def456789

---

## Deploy on EC2

### Connect to the EC2 instance

#### On Linux/Mac:
```bash
chmod 400 meu-website-key.pem

ssh -i meu-website-key.pem ec2-user@54.123.45.67
```

### Install Docker on EC2

```bash
sudo yum update -y

sudo yum install docker -y

sudo systemctl start docker

sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

docker --version
```

### Authenticate Docker with ECR on EC2

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Pull the image from ECR

```bash
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website:v1.0
```

### Run the container

```bash
docker run -d -p 80:80 --name meu-website-prod --restart always 123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website:v1.0
```

#### Important parameters:
- **--restart always**: Restarts the container if the EC2 instance reboots
- **-p 80:80**: Maps port 80 (default HTTP)

### Verify that it is running

```bash
docker ps

docker logs meu-website-prod
```

---

## Verification and Testing

### Test 1: Access it in the browser

1. Open your browser.
2. Enter the EC2 public IP: `http://54.123.45.67`
3. Your website should appear.

### Test 2: Check logs on EC2

```bash
docker logs -f meu-website-prod

docker stats meu-website-prod
```

### Test 3: Test restart behavior

```bash
docker stop meu-website-prod

docker ps

docker start meu-website-prod

docker ps
```

---

## Troubleshooting

### Problem 1: "Cannot connect to the Docker daemon"

**Solution**:
```bash
sudo systemctl start docker
sudo usermod -a -G docker $USER
```

### Problem 2: The site does not open in the browser

**Checks**:
1. Is port 80 open in the security group?
2. Is the container running? (`docker ps`)
3. Is the public IP correct?
4. Test with curl on EC2: `curl localhost`

### Problem 3: "No basic auth credentials" when pulling from ECR

**Solution**:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin [ECR_URI]
```

### Problem 4: Permission denied in Docker

**Solution**:
```bash
sudo usermod -a -G docker ec2-user

exit
ssh -i key.pem ec2-user@IP
```

---

## Resource Cleanup

### Step 1: Stop and remove the container on EC2

```bash
docker stop meu-website-prod
docker rm meu-website-prod
docker rmi 123456789012.dkr.ecr.us-east-1.amazonaws.com/meu-website:v1.0
```

### Step 2: Terminate the EC2 instance

1. AWS Console → EC2
2. Select your instance
3. Actions → Instance State → Terminate

### Step 3: Delete the ECR image

1. AWS Console → ECR
2. Select the repository
3. Select the image
4. Delete

### Step 4: Delete the ECR repository (optional)

1. Select the repository
2. Delete

### Step 5: Delete the security group

1. EC2 → Security Groups
2. Select `meu-website-sg`
3. Actions → Delete

### Step 6: Delete the IAM role (optional)

1. IAM → Roles
2. Select `EC2-ECR-Role`
3. Delete

---

- [Docker Documentation](https://docs.docker.com/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Best Practices for Dockerfile](https://docs.docker.com/develop/dev-best-practices/)
