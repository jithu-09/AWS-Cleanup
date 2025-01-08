# Terminate all running EC2 instances
echo "Terminating all running EC2 instances..."
aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' --output text)

# Delete all non-default VPCs
echo "Deleting all non-default VPCs..."
vpc_ids=$(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].VpcId' --output text)
for vpc_id in $vpc_ids; do
  echo "Deleting VPC: $vpc_id"

  # Delete dependencies: Subnets, Gateways, Route Tables, etc.
  echo "Deleting subnets for VPC: $vpc_id"
  aws ec2 delete-subnet --subnet-id $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text)

  echo "Detaching and deleting internet gateways for VPC: $vpc_id"
  igw_id=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text)
  if [ -n "$igw_id" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
  fi

  echo "Deleting route tables for VPC: $vpc_id"
  route_table_ids=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output text)
  for route_table_id in $route_table_ids; do
    aws ec2 delete-route-table --route-table-id $route_table_id
  done

  # Finally, delete the VPC
  aws ec2 delete-vpc --vpc-id $vpc_id
done

# Delete all load balancers
echo "Deleting all load balancers..."
load_balancers=$(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text)
for lb in $load_balancers; do
  echo "Deleting Load Balancer: $lb"
  aws elb delete-load-balancer --load-balancer-name $lb
done

# Delete all EKS clusters and managed node groups
echo "Deleting all EKS clusters and their associated managed node groups..."
eks_clusters=$(aws eks list-clusters --query 'clusters' --output text)
for cluster in $eks_clusters; do
  echo "Processing EKS cluster: $cluster"

  # Delete managed node groups
  node_groups=$(aws eks list-nodegroups --cluster-name $cluster --query 'nodegroups' --output text)
  for node_group in $node_groups; do
    echo "Deleting node group: $node_group in cluster: $cluster"
    aws eks delete-nodegroup --cluster-name $cluster --nodegroup-name $node_group
  done

  # Wait for node groups to delete before deleting the cluster
  echo "Waiting for node groups to delete..."
  for node_group in $node_groups; do
    aws eks wait nodegroup-deleted --cluster-name $cluster --nodegroup-name $node_group
  done

  # Finally, delete the cluster
  echo "Deleting EKS cluster: $cluster"
  aws eks delete-cluster --name $cluster
done

# Terminate orphaned EC2 instances from EKS node groups
echo "Terminating orphaned EC2 instances from EKS node groups..."
eks_instance_ids=$(aws ec2 describe-instances --query 'Reservations[].Instances[?Tags[?Key==`eks:cluster-name`]].InstanceId' --output text)
if [ -n "$eks_instance_ids" ]; then
  aws ec2 terminate-instances --instance-ids $eks_instance_ids
  echo "Terminated EKS-managed instances: $eks_instance_ids"
else
  echo "No orphaned EKS-managed instances found."
fi

echo "Resource cleanup completed."
