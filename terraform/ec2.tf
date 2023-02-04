#
locals {
  instance_name_prefix = "${var.environment}-"
  tags = merge(var.extra_tags,
    {
      Clique    = trimsuffix(local.instance_name_prefix, "-")
      App       = "alephium"
      Component = "broker"
    })
  key_name = "${var.environment}-rsa-${random_string.random_suffix.result}"
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "random_string" "random_suffix" {
  length  = 4
  special = false
  upper   = false
}

module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  key_name   = local.key_name
  public_key = tls_private_key.this.public_key_openssh
  tags = merge(
    { "Name" = local.key_name },
    var.extra_tags
  )
}

resource "local_sensitive_file" "pem_file" {
  filename          = pathexpand("${path.root}/${module.key_pair.key_pair_name}.pem")
  file_permission   = "600"
  content = tls_private_key.this.private_key_pem
}

resource "aws_instance" "instance" {
  count                       = var.instance_count
  ami                         = data.aws_ami.ubuntu-jammy.id
  instance_type               = var.instance_type
  subnet_id                   = element(module.vpc.public_subnets, count.index)
  associate_public_ip_address = true
  key_name                    = local.key_name

  vpc_security_group_ids = [aws_security_group.alephium_broker_ssh.id, aws_security_group.alephium_broker_protocol.id]

  tags = merge(
    { "Name" = "${local.instance_name_prefix}${count.index + var.offset_shift}" },
    var.extra_tags
  )

  volume_tags = merge(
    { "Name" = "${local.instance_name_prefix}${count.index + var.offset_shift}" },
    var.extra_tags
  )

  user_data = element(data.template_file.cloud_init, count.index).rendered

  //  # see https://github.com/hashicorp/terraform/issues/1260#issuecomment-261068928
  lifecycle {
    ignore_changes = [ebs_block_device, ami, ebs_optimized]
  }
}

resource "aws_volume_attachment" "volume" {
  count       = var.ebs_block_device_size > 0 ? var.instance_count : 0
  device_name = "/dev/sdh"
  volume_id   = element(aws_ebs_volume.volume, count.index).id
  instance_id = element(aws_instance.instance, count.index).id
}

resource "aws_ebs_volume" "volume" {
  count             = var.ebs_block_device_size > 0 ? var.instance_count : 0
  availability_zone = element(aws_instance.instance, count.index).availability_zone
  size              = var.ebs_block_device_size
  encrypted         = true
  type              = var.ebs_block_device_type
  tags = merge(
    { "Name" = "${local.instance_name_prefix}${count.index + var.offset_shift}" },
    var.extra_tags
  )
  lifecycle {
    ignore_changes = [availability_zone]
  }
}

data "template_file" "cloud_init" {
  count    = var.instance_count
  template = file("${path.module}/templates/cloud-init.tpl")
  vars = {
    instance_name               = "${local.instance_name_prefix}${count.index + var.offset_shift}"
    with_data_volume            = var.ebs_block_device_size > 0
  }
}

data "template_file" "docker_compose" {
  count    = var.instance_count
  template = file("${path.module}/templates/docker-compose.yml.tpl")
  vars = {
    alephium_image = var.alephium_image
  }
}


resource "null_resource" "broker-config" {

  count = var.instance_count
  triggers = {
    docker_compose  = element(data.template_file.docker_compose, count.index).rendered
    increment       = 1
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = element(aws_instance.instance, count.index).public_ip
    private_key = tls_private_key.this.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /data/alephium/alephium-data /data/alephium/alephium-wallets",
      "sudo chown ubuntu /data/alephium /data/alephium/alephium-data", // to allow provisioner to copy files
      "sudo chmod 777 /data/alephium/alephium-data /data/alephium/alephium-wallets"
    ]
  }

  provisioner "file" {
    content     = element(data.template_file.docker_compose, count.index).rendered
    destination = "/data/alephium/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -fr /data/alephium/alephium-data/mainnet/user.conf",
      "while [ ! -f /usr/bin/docker-compose ]; do echo 'waiting for docker-compose to get installed'; sleep 5; done",
      "while [ ! -S /run/docker.sock ]; do echo 'waiting for docker to start'; sleep 5; done",
      "cd /data/alephium && sudo /usr/bin/docker-compose up -d --remove-orphans",
      "sudo iptables -L | grep RATE-LIMIT || (sudo iptables --new-chain RATE-LIMIT; sudo iptables --append RATE-LIMIT --match limit --limit 500/sec --limit-burst 350 --jump RETURN; sudo iptables --append RATE-LIMIT --match limit --limit 1/sec --limit-burst 10 --jump LOG --log-prefix 'IPTables-Rejected: '; sudo iptables --append RATE-LIMIT --jump REJECT; sudo iptables --insert DOCKER-USER --match conntrack --ctstate NEW --jump RATE-LIMIT)"
    ]
  }
}
