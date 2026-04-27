# 📚 Task 2: IAM Roles and Instance Profiles — Lectures

---

## Task 2 (Parent) — IAM Roles and Instance Profiles

### 🎯 What Are We Building?

In this task, we're setting up the "security badges" that allow different parts of our deployment system to talk to each other. Specifically, we're creating two things:

1. A service role for AWS CodeDeploy (the tool that handles our deployments)
2. An instance profile for our EC2 servers (the computers that will run our app)

Without these, nothing in our pipeline has permission to do anything — it's like showing up to a secure building without an ID badge.

### 💡 Key Concept: IAM Roles (Identity Badges for Services)

Think of AWS like a large office building with many departments. Every department (service) needs a badge (IAM role) that says exactly which rooms they're allowed to enter and what they can do there.

- A "role" is like a badge that says "I'm allowed to do X, Y, and Z."
- A "trust policy" is like the badge office saying "Only employees from Department A can get this badge." It controls who is allowed to wear the badge.
- An "instance profile" is a special badge holder that attaches a role to an EC2 instance — think of it as a lanyard that clips the badge onto a specific person.

So when CodeDeploy needs to move traffic around or talk to your servers, it shows its badge. When your EC2 servers need to download your app code from storage (S3), they show theirs.

### 🔍 How Does It Work?

1. We create a trust policy that says "AWS CodeDeploy is allowed to assume this role" — this is like registering CodeDeploy at the badge office.
2. We attach a managed policy (`AWSCodeDeployRole`) to that role — this is the list of permissions on the badge (access EC2, Auto Scaling, Load Balancers).
3. We create a second role for EC2 instances with permissions to read from S3 (where our app code lives) and communicate with AWS Systems Manager (how the CodeDeploy agent phones home).
4. We wrap that EC2 role in an "instance profile" — the lanyard that physically attaches the badge to each server.

### 🔧 Our Game Plan

```
Create CodeDeploy Service Role
    → Add trust policy (CodeDeploy can wear this badge)
    → Attach AWSCodeDeployRole policy (permissions list)
    → Wait 10 seconds (badge needs time to activate in the system)

Create EC2 Instance Profile
    → Create EC2 role with trust policy (EC2 can wear this badge)
    → Attach S3 read + SSM policies
    → Create instance profile (the lanyard)
    → Add the role to the instance profile

Cleanup function
    → Remove badges and lanyards when we're done
```

### 💬 Quick Check

If CodeDeploy didn't have its service role, what would happen when it tries to shift traffic on the load balancer?

**Answer:** It would be denied — like trying to enter a restricted room without a badge. AWS would say "Access Denied" because CodeDeploy has no permission to touch the load balancer.

---

## Task 2.1 — Implement CodeDeploy Service Role

### 🎯 What Are We Building?

We're creating the very first piece of our deployment system: the CodeDeploy service role. This is the permission badge that lets AWS CodeDeploy do its job — managing your servers, talking to the load balancer, and orchestrating deployments.

### 💡 Key Concept: Trust Policies (Who Can Wear the Badge?)

Imagine you work at a hospital. There's a special badge that lets you access the operating room. But not just anyone can get that badge — only surgeons are allowed to request it.

That's exactly what a "trust policy" does. It's a rule that says: "Only this specific AWS service (CodeDeploy) is allowed to assume (put on) this role." Even if another service tried to use it, AWS would say "nope, you're not on the list."

The trust policy is the "who can wear it" part. The attached policy (`AWSCodeDeployRole`) is the "what they can do while wearing it" part — in this case, interact with EC2 instances, Auto Scaling groups, and load balancers.

### 🔍 How Does It Work?

1. We call AWS IAM (Identity and Access Management — the badge office) and say "create a new role."
2. We include a trust policy document that says "codedeploy.amazonaws.com is allowed to assume this role."
3. We attach the AWS-managed policy `AWSCodeDeployRole` — this is a pre-built permissions list that AWS maintains, so we don't have to write every permission by hand.
4. We wait about 10 seconds — IAM changes take a moment to spread across all of AWS's systems (called "propagation," like waiting for a new badge to show up in the security system).

### 🔧 Our Game Plan

```
create_codedeploy_service_role(role_name)
    → Build trust policy JSON (CodeDeploy can assume this role)
    → Call IAM create_role with the trust policy
    → Attach AWSCodeDeployRole managed policy
    → Sleep 10 seconds for propagation
    → Return the role ARN (a unique address for the role)

get_role_arn(role_name)
    → Call IAM get_role
    → Return just the ARN string
```

### 💬 Quick Check

Why do we need to wait 10 seconds after creating the role?

**Answer:** IAM is a global service — changes need a few seconds to replicate across AWS's infrastructure. If we try to use the role immediately, other services might not "see" it yet and would throw an error.

---

## Task 2.2 — Implement EC2 Instance Profile

### 🎯 What Are We Building?

Now we're creating the badge for the other side — the EC2 instances (your servers). These servers need permission to do two things: download your app code from S3 (Amazon's file storage) and talk to AWS Systems Manager (so the CodeDeploy agent can phone home). We're also building a cleanup function to tear everything down when we're done.

### 💡 Key Concept: Instance Profiles (The Lanyard)

You know how at a conference, you get a name badge and a lanyard to hang it around your neck? In AWS, a "role" is the badge (it has your permissions), and an "instance profile" is the lanyard — it's the thing that physically attaches the badge to an EC2 instance.

You can't just hand a role directly to an EC2 instance. You have to wrap it in an instance profile first. It's a small extra step, but it's how AWS designed it — the instance profile is the delivery mechanism.

### 🔍 How Does It Work?

1. We create an IAM role with a trust policy that says "EC2 instances are allowed to assume this role" — only servers can wear this badge.
2. We attach two policies: one for reading files from S3 (so the server can download your app), and one for Systems Manager (so the CodeDeploy agent can communicate with AWS).
3. We create an instance profile (the lanyard) and add the role to it.
4. Later, when we launch EC2 instances, we'll attach this instance profile so they automatically get the right permissions.

### 🔧 Our Game Plan

```
create_ec2_instance_profile(profile_name, role_name)
    → Create IAM role with EC2 trust policy
    → Attach AmazonS3ReadOnlyAccess policy
    → Attach AmazonSSMManagedInstanceCore policy
    → Create instance profile (the lanyard)
    → Add role to instance profile
    → Wait 10 seconds for propagation
    → Return the instance profile ARN

delete_roles_and_profiles(role_name, profile_name)
    → Remove role from instance profile
    → Delete instance profile
    → Detach all policies from role
    → Delete the role
```

### 💬 Quick Check

Why do we need an instance profile instead of just attaching the role directly to an EC2 instance?

**Answer:** AWS requires this extra wrapper. Think of it as a container — the instance profile holds the role and is what actually gets associated with the EC2 instance. It's AWS's way of keeping things organized and secure.
