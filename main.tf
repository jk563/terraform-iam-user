resource "aws_iam_user" "main" {
  name          = var.name
  force_destroy = true
}

resource "aws_iam_user_login_profile" "main" {
  user                    = aws_iam_user.main.name
  password_reset_required = var.reset_password
}

resource "aws_iam_user_policy_attachment" "main_default_permissions" {
  policy_arn = aws_iam_policy.main_default_permissions.arn
  user       = aws_iam_user.main.name
}

resource "aws_iam_policy" "main_default_permissions" {
  description = "Enforce MFA, except for MFA creation; allow creation of access keys"
  name        = "AccessKeysAndEnforceMFA"
  policy      = data.aws_iam_policy_document.default_user_permissions.json
}

data "aws_iam_policy_document" "default_user_permissions" {
  statement {
    sid = "AllowViewOwnInfo"
    actions = [
      "iam:GetUser",
      "iam:GetLoginProfile",
      "iam:ListUserTags",
      "iam:ListSigningCertificates",
      "iam:ListSSHPublicKeys",
      "iam:ListServiceSpecificCredentials",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid = "AllowManageOwnAccess"
    actions = [
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:GetAccessKeyLastUsed",
      "iam:ChangePassword",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid       = "AllowManageOwnVirtualMFADevice"
    actions   = ["iam:CreateVirtualMFADevice"]
    resources = ["arn:aws:iam::*:mfa/$${aws:username}-*"]
  }

  statement {
    sid = "AllowManageOwnUserMFA"
    actions = [
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice",
    ]
    resources = ["arn:aws:iam::*:user/$${aws:username}"]
  }

  statement {
    sid    = "EnforceMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken",
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

