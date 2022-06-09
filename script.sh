#!/bin/bash

##### AWS CLI installation #####
function cli_installation {
   apt update && apt upgrade -y
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
   && unzip awscliv2.zip \
   && ./aws/install \
   && [ -d ~/.aws ] || mkdir ~/.aws
}


##### AWS CLI add configuration #####
function cli_configuration {
echo "Enter profile name"
read profile
echo "Enter aws access key ID"
read aws_access_key_id
aws configure set aws_access_key_id $aws_access_key_id --profile $profile
echo "Enter aws secret access key"
read aws_secret_access_key
aws configure set aws_secret_access_key $aws_secret_access_key --profile $profile
echo "Enter region"
read region
aws configure set region $region --profile $profile
aws configure set output text --profile $profile
}

##### Configure EBS space #####
function ebs_configuration {
echo "Enter your AWS CLI profile name"
read profile
echo "Please enter EC2 name"
read varname 
ec2_name=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values='$varname'' \
--query 'Reservations[*].Instances[*].InstanceId' --profile $profile)
root_volume_name=$(aws ec2 describe-instances --instance-id $ec2_name \
--query 'Reservations[*].Instances[*].RootDeviceName' --profile $profile)
root_volume_id=$(aws ec2 describe-volumes \
--filters Name=attachment.instance-id,Values=$ec2_name Name=attachment.device,Values=$root_volume_name \
--query 'Volumes[*].VolumeId' --profile $profile)
primary_ebs=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=$ec2_name \
--query 'Volumes[?VolumeId != `'$root_volume_id'`].VolumeId' --profile $profile)
primary_ebs_size=$(aws ec2 describe-volumes --volume-ids $primary_ebs \
--query 'Volumes[*].{Details:Size}' --profile $profile)
echo "Current primary disk size is $primary_ebs_size"
echo "How many GB do you want to add?"
read adding_disk_space
total_space=$(($primary_ebs_size + $adding_disk_space))
echo "New total space: $total_space"
aws ec2 modify-volume --size $total_space --volume-id $primary_ebs --profile $profile
}

###### If/Else conditions #####
echo "Do you want to install AWS CLI? (Yes/No)"
read aws_cli_install
if [[ $aws_cli_install == "Yes" ]]; then
cli_installation
elif [[ $aws_cli_install == "No" ]]; then
echo "Skip installation"
fi

echo "Do you need additional AWS CLI prfile? (Yes/No)" 
read aws_cli_profile_conf
if [[ $aws_cli_profile_conf == "Yes" ]]; then
cli_configuration
elif [[ $aws_cli_profile_conf == "No" ]]; then
echo "Skip configuration"
fi

echo "EBS configuration"
ebs_configuration

