terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  # Hardcoded issuer
  jwt_issuer = "https://sts.windows.net/50bb1d9e-7174-4e06-aecd-e87b1b8c211d/"

  routes_by_key = {
    for r in var.routes :
    "${upper(r.method)} ${r.path}" => {
      path       = r.path
      method     = upper(r.method)
      lambda_arn = r.lambda_arn
    }
  }

  # Split every route path into segments
  route_segs_by_path = {
    for r in var.routes :
    r.path => [for s in split("/", trim(r.path, "/")) : s if s != ""]
  }

  # Build ALL intermediate paths for all routes (e.g. /a, /a/b, /a/b/c)
  all_resource_paths = toset(flatten([
    for p, segs in local.route_segs_by_path : [
      for i in range(1, length(segs) + 1) : "/${join("/", slice(segs, 0, i))}"
    ]
  ]))

  # Map full resource path -> segment array
  segs_by_resource_path = {
    for p in local.all_resource_paths :
    p => [for s in split("/", trim(p, "/")) : s if s != ""]
  }

  # Group resource paths by depth (up to depth 6)
  paths_by_depth = {
    1 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 1]
    2 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 2]
    3 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 3]
    4 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 4]
    5 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 5]
    6 = [for p, segs in local.segs_by_resource_path : p if length(segs) == 6]
  }
}

resource "aws_api_gateway_rest_api" "this" {
  name   = var.name
  policy = data.aws_iam_policy_document.rest_api_policy.json
}

locals {
  root_id = aws_api_gateway_rest_api.this.root_resource_id
}

# ----------------------------
# API Gateway Resources (paths)
# Supports paths up to depth 6
# ----------------------------

resource "aws_api_gateway_resource" "path_level_1" {
  for_each = toset(lookup(local.paths_by_depth, 1, []))

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = local.root_id
  path_part   = local.segs_by_resource_path[each.value][0]
}

resource "aws_api_gateway_resource" "path_level_2" {
  for_each = toset(lookup(local.paths_by_depth, 2, []))

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.path_level_1[
    "/${local.segs_by_resource_path[each.value][0]}"
  ].id

  path_part = local.segs_by_resource_path[each.value][1]
}

resource "aws_api_gateway_resource" "path_level_3" {
  for_each = toset(lookup(local.paths_by_depth, 3, []))

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.path_level_2[
    "/${join("/", slice(local.segs_by_resource_path[each.value], 0, 2))}"
  ].id

  path_part = local.segs_by_resource_path[each.value][2]
}

resource "aws_api_gateway_resource" "path_level_4" {
  for_each = toset(lookup(local.paths_by_depth, 4, []))

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.path_level_3[
    "/${join("/", slice(local.segs_by_resource_path[each.value], 0, 3))}"
  ].id

  path_part = local.segs_by_resource_path[each.value][3]
}

resource "aws_api_gateway_resource" "path_level_5" {
  for_each = toset(lookup(local.paths_by_depth, 5, []))

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.path_level_4[
    "/${join("/", slice(local.segs_by_resource_path[each.value], 0, 4))}"
  ].id

  path_part = local.segs_by_resource_path[each.value][4]
}
