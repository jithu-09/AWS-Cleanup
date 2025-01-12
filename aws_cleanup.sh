#!/bin/bash

# Define log file
log_file="cleanup_log.txt"

# Define regions to process
regions=("eu-west-1" "eu-north-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2")

# Log the start time
echo "Cleanup started at $(date)"

# Loop through each region
for region in "${regions[@]}"; do
  echo "Processing region: $region"

  # Terminate all running EC2 instances
  echo "Terminating all running EC2 instances in region $region..."
  instance_ids=$(aws ec2 describe-instances --region $region --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' --output text)
  if [ -n "$instance_ids" ]; then
    aws ec2 terminate-instances --region $region --instance-ids $instance_ids
    echo "Terminated EC2 instances: $instance_ids" >> $log_file
  else
    echo "No running EC2 instances found in region $region."
  fi

  # Delete all non-default VPCs
  echo "Deleting all non-default VPCs in region $region..."
  vpc_ids=$(aws ec2 describe-vpcs --region $region --query 'Vpcs[?IsDefault==`false`].VpcId' --output text)
  for vpc_id in $vpc_ids; do
    echo "Deleting VPC: $vpc_id in region $region"

    # Delete dependencies: Subnets, Gateways, Route Tables, etc.
    subnet_ids=$(aws ec2 describe-subnets --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text)
    for subnet_id in $subnet_ids; do
      aws ec2 delete-subnet --region $region --subnet-id $subnet_id
    done

    igw_id=$(aws ec2 describe-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text)
    if [ -n "$igw_id" ]; then
      aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw_id --vpc-id $vpc_id
      aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw_id
    fi

    route_table_ids=$(aws ec2 describe-route-tables --region $region --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text)
    for route_table_id in $route_table_ids; do
      aws ec2 delete-route-table --region $region --route-table-id $route_table_id
    done

    # Finally, delete the VPC
    aws ec2 delete-vpc --region $region --vpc-id $vpc_id
    echo "Deleted VPC: $vpc_id in region $region" >> $log_file
  done

  # Delete all load balancers
  echo "Deleting all load balancers in region $region..."
  load_balancers=$(aws elb describe-load-balancers --region $region --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text)
  for lb in $load_balancers; do
    aws elb delete-load-balancer --region $region --load-balancer-name $lb
    echo "Deleted Load Balancer: $lb in region $region" >> $log_file
  done

  # Delete all EKS clusters and managed node groups
  echo "Deleting all EKS clusters and their associated managed node groups in region $region..."
  eks_clusters=$(aws eks list-clusters --region $region --query 'clusters' --output text)
  for cluster in $eks_clusters; do
    # Delete managed node groups
    node_groups=$(aws eks list-nodegroups --region $region --cluster-name $cluster --query 'nodegroups' --output text)
    for node_group in $node_groups; do
      aws eks delete-nodegroup --region $region --cluster-name $cluster --nodegroup-name $node_group
    done

    # Wait for node groups to delete before deleting the cluster
    for node_group in $node_groups; do
      aws eks wait nodegroup-deleted --region $region --cluster-name $cluster --nodegroup-name $node_group
    done

    # Finally, delete the cluster
    aws eks delete-cluster --region $region --name $cluster
    echo "Deleted EKS cluster: $cluster in region $region" >> $log_file
  done

  # Terminate orphaned EC2 instances from EKS node groups
  echo "Terminating orphaned EC2 instances from EKS node groups in region $region..."
  eks_instance_ids=$(aws ec2 describe-instances --region $region --query 'Reservations[].Instances[?Tags[?Key==`eks:cluster-name`]].InstanceId' --output text)
  if [ -n "$eks_instance_ids" ]; then
    aws ec2 terminate-instances --region $region --instance-ids $eks_instance_ids
    echo "Terminated orphaned EC2 instances: $eks_instance_ids in region $region" >> $log_file
  else
    echo "No orphaned EKS-managed instances found in region $region."
  fi
done

# Log the end time
echo "Cleanup completed at $(date)" >> $log_file
