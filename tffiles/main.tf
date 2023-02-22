# Configure the Azure provider
provider "azurerm" {
  features {}
}
provider "github" {
  token = file("~/Downloads/key/github-token.txt")
}
resource "github_repository_file" "dbendpoint" {
  content             = azurerm_mysql_flexible_server.example.fqdn
  file                = "dbserver.endpoint"
  repository          = "terraform-lb-phonebook-app"
  branch              = "main"
  overwrite_on_create = true
}