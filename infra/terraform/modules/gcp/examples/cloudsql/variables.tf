# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "fawkes-example"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "fawkes-db"
}

variable "database_version" {
  description = "Database version (e.g., POSTGRES_15, MYSQL_8_0)"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine tier for the instance"
  type        = string
  default     = "db-custom-2-7680"
}

variable "availability_type" {
  description = "Availability type (REGIONAL or ZONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "private_network" {
  description = "VPC network ID for private IP"
  type        = string
  default     = null
}

variable "database_flags" {
  description = "Database-specific flags for tuning"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = ["fawkesdb"]
}

variable "users" {
  description = "List of database users to create"
  type = list(object({
    name     = string
    password = optional(string, null)
    type     = optional(string, "BUILT_IN")
    host     = optional(string, "%")
  }))
  default = [
    {
      name = "dbadmin"
    }
  ]
}
