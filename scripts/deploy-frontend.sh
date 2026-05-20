#!/bin/bash
set -euo pipefail

# Deploy frontend to S3 and invalidate CloudFront
# Usage: ./deploy-frontend.sh <s3-bucket> <cloudfront-distribution-id>

S3_BUCKET=${1:-$S3_BUCKET_NAME}
CF_DISTRIBUTION=${2:-$CLOUDFRONT_DISTRIBUTION_ID}
DIST_DIR=${3:-"Client/dist"}

if [ -z "$S3_BUCKET" ] || [ -z "$CF_DISTRIBUTION" ]; then
  echo "Usage: $0 <s3-bucket> <cloudfront-distribution-id>"
  exit 1
fi

echo " Deploying frontend to s3://$S3_BUCKET"

# Sync assets with long cache (hashed filenames)
aws s3 sync "$DIST_DIR" "s3://$S3_BUCKET" \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html"

# Upload HTML files with no-cache
aws s3 sync "$DIST_DIR" "s3://$S3_BUCKET" \
  --cache-control "no-cache, no-store, must-revalidate" \
  --include "*.html" \
  --exclude "*" \
  --include "*.html"

echo " S3 sync complete"

# Invalidate CloudFront
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "$CF_DISTRIBUTION" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text)

echo " CloudFront invalidation started: $INVALIDATION_ID"
aws cloudfront wait invalidation-completed \
  --distribution-id "$CF_DISTRIBUTION" \
  --id "$INVALIDATION_ID"

echo " CloudFront cache invalidated"