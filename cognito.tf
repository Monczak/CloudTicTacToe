resource "aws_cognito_user_pool" "cloudtictactoe_user_pool" {
  name = "Cloud Tic Tac Toe User Pool"

  mfa_configuration = "OFF"

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
  }

  auto_verified_attributes = [ "email" ]
}

resource "aws_cognito_user_pool_client" "cloudtictactoe_cognito_client" {
  user_pool_id = aws_cognito_user_pool.cloudtictactoe_user_pool.id
  name = "Cloud Tic Tac Toe"

  explicit_auth_flows = [ "ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH" ]
}