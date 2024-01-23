# variables.tf

# Azure subscription Id
variable "subscription_id" {
  description = "Azure subscription Id"
  type        = string
  sensitive   = true
  default     = "3542213f-7e7a-4dad-aea4-fe30482ed0f3"
}
# Azure tenant Id
variable "tenant_id" {
  description = "Azure tenant Id"
  type        = string
  sensitive   = true
  default     = "47d4542c-f112-47f4-92c7-a838d8a5e8ef"
}

# Secret Env Var default values maintained for clarity during development

# client-id to reference env var TF_VAR_client_id 
variable "client_id" {
  description = "Provider Client Id"
  type        = string
  sensitive   = true
  # default   = "c2fc7959-d7b4-4f23-827f-fe6c59827bce"
}
# client-secret to reference env var TF_VAR_client_secret
variable "client_secret" {
  description = "Provider Client Secret"
  type        = string
  sensitive   = true
  # default   = "Ik98Q~ZObrT3fs_SnHOOJoW~I6II9NkuQ~1W9dx6"
}

# Remove defaults from production, when env var are defined

# Set env var:
# setx TF_VAR_client_id client_id /m
# In our case:
# setx TF_VAR_client_id "c2fc7959-d7b4-4f23-827f-fe6c59827bce" /m
# setx TF_VAR_client_secret client_secret /m
# In our case:
# setx TF_VAR_client_secret "Ik98Q~ZObrT3fs_SnHOOJoW~I6II9NkuQ~1W9dx6" /m

# Remember to restart shell after setting to view the vars

# Check env var set:
# $env:TF_VAR_client_id
# or, to view all env vars:
# Get-ChildItem env:

# To delete env var:
# [Environment]::SetEnvironmentVariable("TF_VAR_user_name", $null, "Machine")

