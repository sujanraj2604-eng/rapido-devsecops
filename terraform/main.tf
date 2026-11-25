
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

resource "docker_image" "rapido" {
  name         = "rapido-demo:latest"
  keep_locally = true
}

resource "docker_container" "rapido_website" {
  name  = "rapido-website"
  image = docker_image.rapido.image_id

  ports {
    internal = 80
    external = 8085
  }

  restart = "unless-stopped"
}

