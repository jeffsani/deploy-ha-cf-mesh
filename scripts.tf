# Install scripts are now standalone bash scripts in scripts/.
# They accept the connector token as a CLI argument.
# No Terraform rendering needed — just copy the script to hosts and run:
#
#   TOKEN=$(terraform output -raw connector_token)
#   scp scripts/install_debian.sh user@host:~/
#   ssh user@host "chmod +x ~/install_debian.sh && sudo ~/install_debian.sh $TOKEN"
