# Configure the Azure provider
provider "azurerm" {
  features {}
}
provider "github" {
  token = file("~/Downloads/key/github-token.txt")
}
resource "github_repository_file" "dbendpoint" {
  content             = azurerm_sql_server.phonebook.fully_qualified_domain_name
  file                = "dbserver.endpoint"
  repository          = "terraform-lb-phonebook-app"
  branch              = "main"
  overwrite_on_create = true
}