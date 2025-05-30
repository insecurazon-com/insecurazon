variable "peering_config" {
  type = object({
    peering_name = string
    vpc_id = string
    peer_vpc_id = string
    tags = map(string)
  })
}