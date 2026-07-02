prefix   = "neur"
location = "centralus"

create_secondary_region = false
secondary_location      = "eastus2"

containers = {
  app1 = {
    image  = "docker.io/library/nginx:latest"
    cpu    = 0.5
    memory = 0.5
    port   = 80
  }

  app2 = {
    image  = "docker.io/library/httpd:latest"
    cpu    = 0.5
    memory = 1.0
    port   = 80
  }
}