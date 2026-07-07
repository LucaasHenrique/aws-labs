resource "aws_key_pair" "instance_key" {
  key_name   = "site-server-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
