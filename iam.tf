# --- LAMBDA PERMISSIONS ---
resource "aws_iam_role" "lambda_role" {
  name = "arca_lambda_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_policy" "arca_bedrock_policy" {
  name = "ARCA_Bedrock_Access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Action = "bedrock:InvokeModel", Effect = "Allow", Resource = "arn:aws:bedrock:us-east-1::foundation-model/amazon.nova-micro-v1:0" },
      { Action = ["ssm:SendCommand", "ssm:GetCommandInvocation"], Effect = "Allow", Resource = "*" },
      { Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Effect = "Allow", Resource = "arn:aws:logs:*:*:*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.arca_bedrock_policy.arn
}

# --- EC2 PERMISSIONS ---
resource "aws_iam_role" "ec2_role" {
  name = "arca_ec2_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cw_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "arca_ec2_profile"
  role = aws_iam_role.ec2_role.name
}