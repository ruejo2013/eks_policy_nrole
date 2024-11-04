data "aws_iam_user" "pith_infra" {
  user_name = var.user_name
}


# Step 1: Define the custom IAM policy with all required permissions
data "aws_iam_policy_document" "eks_permissions_policy" {
  statement {
    actions = [
      # EC2 Permissions
      "ec2:RunInstances",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:DescribeRegions",
      "ec2:DescribeVpcs",
      "ec2:DescribeTags",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeRouteTables",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeImages",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeAccountAttributes",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteKeyPair",
      "ec2:CreateTags",
      "ec2:CreateSecurityGroup",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateKeyPair",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",

      # EKS Permissions
      "eks:UpdateNodegroupVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateClusterConfig",
      "eks:UntagResource",
      "eks:TagResource",
      "eks:ListUpdates",
      "eks:ListTagsForResource",
      "eks:ListNodegroups",
      "eks:ListFargateProfiles",
      "eks:ListClusters",
      "eks:DescribeUpdate",
      "eks:DescribeNodegroup",
      "eks:DescribeFargateProfile",
      "eks:DescribeCluster",
      "eks:DeleteNodegroup",
      "eks:DeleteFargateProfile",
      "eks:DeleteCluster",
      "eks:CreateNodegroup",
      "eks:CreateFargateProfile",
      "eks:CreateCluster",

      # KMS Permissions
      "kms:ListKeys",

      # IAM Permissions
      "iam:PassRole",
      "iam:ListRoles",
      "iam:ListRoleTags",
      "iam:ListInstanceProfilesForRole",
      "iam:ListInstanceProfiles",
      "iam:ListAttachedRolePolicies",
      "iam:GetRole",
      "iam:GetInstanceProfile",
      "iam:DetachRolePolicy",
      "iam:DeleteRole",
      "iam:CreateRole",
      "iam:AttachRolePolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_permissions_policy" {
  name   = "EKSFullPermissionsPolicy"
  policy = data.aws_iam_policy_document.eks_permissions_policy.json
}

# Step 2: Define the IAM Role with Trust Policy for ec2.amazonaws.com and pith-infra user
resource "aws_iam_role" "eks_role" {
  name = "EKSFullPermissionsRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : data.aws_iam_user.pith_infra.arn

        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Attach the custom policy to the IAM role
resource "aws_iam_role_policy_attachment" "eks_permissions_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = aws_iam_policy.eks_permissions_policy.arn
}

# Step 4: Create a policy to allow 'pith-infra' to assume the EKS role
data "aws_iam_policy_document" "user_assume_role_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.eks_role.arn]
  }
}

resource "aws_iam_policy" "assume_role_policy" {
  name   = "EksAssumeRolePolicy"
  policy = data.aws_iam_policy_document.user_assume_role_policy.json
}

# Attach the assume role policy to the pith-infra user
resource "aws_iam_user_policy_attachment" "user_assume_role_policy_attachment" {
  user       = var.user_name
  policy_arn = aws_iam_policy.assume_role_policy.arn
}

