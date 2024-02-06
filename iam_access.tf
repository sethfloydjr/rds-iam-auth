
# Create a user
resource "aws_iam_user" "john_smith" {
  name = "john.smith"
  path = "/"
}

# Give the new user some keys
resource "aws_iam_access_key" "john_smith_access_key" {
  user = aws_iam_user.john_smith.name
}


#We are giving our developers PowerUser access because we trust them so much.
resource "aws_iam_user_policy_attachment" "developer_attachment" {
  user       = aws_iam_user.john_smith.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
