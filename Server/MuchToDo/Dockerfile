# ---- Build Stage ----
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install dependencies
COPY go.mod go.sum ./
RUN go mod download -x

# Copy source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o muchtodo ./cmd/api/main.go

# ---- Runtime Stage ----
FROM alpine:3.20

WORKDIR /app

# Add CA certs for MongoDB Atlas TLS and timezone data
RUN apk --no-cache add ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/muchtodo .

EXPOSE 8080

CMD ["./muchtodo"]