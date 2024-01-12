output "bedrock_role" {
  value = aws_iam_role.bedrock.arn
}

#output "collection_enpdoint" {
#  value = aws_opensearchserverless_collection.collection.collection_endpoint
#}

#output "dashboard_endpoint" {
# value = aws_opensearchserverless_collection.collection.dashboard_endpoint
#}

#output "ecr_repository" {
# value = aws_ecr_repository.bedrock.arn
#}