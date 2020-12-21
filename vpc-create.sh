#!/bin/bash

# ** EDIT to make subnets all /24 **
# in a nutshell:
# create VPC and subnets
# create IGW and attach to the VPC 
# create custom route table in VPC
# create a route to the IGW in that rout table destination 0.0.0.0
# associate route table with one or more of the VPC subnets 
# https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-subnets-commands-example.html
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html

vpcId=`aws ec2 create-vpc --cidr-block 172.16.0.0/20 --query 'Vpc.VpcId' --output text`
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"
aws ec2 create-tags --resources $vpcId --tags Key=Name,Value=vpc-jimmy7
printf "created vpc %s\n" $vpcId

subnetId1=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 172.16.0.0/22  --availability-zone us-east-1a  --query 'Subnet.SubnetId' --output text`
aws ec2 create-tags --resources $subnetId1 --tags Key=Name,Value=jimmy-public1
printf "created PUBLIC subnet:  %s\n" $subnetId1

subnetId2=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 172.16.4.0/22  --availability-zone us-east-1d --query 'Subnet.SubnetId' --output text`
aws ec2 create-tags --resources $subnetId2 --tags Key=Name,Value=jimmy2
printf "created subnet %s\n" $subnetId2

subnetId3=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 172.16.8.0/22  --query 'Subnet.SubnetId' --output text`
aws ec2 create-tags --resources $subnetId3 --tags Key=Name,Value=jimmy3
printf "created subnet %s\n" $subnetId3

subnetId4=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 172.16.12.0/22  --query 'Subnet.SubnetId' --output text`
aws ec2 create-tags --resources $subnetId4 --tags Key=Name,Value=jimmy4
printf "created subnet %s\n" $subnetId4

gwid=`aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text`
aws ec2 attach-internet-gateway --internet-gateway-id $gwid --vpc-id $vpcId
aws ec2 create-tags --resources $gwid --tags Key=Name,Value=IGW-jimmy7

# by default every subnet inherits the default VPC route table which allows for intra-VPC communication only
# we will create public route table and associate with one of our subnets, then create route to our IGW
routeTableId=`aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text`
aws ec2 create-tags --resources $routeTableId --tags Key=Name,Value=JimmyPublic
printf "created route table for IGW %s\n" $routeTableId
aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId1
aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $gwid

securityGroupId=`aws ec2 create-security-group --group-name ControlServerSG-7 --description "ControlServerSG-7" --vpc-id $vpcId --query 'GroupId' --output text`
aws ec2 create-tags --resources $securityGroupId --tags Key=Name,Value=ControlServerSG-7
aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr 0.0.0.0/0
printf "Sec Group created:  %s\n" $securityGroupId

sleep 5;

# grab image names if needed
#aws ec2 describe-images --owners amazon
instanceId=`aws ec2 run-instances --image-id ami-f5f41398 --count 1 --instance-type t2.micro --key-name myNewKey --security-group-ids $securityGroupId --subnet-id $subnetId1 --associate-public-ip-address --query 'Instances[0].InstanceId' --output text` 
aws ec2 create-tags --resources $instanceId --tags Key=Name,Value=ControlServer

printf "Waiting for instance to become ready..\n" 
aws ec2 wait instance-running --instance-ids $instanceId
instanceUrl=`aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
printf "%s is ready.\n" $instanceUrl 


