data "aws_iam_policy_document" "authorizer_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "authorizer_role" {
  name               = "${var.name}-authorizer-role"
  assume_role_policy = data.aws_iam_policy_document.authorizer_assume_role.json
}

resource "aws_iam_role_policy_attachment" "authorizer_basic" {
  role       = aws_iam_role.authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
