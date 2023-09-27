
resource "aws_vpc" "my_new_vpc" {
  cidr_block = var.cidr
  tags = {
    Name = "Vpc_sep24"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_new_vpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.my_new_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "new_sep24"
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}


// Mapping Subnet to 1a zone
resource "aws_subnet" "sub1" {

  vpc_id     = aws_vpc.my_new_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "web-1"
  }
}

// Mapping subnet to 1b zone
resource "aws_subnet" "sub2" {

  vpc_id            = aws_vpc.my_new_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "web-2"
  }

}

//Creating Security Group
resource "aws_security_group" "web_sg" {

  name        = var.sg_name
  description = var.sg_description
  vpc_id      = aws_vpc.my_new_vpc.id

  ingress {
    description = "SSH"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS"
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "new_sg_sep24"
  }

}

//Creating instance for 1a Zone
resource "aws_instance" "web_1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.sub1.id

  tags = {
    Name = var.tags
  }

}
//Creating instance for 1b Zone
resource "aws_instance" "web_2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.sub2.id

  tags = {
    Name = var.tag
  }

}
################## Create EFS File system ################
resource "aws_efs_file_system" "file_system_1" {
  creation_token   = "efs_sep24"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Name = "efs_sep24"
  }
}

resource "aws_efs_mount_target" "mount_targets_1" {
  count           = 1
  file_system_id  = aws_efs_file_system.file_system_1.id
  #vpc_id            = aws_vpc.my_new_vpc.id
  subnet_id       = aws_subnet.sub1.id
  security_groups = [aws_security_group.web_sg.id]
}

resource "aws_efs_mount_target" "mount_targets_2" {
  count           = 1
  file_system_id  = aws_efs_file_system.file_system_1.id
  #vpc_id            = aws_vpc.my_new_vpc.id
  subnet_id       = aws_subnet.sub2.id
  security_groups = [aws_security_group.web_sg.id]
}

# Creating Mount Point for EFS
resource "null_resource" "configure_nfs" {
  depends_on = [aws_efs_mount_target.mount_targets_1]
  connection {
#    type    = "ssh"
    user    = "root"
    private_key = file(var.private_key)
    host    = aws_instance.web_1.public_ip
    timeout = "20s"
  }


provisioner "remote-exec" {
  inline = [

     aws_vpc.my_new_vpc.id,
     aws_instance.web_1.public_ip,
    "sudo -i",
    "yum install -y amazon-efs-utils",
    "sleep 15",
    "systemctl start nfs-server",
    "systemctl status nfs-server",
    "sleep 15",
    "mkdir /efs_sep24",
    "mount -t efs -o tls ${aws_efs_file_system.file_system_1.dns_name}:/ /efs_sep24",

    #    # Mounting Efs
    #    "sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.file_system_1.dns_name}:/  /var/www/html",
    #    "sleep 15",
    #    "sudo chmod go+rw /var/www/html",
    #    "sudo bash -c 'echo Welcome  > /var/www/html/index.html'",
  ]
}
}



