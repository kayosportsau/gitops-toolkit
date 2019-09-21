#!/bin/bash
set -o nounset
set -o errexit

EKS_CLUSTER_NAME=$1

aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME}

CONTROL_PLANE_SG=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --output text --query 'cluster.resourcesVpcConfig.securityGroupIds')
CONTROL_PLANE_ENDPOINT=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --output text --query 'cluster.endpoint')

PRIVATE_IPS=$(aws ec2 describe-network-interfaces --output text --query 'NetworkInterfaces[?Groups[?GroupId==`'${CONTROL_PLANE_SG}'`]].[PrivateIpAddress]')

Field_Separator=$IFS

cp /etc/hosts /etc/hosts_backup
cat /etc/hosts | grep -v ${CONTROL_PLANE_ENDPOINT#'https://'} > /etc/hosts_new

for ip in $PRIVATE_IPS;
do
    echo $ip    ${CONTROL_PLANE_ENDPOINT#'https://'} >> /etc/hosts_new
done

cat /etc/hosts_new > /etc/hosts
IFS=$Field_Separator