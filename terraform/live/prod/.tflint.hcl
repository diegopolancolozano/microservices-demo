rule "terraform_unused_declarations" {
  enabled = true
  exclude = ["rate_limit_per_minute", "circuit_breaker_timeout_seconds"]
}