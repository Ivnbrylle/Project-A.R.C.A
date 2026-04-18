resource "aws_security_group" "arca_sg" {
  name   = "arca_security_group"
  vpc_id = aws_default_vpc.default.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "arca_target" {
  ami                         = "ami-0c101f26f147fa7fd" # Amazon Linux 2023
  instance_type               = "t3.micro"
  subnet_id                   = aws_default_subnet.default_az1.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids      = [aws_security_group.arca_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y nginx amazon-cloudwatch-agent
              systemctl start nginx
              systemctl enable nginx
              cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
              {
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/nginx/error.log",
                          "log_group_name": "/aws/ec2/nginx-logs",
                          "log_stream_name": "{instance_id}",
                          "retention_in_days": 7
                        }
                      ]
                    }
                  }
                }
              }
              EOT
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
              EOF

  tags = {
    Name = "ARCA-Target-Server"
  }
}