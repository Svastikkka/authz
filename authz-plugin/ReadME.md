Creating a Docker Authorization (AuthZ) plugin involves writing a simple API server that listens for requests from Docker and responds with an approval or denial of these requests based on the command and authentication context.

Here’s a sample AuthZ plugin written in **Go**. It will:
- Approve all `GET` requests to Docker.
- Deny all requests to delete containers.
- Approve any other requests by default.

### Prerequisites:
1. **Docker Plugin API knowledge**.
2. **Go Programming Language**.
3. Docker daemon running with the plugin configured.

### Directory Structure:
```plaintext
authz-plugin/
├── authz.go
├── go.mod
├── go.sum
└── Dockerfile
```

### Step 1: `go.mod` File (Go Module)
```go
module authz-plugin

go 1.18

require (
    github.com/docker/docker v20.10.8+incompatible
    github.com/docker/go-plugins-helpers/authorization v0.4.0
)
```

### Step 2: Writing the Plugin (`authz.go`)
```go
package main

import (
	"log"
	"net/http"
	"github.com/docker/go-plugins-helpers/authorization"
)

// AuthZPlugin struct
type AuthZPlugin struct{}

// AuthZRequest function handles authorization requests from Docker
func (p *AuthZPlugin) AuthZReq(req authorization.Request) authorization.Response {
	// Deny DELETE requests for containers
	if req.RequestMethod == "DELETE" && req.RequestURI == "/containers" {
		return authorization.Response{
			Allow: false,
			Msg:   "Deleting containers is not allowed",
		}
	}

	// Approve all GET requests
	if req.RequestMethod == "GET" {
		return authorization.Response{
			Allow: true,
			Msg:   "GET requests are allowed",
		}
	}

	// Default: approve all other requests
	return authorization.Response{
		Allow: true,
		Msg:   "Request approved",
	}
}

// AuthZResponse function is triggered after a Docker request is processed
func (p *AuthZPlugin) AuthZRes(req authorization.Request) authorization.Response {
	// Simply approve all responses
	return authorization.Response{
		Allow: true,
	}
}

func main() {
	plugin := &AuthZPlugin{}
	handler := authorization.NewHandler(plugin)

	log.Println("Starting AuthZ plugin server...")

	if err := handler.ServeUnix("authz-sample-plugin", 0); err != nil {
		log.Fatalf("Failed to start AuthZ plugin: %v", err)
	}
}
```

### Explanation of the Code:
1. **`AuthZPlugin` struct**: Defines a plugin object. All authorization logic is inside this struct.
2. **`AuthZReq` method**: This handles incoming requests from Docker. Based on the request type and URI, it approves or denies requests. Here:
   - `DELETE` on `/containers` is denied.
   - `GET` requests are allowed.
   - Everything else is allowed by default.
3. **`AuthZRes` method**: This handles responses after a Docker request has been processed. In this case, it allows all responses.
4. **`main` function**: Starts the plugin and listens for Docker requests using a Unix socket.

### Step 3: Dockerfile to Build the Plugin
Here’s a Dockerfile to build the AuthZ plugin and package it as a Docker image.

```Dockerfile
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
```

### Step 4: Building and Running the Plugin
1. Build the Docker image for the plugin:
   ```bash
   docker build -t authz-plugin .
   ```

2. Run the AuthZ plugin container:
   ```bash
   docker run -d --name authz-plugin authz-plugin
   ```

3. Install and configure the plugin in Docker (this can vary based on Docker’s plugin management).

### Step 5: Configuring Docker to Use the AuthZ Plugin
To activate the plugin, add the following line to Docker's **daemon.json** configuration file, typically located at `/etc/docker/daemon.json`:

```json
{
  "authorization-plugins": ["authz-sample-plugin"]
}
```

Restart the Docker daemon for the changes to take effect:
```bash
sudo systemctl restart docker
```

### Step 6: Testing the Plugin
You can now test the plugin by performing Docker operations. For example:
- **List containers** (allowed):
  ```bash
  docker ps
  ```

- **Delete a container** (denied):
  ```bash
  docker rm <container_id>
  ```

The plugin will deny the delete request and allow listing containers as specified.

### Final Notes:
- This plugin is basic and can be expanded to handle more complex scenarios like checking the user’s authentication context, specific container operations, or more granular controls.
- The plugin interacts with Docker via a Unix socket, and Docker communicates with it every time a request is made.

Let me know if you'd like to extend or modify this example further!