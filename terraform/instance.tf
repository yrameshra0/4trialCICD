resource "aws_instance" "control_hub" {
  ami                    = "ami-0d773a3b7bb2bb1c1"
  instance_type          = "t2.micro"
  key_name               = "<YOUR PEM KEY DETAILS>"
  subnet_id              = "${aws_subnet.public_sn_1.id}"
  vpc_security_group_ids = ["${aws_security_group.public_limited_sg.id}"]

  # Key file copy
  provisioner "file" {
    source      = "../<YOUR PEM KEY DETAILS>.pem"
    destination = "/tmp/<YOUR PEM KEY DETAILS>.pem"
  }

  # Ansible files copy
  provisioner "file" {
    source      = "../ansible"
    destination = "/tmp/"
  }

  # Docker compose files copy
  provisioner "file" {
    source      = "../compose"
    destination = "/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt -y update",
      "sudo apt-get -y install software-properties-common",
      "sudo apt-add-repository -y ppa:ansible/ansible",
      "sudo apt-get -y update",
      "sudo apt-get -y install ansible",
      "sudo apt-get -y install python-pip",
      "sudo pip install 'boto==2.46.1'",
      "sudo chmod 400 /tmp/<YOUR PEM KEY DETAILS>.pem",
      "sudo mv /tmp/<YOUR PEM KEY DETAILS>.pem /home/ubuntu/",
      "sudo mv /tmp/ansible /home/ubuntu",
      "sudo mv /tmp/compose /home/ubuntu",
      "sudo mv /home/ubuntu/ansible/dynamic_inventory/ec2.py /etc/ansible/hosts",
      "sudo chmod +x /etc/ansible/hosts",
      "sudo mv /home/ubuntu/ansible/dynamic_inventory/ec2.ini /etc/ansible/",
      "export ANSIBLE_HOST_KEY_CHECKING=False",
      "sleep 180",
      "ansible-playbook ./ansible/docker_swarm_setup.yml --private-key <YOUR PEM KEY DETAILS>.pem",
    ]
  }

  connection {
    user        = "ubuntu"
    private_key = "${file("../<YOUR PEM KEY DETAILS>.pem")}"
  }

  tags {
    Name = "control_hub"
  }
}

output "ip" {
  value = "\n\r Control Hub - ${aws_instance.control_hub.public_ip}"
}

resource "aws_instance" "minions_1a" {
  ami                    = "ami-0d773a3b7bb2bb1c1"
  instance_type          = "t2.micro"
  key_name               = "<YOUR PEM KEY DETAILS>"
  count                  = 1
  subnet_id              = "${aws_subnet.private_sn_1.id}"
  vpc_security_group_ids = ["${aws_security_group.private_dmz_sg.id}"]

  tags {
    Name = "minions"
  }
}

# Volume created manually for avoiding failing on destroying infra
resource "aws_volume_attachment" "persistent_data_attachment" {
  device_name  = "/dev/sdh"
  volume_id    = "<EBS VOLUME ID>"
  instance_id  = "${aws_instance.minions_1a.id}"
  force_detach = true
}

resource "aws_lb_target_group_attachment" "root_tga_1a" {
  count            = 1
  target_group_arn = "${aws_alb_target_group.alb_targets.0.arn}"
  target_id        = "${element(aws_instance.minions_1a.*.id, count.index)}"
  port             = 10000
}

resource "aws_lb_target_group_attachment" "prod_tga_1a" {
  count            = 1
  target_group_arn = "${aws_alb_target_group.alb_targets.1.arn}"
  target_id        = "${element(aws_instance.minions_1a.*.id, count.index)}"
  port             = 11000
}

resource "aws_lb_target_group_attachment" "test_tga_1a" {
  count            = 1
  target_group_arn = "${aws_alb_target_group.alb_targets.2.arn}"
  target_id        = "${element(aws_instance.minions_1a.*.id, count.index)}"
  port             = 12000
}
