locals {
  lambda_config = {
    function_name = "ins-webserver"
    handler = "dist/main.handler"
    runtime = "nodejs22.x"
    vpc_id = module.network_config.vpc_config.egress.vpc_config.vpc_id
    subnet_ids = [ module.network_config.vpc_config.egress.vpc_config.subnet.egress-public.id ]
    api_gateway_name = "ins-webserver-api"
  }
}