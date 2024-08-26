resource "aws_ecr_repository" "app" {
  name = "app"
  force_delete = "true"
}