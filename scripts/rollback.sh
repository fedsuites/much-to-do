#!/bin/bash
set -euo pipefail

# Rollback the ASG to the previous launch template version
# Usage: ./rollback.sh

ASG_NAME=${ASG_NAME:-starttech-backend-asg}
LT_NAME=${LT_NAME:-starttech-backend-lt}

echo "⏪ Starting rollback for ASG: $ASG_NAME"

# Get current default version
CURRENT_VERSION=$(aws ec2 describe-launch-templates \
  --launch-template-names "$LT_NAME" \
  --query 'LaunchTemplates[0].DefaultVersionNumber' \
  --output text)

PREVIOUS_VERSION=$((CURRENT_VERSION - 1))

if [ "$PREVIOUS_VERSION" -lt 1 ]; then
  echo " No previous version to roll back to"
  exit 1
fi

echo " Rolling back from version $CURRENT_VERSION to $PREVIOUS_VERSION"

# Set previous version as default
aws ec2 modify-launch-template \
  --launch-template-name "$LT_NAME" \
  --default-version "$PREVIOUS_VERSION"

# Trigger instance refresh with previous version
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{
    "MinHealthyPercentage": 50,
    "InstanceWarmup": 60
  }'

echo "Rollback initiated — monitor the ASG in AWS console"