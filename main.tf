# The domain name to use with api-gateway


resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
}


resource "aws_api_gateway_domain_name" "domain_name" {
  domain_name = "${var.sub_domain}.${var.root_domain}"
  regional_certificate_arn = aws_acm_certificate.cert.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }


  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "aws_route53_record" "sub_domain" {
  name    = var.sub_domain
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = aws_api_gateway_domain_name.domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "cert" {
  # api-gateway / cloudfront certificates need to use the us-east-1 region
  domain_name       = "${var.sub_domain}.${var.root_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  name    = "${tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name}"
  type    = "${tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type}"
  zone_id = var.zone_id
  records = ["${tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  # api-gateway / cloudfront certificates need to use the us-east-1 region

  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]

  timeouts {
    create = "45m"
  }
}

resource "aws_api_gateway_base_path_mapping" "example" {
  api_id      = var.api_id
  stage_name  = var.stage_name
  domain_name = aws_api_gateway_domain_name.domain_name.domain_name
}
