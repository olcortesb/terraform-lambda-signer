// Local vars
locals {
  zip_file_path = "src/zips/${var.function_name}.zip"
}


// Lambda file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "src/"
  output_path = local.zip_file_path
  excludes    = ["zips", "terraform", ".gitignore", "README.md", ".git", ".gitlab-ci.yml"]
}

resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket = "${var.function_name}-lambda-code-${var.environment}"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "lambda_code" {
  bucket      = aws_s3_bucket.lambda_code_bucket.id
  key         = "${var.function_name}.zip"
  source      = local.zip_file_path
  source_hash = data.archive_file.lambda_zip.output_base64sha256
  depends_on  = [data.archive_file.lambda_zip, aws_s3_bucket_versioning.versioning_example]
}


## Lambda Signer 

resource "aws_signer_signing_profile" "tfsigner" {
  name_prefix = "tfsigner"
  platform_id = "AWSLambda-SHA384-ECDSA"
}


resource "aws_signer_signing_job" "this" {
  profile_name = aws_signer_signing_profile.tfsigner.name

  source {
    s3 {
      bucket  = aws_s3_bucket.lambda_code_bucket.id
      key     = aws_s3_object.lambda_code.id
      version = aws_s3_object.lambda_code.version_id
    }
  }

  destination {
    s3 {
      bucket = aws_s3_bucket.lambda_code_bucket.id
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = true
}

resource "aws_lambda_code_signing_config" "tfsigner_code" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.tfsigner.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

// Lambda
resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  #s3_bucket     = aws_s3_bucket.lambda_code_bucket.id
  #s3_key        = "${var.function_name}.zip"
  role    = aws_iam_role.lambda_role.arn
  publish = true
  # Signer
  code_signing_config_arn = aws_lambda_code_signing_config.tfsigner_code.arn

  # S3 for signer configurations

  s3_bucket = aws_signer_signing_job.this.signed_object[0].s3[0].bucket
  s3_key    = aws_signer_signing_job.this.signed_object[0].s3[0].key

  # TODO
  # description      = "Upsert leads and individuals towards salesforce."
  # filename         = local.zip_file_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "${var.function_name}.lambda_handler"
  runtime          = "python3.8"
  timeout          = 300
  memory_size      = 128
  //layers           = [aws_lambda_layer_version.dependencies_layer.arn]
  environment {
    variables = {
      # TODO: get from aws secrets
      # Hardcoded parameters despite password and secret keys input on aws lambda "by hand" - just for testing purposes
      DATE_START = "2024-02-01"
      DATE_END   = "2024-02-18"
    }
  }

  depends_on = [resource.aws_s3_object.lambda_code]
}

// Alias
resource "aws_lambda_alias" "alias" {
  name             = var.environment
  description      = "Latest function on ${var.environment} stage"
  function_name    = aws_lambda_function.lambda.function_name
  function_version = aws_lambda_function.lambda.version
}

