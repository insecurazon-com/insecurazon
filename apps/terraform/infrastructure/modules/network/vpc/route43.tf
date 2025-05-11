# resource "aws_route53_zone" "private_zone" {
#   name = var.domain_name
#   vpc {
#     vpc_id = aws_vpc.this.id
#   }
# }

# output "zone_id" {
#   value = aws_route53_zone.private_zone.id
# }