terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_container" "rapido_website" {
  name  = "rapido-website"
  image = "rapido-demo:latest"

  ports {
    internal = 80
    external = 8085
  }

  restart = "unless-stopped"
}
