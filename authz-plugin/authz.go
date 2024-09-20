package main

import (
	"log"

	"github.com/docker/go-plugins-helpers/authorization"
)

// AuthZPlugin struct
type AuthZPlugin struct{}

// AuthZReq function handles authorization requests from Docker
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

// AuthZRes function is triggered after a Docker request is processed
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
