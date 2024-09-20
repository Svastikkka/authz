# Use a base image with Go installed
FROM golang:1.18-alpine

# Install git (needed for go mod download)
RUN apk add --no-cache git

# Create app directory
WORKDIR /go/src/app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Install dependencies
RUN go mod tidy

# Copy the source code
COPY . .

# Explicitly fetch required module after copying source
#RUN go get github.com/docker/go-plugins-helpers@v0.0.0-20240701071450-45e2431495c8

# Build the Go binary
RUN go build -o /authz-plugin

# Define the entry point
ENTRYPOINT ["/authz-plugin"]
