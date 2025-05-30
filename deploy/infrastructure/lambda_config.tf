locals {
  lambda_config = {
    function_name = "ins-webserver"
    handler = "dist/main.handler"
    runtime = "nodejs22.x"
    vpc_id = module.network_config.vpc_config.main.vpc_config.vpc_id
    subnet_ids = [ module.network_config.vpc_config.main.vpc_config.subnet.main-public-1.id, module.network_config.vpc_config.main.vpc_config.subnet.main-public-2.id ]
    api_gateway_name = "ins-webserver-api"
  }
}