# Much To Do — StartTech Application

A full-stack Todo application with a React frontend and Golang backend, deployed on AWS with a complete CI/CD pipeline.

## Application Structure
much-to-do/
├── .github/workflows/
│   ├── frontend-ci-cd.yml   # React build and S3 deployment
│   └── backend-ci-cd.yml    # Go build, Docker, EC2 deployment
├── Client/                  # React + Vite + TypeScript frontend
├── Server/MuchToDo/         # Golang + Gin backend API
└── scripts/                 # Deployment and operations scripts

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 19, Vite, TypeScript, TailwindCSS |
| Backend | Golang, Gin framework |
| Database | MongoDB Atlas |
| Cache | Redis (ElastiCache) |
| Frontend Hosting | AWS S3 + CloudFront |
| Backend Hosting | AWS EC2 + ALB + Auto Scaling |
| Container Registry | AWS ECR |
| Monitoring | AWS CloudWatch |

## CI/CD Pipelines

### Frontend Pipeline (`frontend-ci-cd.yml`)
Triggers on changes to `Client/` on the `feature/full-stack` branch.

| Stage | Steps |
|-------|-------|
| Build | Install deps, lint, security audit, build bundle |
| Deploy | Sync to S3, invalidate CloudFront cache |

### Backend Pipeline (`backend-ci-cd.yml`)
Triggers on changes to `Server/` on the `feature/full-stack` branch.

| Stage | Steps |
|-------|-------|
| Test | Unit tests, integration tests, vet, staticcheck, govulncheck |
| Build | Build Docker image, Trivy scan, push to ECR |
| Deploy | Rolling update via ASG instance refresh, smoke tests |

## Required GitHub Secrets

Set these under Settings → Secrets → Actions:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | AWS region e.g. `us-east-1` |
| `S3_BUCKET_NAME` | Frontend S3 bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID |
| `VITE_API_BASE_URL` | Backend API URL e.g. `http://<alb-dns>` |
| `ALB_DNS_NAME` | ALB DNS name for health checks |

> All values come from Terraform outputs in the `starttech-infra` repo.

## Local Development

### Frontend
```bash
cd Client
cp .env.example .env
# Set VITE_API_BASE_URL=http://localhost:8080
npm install
npm run dev
```

### Backend
```bash
cd Server/MuchToDo
cp .env.example .env
# Fill in MONGO_URI, JWT_SECRET_KEY, REDIS_ADDR
docker-compose up -d  # starts MongoDB and Redis
go run ./cmd/api/main.go
```

### Run Tests
```bash
cd Server/MuchToDo
# Unit tests
go test ./... -short

# Integration tests (requires Docker)
INTEGRATION=true go test ./... -timeout 120s
```

## Scripts

| Script | Usage |
|--------|-------|
| `scripts/deploy-frontend.sh` | Manually deploy frontend to S3 |
| `scripts/deploy-backend.sh` | Runs on EC2 as UserData to start container |
| `scripts/health-check.sh` | Check backend health via ALB |
| `scripts/rollback.sh` | Roll back to previous launch template version |

## Deployment Flow
Code Push
│
├── Client/ changes ──► Frontend Pipeline
│                           ├── Build React bundle
│                           ├── Sync to S3
│                           └── Invalidate CloudFront
│
└── Server/ changes ──► Backend Pipeline
├── Run tests
├── Build & push Docker image to ECR
├── Rolling update ASG
└── Smoke test via ALB