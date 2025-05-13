# variable "cluster_name" {
#   description = "Name of the EKS cluster"
#   type        = string
# }

# variable "tags" {
#   description = "A map of tags to add to all resources"
#   type        = map(string)
#   default     = {}
# } 

variable "iam_eks" {
  description = "IAM configuration for EKS"
  type = object({
    cluster_name = string
    fargate_enabled = bool
    node_enabled = bool
    tags = map(string)
  })
}