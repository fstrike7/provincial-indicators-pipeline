# Variables
$REGION = "us-east-1"
$CLUSTER_NAME = "provincial-indicators-ecs-dev"
$VPC_CIDR = "10.0.0.0/16"
$LOG_GROUP = "/ecs/provindicators-api"

Write-Host "==== Eliminando ECS Cluster ===="
$clusterArn = aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query "clusters[0].clusterArn" --output text 2>$null
if ($clusterArn -ne "None") {
    aws ecs delete-cluster --cluster $CLUSTER_NAME --region $REGION
    Write-Host "ECS Cluster eliminado."
} else {
    Write-Host "ECS Cluster no encontrado."
}

Write-Host "==== Eliminando Load Balancers ===="
$albs = aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?contains(LoadBalancerName,'provindicators')].LoadBalancerArn" --output text
if ($albs) {
    foreach ($alb in $albs) {
        Write-Host "Eliminando ALB: $alb"
        aws elbv2 delete-load-balancer --load-balancer-arn $alb --region $REGION
    }
} else {
    Write-Host "No se encontraron ALBs relacionados."
}

Write-Host "==== Eliminando Target Groups ===="
$tgs = aws elbv2 describe-target-groups --region $REGION --query "TargetGroups[?contains(TargetGroupName,'provindicators')].TargetGroupArn" --output text
if ($tgs) {
    foreach ($tg in $tgs) {
        Write-Host "Eliminando Target Group: $tg"
        aws elbv2 delete-target-group --target-group-arn $tg --region $REGION
    }
} else {
    Write-Host "No se encontraron Target Groups relacionados."
}

Write-Host "==== Eliminando Log Group de CloudWatch ===="
$logExists = aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $REGION --query "logGroups[0].logGroupName" --output text 2>$null
if ($logExists -ne "None") {
    aws logs delete-log-group --log-group-name $LOG_GROUP --region $REGION
    Write-Host "Log Group eliminado."
} else {
    Write-Host "Log Group no encontrado."
}

Write-Host "==== Eliminando VPC ===="
$vpcId = aws ec2 describe-vpcs --region $REGION --filters "Name=cidr,Values=$VPC_CIDR" --query "Vpcs[0].VpcId" --output text 2>$null
if ($vpcId -ne "None") {
    # Eliminar Subnets
    $subnets = aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$vpcId" --query "Subnets[].SubnetId" --output text
    foreach ($subnet in $subnets) {
        Write-Host "Eliminando Subnet: $subnet"
        aws ec2 delete-subnet --subnet-id $subnet --region $REGION
    }

    # Eliminar Internet Gateways
    $igws = aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$vpcId" --query "InternetGateways[].InternetGatewayId" --output text
    foreach ($igw in $igws) {
        Write-Host "Desacoplando y eliminando IGW: $igw"
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpcId --region $REGION
        aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $REGION
    }

    # Eliminar Route Tables
    $routeTables = aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$vpcId" --query "RouteTables[].RouteTableId" --output text
    foreach ($rtb in $routeTables) {
        if ($rtb -ne "") {
            Write-Host "Eliminando Route Table: $rtb"
            aws ec2 delete-route-table --route-table-id $rtb --region $REGION
        }
    }

    # Finalmente eliminar VPC
    Write-Host "Eliminando VPC: $vpcId"
    aws ec2 delete-vpc --vpc-id $vpcId --region $REGION
} else {
    Write-Host "No se encontró la VPC con CIDR $VPC_CIDR."
}
