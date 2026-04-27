# Task 8.1 — IAM Permission Error and tasks.md Correction

## The Problem

During Task 8.1, the first deployment attempt (`d-JTQ4047UI`) failed because the `AWSCodeDeployRole` managed policy attached to `CodeDeployServiceRole` does not include all permissions needed for blue-green deployments that copy Auto Scaling groups. Specifically, it was missing:

- `iam:PassRole` — needed so CodeDeploy can pass the EC2 instance role to newly launched green instances
- `ec2:RunInstances` — needed so CodeDeploy can launch instances when copying the ASG
- `ec2:CreateTags` — needed to tag the new green instances

## The Runtime Fix

An inline policy `BlueGreenDeploymentPermissions` was attached to `CodeDeployServiceRole` granting the missing permissions. The second deployment (`d-TOT9JG8UI`) then proceeded successfully.

## The tasks.md Correction

To prevent future learners from hitting this same error, Task 2.1 in `tasks.md` was updated to include the inline policy requirement upfront. The added line:

> Attach an inline policy granting `iam:PassRole`, `ec2:RunInstances`, and `ec2:CreateTags` permissions — these are required for blue-green deployments where CodeDeploy copies the Auto Scaling group to provision green instances

This was added after the `AWSCodeDeployRole` managed policy attachment step in Task 2.1 (Implement CodeDeploy Service Role), so learners set up the correct permissions during initial IAM setup rather than discovering the gap 6 tasks later.

## Key Takeaway

The `AWSCodeDeployRole` managed policy is sufficient for in-place deployments but not for blue-green deployments with `COPY_AUTO_SCALING_GROUP` provisioning. The additional permissions are needed because CodeDeploy must launch new EC2 instances and pass the instance profile role to them.
