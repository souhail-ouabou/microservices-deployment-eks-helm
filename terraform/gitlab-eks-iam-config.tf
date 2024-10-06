data "aws_caller_identity" "current" {}

# IAM Role for GitLab CI/CD
resource "aws_iam_role" "gitlab_ci_role" {
  name = "${local.env}-${local.eks_name}-eks-admin"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }
  ]
}
POLICY
}

# IAM Policy for GitLab CI/CD Admin Access
resource "aws_iam_policy" "gitlab_ci_policy" {
  name = "AmazonEKSAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "gitlab_admin" {
  role       = aws_iam_role.gitlab_ci_role.name
  policy_arn = aws_iam_policy.gitlab_ci_policy.arn
}

# IAM User for GitLab CI/CD Manager
resource "aws_iam_user" "gitlab_ci_manager" {
  name = "gitlab_ci_manager"
}

# IAM Policy to Allow GitLab CI Manager to Assume GitLab CI Role
resource "aws_iam_policy" "gitlab_ci_assume_role_policy" {
  name = "AmazonEKSAssumeGitLabCIAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "${aws_iam_role.gitlab_ci_role.arn}"
        }
    ]
}
POLICY
}

# Attach the assume role policy to the GitLab CI Manager
resource "aws_iam_user_policy_attachment" "gitlab_ci_manager_attachment" {
  user       = aws_iam_user.gitlab_ci_manager.name
  policy_arn = aws_iam_policy.gitlab_ci_assume_role_policy.arn
}

# Best practice: use IAM roles due to temporary credentials
resource "aws_eks_access_entry" "gitlab_ci_manager_access" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.gitlab_ci_role.arn
  kubernetes_groups = ["gitlab-admin"]
}
