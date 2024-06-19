# Initialising the Core IAM User
## Context
Root users should not be used where possible. Here we use the root user to create a Core IAM User which can then be used. Once created, we use the core user account to set up MFA and reset the access keys used for itself.

## Steps
1. Initialise and apply terraform to generate the terraform state bucket, initial user, and an initial password
```
terraform init
terraform apply -var core_user_password_reset=true
```

2. Switch from the local backend if `terraform.tf` configuration to the S3 remote backend. This will now require the bucket ID to be passed in as an argument in the backend configuration block, set it to the bucked name output by the initial apply. Then migrate the state files to the new backend and delete the local state files:
```
terraform init -migrate-state
rm terraform.tfstate
rm terraform.tfstate.backup
```

3. Generate an Access Key for the user (as the root user), note the Access Key ID as OLD_ACCESS_KEY_ID for usage later.
```
aws iam create-access-key --user-name core
```

4. Use the Access Key generated to create a virtual MFA device and secret (as the core user). `CUSTOM_ID` can be any string for identifying the MFA device. This will return a serial number to use in the next step
```
aws iam create-virtual-mfa-device --virtual-mfa-device-name core-${CUSTOM_ID} --outfile qr.png --bootstrap-method QRCodePNG
```

5. Setup 2FA using the generated PNG and use the TOTP codes generated to enable the MFA device (as the core user)
```
aws iam enable-mfa-device --user-name core --serial-number ${SERIAL_NUMBER} --authentication-code1 ${CODE_1} --authentication-code2 ${CODE_2}
```

6. Generate and use new temporary session keys using the new MFA device
```
AWS_TEMPORARY_CREDENTIALS=`aws sts get-session-token --serial-number ${SERIAL_NUMBER} --token-code ${MFA_CODE}` \
  && export AWS_ACCESS_KEY_ID=`echo $AWS_TEMPORARY_CREDENTIALS | jq --raw-output '.Credentials.AccessKeyId'` \
  && export AWS_SECRET_ACCESS_KEY=`echo $AWS_TEMPORARY_CREDENTIALS | jq --raw-output '.Credentials.SecretAccessKey'` \
  && export AWS_SESSION_TOKEN=`echo $AWS_TEMPORARY_CREDENTIALS | jq --raw-output '.Credentials.SessionToken'`
```

7. Create a new Access Key (as the core user)
```
aws iam create-access-key --user-name core
```

8. Delete the old Access Key (as the core user) that was created in step 2
```
aws iam delete-access-key --access-key-id ${OLD_ACCESS_KEY_ID}
```

