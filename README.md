# terraform-lambda-signer
POC of AWS lambda Signer with terraform


## Get Starter

- Configure terraform 
- Configure AWS credentials ([Link](https://gist.github.com/olcortesb/a471797eb1d45c54ad51d920b78aa664))
- Create and configure bucket name 

## Deploy

```
terraform plan
terraform apply
```

## Folder structure

```bash
.
├── data.tf
├── lambda_role.tf
├── lambda.tf
├── LICENSE
├── preferences.tf
├── README.md
├── src                # Lambda Folder
│   └── getcost.py     # Lamba Code
├── terraform.tfvars
└── variables.tf
```

## What Is AWS Signer

ref: https://docs.aws.amazon.com/signer/latest/developerguide/Welcome.html

>AWS Signer is a fully managed code-signing service to ensure the trust and integrity of your code. Organizations validate code against a digital signature to confirm that the code is unaltered and from a trusted publisher. With AWS Signer, your security administrators have a single place to define your signing environment, including what AWS Identity and Access Management (IAM) role can sign code and in what Regions. AWS Signer manages the code-signing certificate's public and private keys, and enables central management of the code-signing lifecycle. Integration with AWS CloudTrail helps you track who is generating code signatures and to meet your compliance requirements.

# References

- https://docs.aws.amazon.com/signer/latest/developerguide/Welcome.html
