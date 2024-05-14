# resource "aws_cognito_user_pool" "cloudtictactoe_user_pool" {
#   name = "Cloud Tic Tac Toe User Pool"
# }

# resource "aws_cognito_user_pool_client" "cloudtictactoe_cognito_client" {
#   user_pool_id = aws_cognito_user_pool.cloudtictactoe_user_pool.id
#   name = "Cloud Tic Tac Toe"
# }