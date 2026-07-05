# Allow EC2 to assume the role
data "aws_iam_policy_document" "ec2-trust-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role
resource "aws_iam_role" "ec2-readonly-role" {
  name               = "ec2-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.ec2-trust-policy.json

  tags = {
    Environment = "production"
  }
}

# Attach the AWS managed policy that gives read-only access to EC2
resource "aws_iam_role_policy_attachment" "ec2-readonly-attach" {
  role       = aws_iam_role.ec2-readonly-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create the instance profile
resource "aws_iam_instance_profile" "ec2-ecr-readonly-profile" {
  name = "ec2-ecr-readonly-profile"
  role = aws_iam_role.ec2-readonly-role.name
}
