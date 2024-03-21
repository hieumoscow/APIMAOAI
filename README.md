# APIMAOAI

terraform init
terraform plan -var-file=configs/dev.tfvars
terraform apply -var-file=configs/dev.tfvars
terraform destroy -var-file=configs/dev.tfvars