# Reset the Core User Password
## Context
The Core IAM User requires a password reset

## Steps
1. Run terraform with the reset password variable (as the root user)
```
terraform apply -var core_user_password_reset=true
```

2. Log in as the core user via the console using the new password. The core user will then need to change their password

