provider "aws" {
  region = "ap-south-1"
  profile = "abhi"
}

// ------------------------------------

resource "tls_private_key" "mykey" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "mykey"
  public_key = "${tls_private_key.mykey.public_key_openssh}"


  depends_on = [
    tls_private_key.mykey
  ]
}

resource "local_file" "key-file" {
  content  = "${tls_private_key.mykey.private_key_pem}"
  filename = "mykey.pem"


  depends_on = [
    tls_private_key.mykey
  ]
}


//----------------------------------

resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "abhivpc"
  }
}


//---------------------------------


resource "aws_security_group" "sec_grp" {
  name        = "sec_grp"
  description = "Allows SSH and HTTP"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
 
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "TCP"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sec_grp"
  }
}


//-------------------------------------


resource "aws_subnet" "abhisubnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
 
  
  tags = {
    Name = "abhisubnet1"
  }
}


//--------------------------


resource "aws_subnet" "abhisubnet2" {    
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
 
  
  tags = {
    Name = "abhisubnet2"
  }
}

//---------------------------------


resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "abhigateway"
  }
}

//-----------------------------------


resource "aws_route_table" "route" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "abhiroute"
  }
}


//--------------------------------------


resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.abhisubnet1.id
  route_table_id = aws_route_table.route.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.abhisubnet2.id
  route_table_id = aws_route_table.route.id
}


//------------------------------


resource "aws_instance" "os1" {
	ami = "ami-7e257211"
	instance_type = "t2.micro"
	key_name = aws_key_pair.generated_key.key_name
	vpc_security_group_ids = [aws_security_group.sec_grp.id]
    subnet_id = "${aws_subnet.abhisubnet1.id}"
tags = {
	Name = "AbhiWpOs"
	}
   }


//-----------------------

resource "aws_instance" "os2" {
	ami = "ami-08706cb5f68222d09"
	instance_type = "t2.micro"
	key_name = aws_key_pair.generated_key.key_name
	vpc_security_group_ids = [aws_security_group.sec_grp.id]
     subnet_id = "${aws_subnet.abhisubnet2.id}"
tags = {
	Name = "AbhiMysqlOs"
	}
   }




