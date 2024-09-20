# Use a base image with Go installed
FROM golang:1.18-alpine

# Create app directory
WORKDIR /go/src/app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Install dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the Go binary
RUN go build -o /authz-plugin

# Define the entry point
ENTRYPOINT ["/authz-plugin"]
