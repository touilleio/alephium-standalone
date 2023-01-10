Start your Alephium full node in AWS within seconds!
====

If you have [Terraform](https://www.terraform.io/) installed as well as a valid AWS account,
launch your [Alephium full node](https://alephium.org)!

```shell
export AWS_DEFAULT_REGION=us-east-1
export AWS_PROFILE=default
terraform init
terraform apply
```

And now you can ssh to the server using the ssh key generated and locally stored. The `terraform output`
provides the ssh command to use. Assuming the freshly created instance has `${IP}` as public ip,
you can use the following command

```shell
ssh -i alephium-standalone-rsa.pem ubuntu@$IP
```

Once you're done or want to stop the full node, you can destroy the terraform resources to cleanup everything:

```shell
terraform destroy
```
