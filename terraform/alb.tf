resource "aws_alb" "applb" {
  name            = "applb"
  internal        = false
  security_groups = ["${aws_security_group.public_limited_sg.id}"]
  subnets         = ["${aws_subnet.public_sn_1.id}", "${aws_subnet.public_sn_2.id}"]

  tags {
    Name = "Docker Swarm Application Load Balancer"
  }
}

resource "aws_alb_target_group" "alb_targets" {
  count    = "${length(keys(var.services_map))}"
  name     = "${element(values(var.services_map), count.index)}"
  port     = "${element(keys(var.services_map), count.index)}"
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.cloud_den.id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/healthcheck"
  }
}

resource "aws_alb_listener" "alb_listener" {
  count             = "1"
  load_balancer_arn = "${aws_alb.applb.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${element(aws_alb_target_group.alb_targets.*.arn, 0)}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "test_rule" {
  listener_arn = "${aws_alb_listener.alb_listener.arn}"
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb_targets.2.arn}"
  }

  condition {
    field  = "host-header"
    values = ["*.test.*"]
  }
}

resource "aws_alb_listener_rule" "prod_rule" {
  listener_arn = "${aws_alb_listener.alb_listener.arn}"
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.alb_targets.1.arn}"
  }

  condition {
    field  = "host-header"
    values = ["*.prod.*"]
  }
}

resource "aws_route53_record" "test_record" {
  zone_id = "Z3MGCVRBTR7Y94"
  name    = "*.test"
  type    = "A"

  alias {
    name                   = "${aws_alb.applb.dns_name}"
    zone_id                = "${aws_alb.applb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "prod_record" {
  zone_id = "Z3MGCVRBTR7Y94"
  name    = "*.prod"
  type    = "A"

  alias {
    name                   = "${aws_alb.applb.dns_name}"
    zone_id                = "${aws_alb.applb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cicd_record" {
  zone_id = "Z3MGCVRBTR7Y94"
  name    = "cicd.4trial.net"
  type    = "A"

  alias {
    name                   = "${aws_alb.applb.dns_name}"
    zone_id                = "${aws_alb.applb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_record" {
  zone_id = "Z3MGCVRBTR7Y94"
  name    = "4trial.net"
  type    = "A"

  alias {
    name                   = "${aws_alb.applb.dns_name}"
    zone_id                = "${aws_alb.applb.zone_id}"
    evaluate_target_health = false
  }
}
