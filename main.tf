module "default_label" {
  source      = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.19.2"
  namespace   = var.namespace
  stage       = var.stage
  environment = var.environment
  name        = var.name
  delimiter   = var.delimiter
  attributes  = var.attributes
  tags        = var.tags
  enabled     = var.enabled
}

resource "aws_appautoscaling_target" "read_target" {
  count              = var.enabled ? 1 : 0
  max_capacity       = var.autoscale_max_read_capacity
  min_capacity       = var.autoscale_min_read_capacity
  resource_id        = "table/${var.dynamodb_table_name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "read_target_index" {
  for_each           = var.enabled ? var.dynamodb_indexes : {}
  max_capacity       = lookup(each.value, "max_read_capacity", var.autoscale_max_read_capacity)
  min_capacity       = lookup(each.value, "min_read_capacity", var.autoscale_min_read_capacity)
  resource_id        = "table/${var.dynamodb_table_name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read_policy" {
  count       = var.enabled ? 1 : 0
  name        = "DynamoDBReadCapacityUtilization:${join("", aws_appautoscaling_target.read_target.*.resource_id)}"
  policy_type = "TargetTrackingScaling"
  resource_id = join("", aws_appautoscaling_target.read_target.*.resource_id)

  scalable_dimension = join("", aws_appautoscaling_target.read_target.*.scalable_dimension)
  service_namespace  = join("", aws_appautoscaling_target.read_target.*.service_namespace)

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.autoscale_read_target
  }
}

resource "aws_appautoscaling_policy" "read_policy_index" {
  for_each = var.enabled ? var.dynamodb_indexes : {}

  name = "DynamoDBReadCapacityUtilization:${
    aws_appautoscaling_target.read_target_index[each.key].resource_id
  }"

  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target_index[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target_index[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target_index[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = var.autoscale_read_target
  }
}

resource "aws_appautoscaling_target" "write_target" {
  count              = var.enabled ? 1 : 0
  max_capacity       = var.autoscale_max_write_capacity
  min_capacity       = var.autoscale_min_write_capacity
  resource_id        = "table/${var.dynamodb_table_name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "write_target_index" {
  for_each           = var.enabled ? var.dynamodb_indexes : {}
  max_capacity       = lookup(each.value, "max_write_capacity", var.autoscale_max_write_capacity)
  min_capacity       = lookup(each.value, "min_write_capacity", var.autoscale_min_write_capacity)
  resource_id        = "table/${var.dynamodb_table_name}/index/${each.key}"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write_policy" {
  count       = var.enabled ? 1 : 0
  name        = "DynamoDBWriteCapacityUtilization:${join("", aws_appautoscaling_target.write_target.*.resource_id)}"
  policy_type = "TargetTrackingScaling"
  resource_id = join("", aws_appautoscaling_target.write_target.*.resource_id)

  scalable_dimension = join("", aws_appautoscaling_target.write_target.*.scalable_dimension)
  service_namespace  = join("", aws_appautoscaling_target.write_target.*.service_namespace)

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.autoscale_write_target
  }
}

resource "aws_appautoscaling_policy" "write_policy_index" {
  for_each = var.enabled ? var.dynamodb_indexes : {}

  name = "DynamoDBWriteCapacityUtilization:${
    aws_appautoscaling_target.write_target_index[each.key].resource_id
  }"

  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target_index[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target_index[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target_index[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = var.autoscale_write_target
  }
}
