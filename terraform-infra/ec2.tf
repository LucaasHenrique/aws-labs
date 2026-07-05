resource "aws_instance" "website_server" {
  ami                  = "ami-06067086cf86c58e6"
  instance_type        = "t3.micro"
  key_name             = aws_key_pair.instance_key.key_name
  vpc_security_group_ids      = [aws_security_group.website_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2-ecr-readonly-profile.name

  tags = {
    Name        = "website_server"
    Provisioned = "Terraform"
    Cliente     = "Lucas"
  }
}
