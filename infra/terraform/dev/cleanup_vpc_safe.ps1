param(
    [string]$VpcId = ""
)

# 1. Determinar VPC automáticamente si no se pasa como parámetro
if (-not $VpcId) {
    $VpcId = aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text
    Write-Host "Se seleccionó automáticamente la VPC: $VpcId"
}

if (-not $VpcId -or $VpcId -eq "None") {
    Write-Host "No se encontró ninguna VPC para eliminar."
    exit 1
}

Write-Host "==== Limpiando VPC: $VpcId ===="

# 2. Eliminar ENIs (interfaces de red) asociadas
$enis = aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VpcId" --query "NetworkInterfaces[].NetworkInterfaceId" --output text
if ($enis) {
    foreach ($eni in ($enis -split '\s+')) {
        Write-Host "Eliminando ENI: $eni"
        aws ec2 delete-network-interface --network-interface-id $eni
    }
}

# 3. Eliminar Security Groups (excepto el default)
$sgs = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VpcId" --query "SecurityGroups[].GroupId" --output text
if ($sgs) {
    foreach ($sg in ($sgs -split '\s+')) {
        if ($sg -ne "sg-xxxxxxxx") { # El SG default no se puede borrar
            Write-Host "Eliminando Security Group: $sg"
            aws ec2 delete-security-group --group-id $sg
        }
    }
}

# 4. Desasociar y eliminar Route Tables
$routeTables = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VpcId" --query "RouteTables[].RouteTableId" --output text
foreach ($rt in ($routeTables -split '\s+')) {
    # Desasociar
    $assocIds = aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[].Associations[].RouteTableAssociationId" --output text
    foreach ($assoc in ($assocIds -split '\s+')) {
        if ($assoc -ne "None") {
            Write-Host "Desasociando Route Table: $assoc"
            aws ec2 disassociate-route-table --association-id $assoc
        }
    }
    # Intentar borrar
    Write-Host "Eliminando Route Table: $rt"
    aws ec2 delete-route-table --route-table-id $rt
}

# 5. Eliminar Subnets
$subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VpcId" --query "Subnets[].SubnetId" --output text
if ($subnets) {
    foreach ($subnet in ($subnets -split '\s+')) {
        Write-Host "Eliminando Subnet: $subnet"
        aws ec2 delete-subnet --subnet-id $subnet
    }
}

# 6. Eliminar IGWs
$igws = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VpcId" --query "InternetGateways[].InternetGatewayId" --output text
if ($igws) {
    foreach ($igw in ($igws -split '\s+')) {
        Write-Host "Desacoplando y eliminando IGW: $igw"
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VpcId
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
    }
}

# 7. Eliminar VPC
Write-Host "==== Eliminando VPC ===="
aws ec2 delete-vpc --vpc-id $VpcId
