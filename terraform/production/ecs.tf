//locals {
//  redis_node = aws_elasticache_cluster.this.cache_nodes.0
//}

# Task definition

data "template_file" "container_definitions" {
  template = file("${path.module}/templates/container_definitions.json")

  vars = {
    project_name = module.variables.project_name
    environment  = module.variables.environment
    server_name  = module.variables.server_name
    app_port     = module.variables.app_port

    web_server_ecr_repo = module.main.ecr_repositories.web_server.repository_url
    app_ecr_repo        = module.main.ecr_repositories.app.repository_url

    log_group  = module.main.aws_cloudwatch_log_group.name
    log_region = module.variables.region

    db_host     = aws_db_instance.this.address
    db_username = aws_db_instance.this.username
    db_password = aws_db_instance.this.password

//    redis_url = "redis://${local.redis_node.address}:${local.redis_node.port}"
  }
}

resource "aws_ecs_task_definition" "this" {
  family       = module.variables.project_name_env
  network_mode = "bridge"
  cpu          = module.variables.task_cpu
  memory       = module.variables.task_memory

  container_definitions = data.template_file.container_definitions.rendered

  volume {
    name = "public"
  }
}

## Service

resource "aws_ecs_service" "this" {
  name                               = module.variables.project_name_env
  cluster                            = module.ecs_cluster.cluster.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = module.variables.min_task_count
  deployment_minimum_healthy_percent = module.variables.deployment_minimum_healthy_percent
  deployment_maximum_percent         = module.variables.deployment_maximum_percent

  load_balancer {
    container_name   = "web-server"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.this.arn
  }

  depends_on = [
    module.global.ecs_instance_iam_role
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
