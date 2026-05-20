#!/bin/bash
set -euo pipefail

# This script runs on EC2 instances as UserData
# IMAGE_URI_PLACEHOLDER is replaced by the CI/CD pipeline before base64 encoding

IMAGE_URI="IMAGE_URI_PLACEHOLDER"

echo "Deploying backend image: $IMAGE_URI"

# Install Docker if not present
if ! command -v docker &> /dev/null; then
  yum update -y
  yum install -y docker
  systemctl start docker
  systemctl enable docker
fi

# Install AWS CLI if not present
if ! command -v aws &> /dev/null; then
  yum install -y aws-cli
fi

# Login to ECR
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
  "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Pull new image
docker pull "$IMAGE_URI"

# Stop existing container if running
docker stop muchtodo 2>/dev/null || true
docker rm muchtodo 2>/dev/null || true

# Run new container
docker run -d \
  --name muchtodo \
  --restart unless-stopped \
  -p 8080:8080 \
  --env-file /etc/muchtodo/env \
  --log-driver awslogs \
  --log-opt awslogs-region="$AWS_REGION" \
  --log-opt awslogs-group=/starttech/backend \
  --log-opt awslogs-stream="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
  "$IMAGE_URI"

echo " Backend container started"

# Clean up old images
docker image prune -f