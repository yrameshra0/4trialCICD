resource "aws_instance" "control_hub" {
  ami                    = "ami-0df5449aa8454babe"
  instance_type          = "t2.micro"
  key_name               = "4trial_infra"
  subnet_id              = aws_subnet.public_sn_1.id
  vpc_security_group_ids = [aws_security_group.public_limited_sg.id]

  # Key file copy
  # Key file copy
  provisioner "file" {
    source      = "../4trial_infra.pem"
    destination = "/tmp/4trial_infra.pem"
  }

  # Ansible files copy
  # Ansible files copy
  provisioner "file" {
    source      = "../ansible"
    destination = "/tmp/"
  }

  # Docker compose files copy
  # Docker compose files copy
  provisioner "file" {
    source      = "../compose"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/4trial_infra.pem",
      "sudo mv /tmp/4trial_infra.pem /home/ubuntu/",
      "sudo mv /tmp/ansible /home/ubuntu",
      "sudo mv /tmp/compose /home/ubuntu",
      "sudo mv /home/ubuntu/ansible/dynamic_inventory/ec2.py /etc/ansible/hosts",
      "sudo chmod +x /etc/ansible/hosts",
      "sudo mv /home/ubuntu/ansible/dynamic_inventory/ec2.ini /etc/ansible/",
      "export ANSIBLE_HOST_KEY_CHECKING=False",
      "sleep 180",
      "ansible-playbook ./ansible/docker_swarm_setup.yml --private-key 4trial_infra.pem",
    ]
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("../4trial_infra.pem")
  }

  tags = {
    Name = "control_hub"
  }
}

output "ip" {
  value = "\n\r Control Hub - ${aws_instance.control_hub.public_ip}"
}

resource "aws_instance" "minions_1a" {
  ami                    = "ami-0df5449aa8454babe"
  instance_type          = "t2.micro"
  key_name               = "4trial_infra"
  count                  = 1
  subnet_id              = aws_subnet.private_sn_1.id
  vpc_security_group_ids = [aws_security_group.private_dmz_sg.id]

  tags = {
    Name = "minions"
    Role = "cortana"
  }
}

resource "aws_instance" "minions_1b" {
  ami                    = "ami-0df5449aa8454babe"
  instance_type          = "t2.micro"
  key_name               = "4trial_infra"
  count                  = 1
  subnet_id              = aws_subnet.private_sn_2.id
  vpc_security_group_ids = [aws_security_group.private_dmz_sg.id]

  tags = {
    Name = "minions"
    Role = "masterChief"
  }
}

# Volume created manually for avoiding failing on destroying infra
resource "aws_volume_attachment" "persistent_data_attachment_1a" {
  device_name  = "/dev/sdh"
  volume_id    = "vol-0f210428128e9a96d"
  instance_id  = aws_instance.minions_1a[0].id
  force_detach = true
}

resource "aws_lb_target_group_attachment" "root_tga_1a" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[0].arn
  target_id        = element(aws_instance.minions_1a.*.id, count.index)
  port             = 10000
}

resource "aws_lb_target_group_attachment" "prod_tga_1a" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[1].arn
  target_id        = element(aws_instance.minions_1a.*.id, count.index)
  port             = 11000
}

resource "aws_lb_target_group_attachment" "test_tga_1a" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[2].arn
  target_id        = element(aws_instance.minions_1a.*.id, count.index)
  port             = 12000
}


resource "aws_lb_target_group_attachment" "root_tga_1b" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[0].arn
  target_id        = element(aws_instance.minions_1b.*.id, count.index)
  port             = 10000
}

resource "aws_lb_target_group_attachment" "prod_tga_1b" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[1].arn
  target_id        = element(aws_instance.minions_1b.*.id, count.index)
  port             = 11000
}

resource "aws_lb_target_group_attachment" "test_tga_1b" {
  count            = 1
  target_group_arn = aws_alb_target_group.alb_targets[2].arn
  target_id        = element(aws_instance.minions_1b.*.id, count.index)
  port             = 12000
}

