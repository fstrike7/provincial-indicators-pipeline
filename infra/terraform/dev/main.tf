
# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Public Subnets ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}


# --- Security Group ---
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "dev" {
  name = "${var.project_name}-ecs-dev"
  tags = {
    Environment = "dev"
  }
}
