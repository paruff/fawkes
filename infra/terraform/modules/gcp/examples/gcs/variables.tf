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

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  type        = string
  default     = "fawkes-data-example"
}

variable "location" {
  description = "GCS bucket location"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "Cloud KMS key name for encryption"
  type        = string
  default     = null
}

variable "enable_cors" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "iam_members" {
  description = "IAM members to add to the bucket"
  type = list(object({
    role   = string
    member = string
    condition = optional(object({
      title       = string
      description = string
      expression  = string
    }), null)
  }))
  default = []
}
