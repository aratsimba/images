# 📚 Task 1 Mini Lecture: Prerequisites - Environment Setup

## 🎯 What Are We Building?

Before we write any code, we need to set up our workspace — think of it like a chef preparing their kitchen before cooking a meal. We need the right tools on the counter, the ingredients ready, and the workspace organized. In our case, that means making sure our computer can talk to AWS (Amazon's cloud), that we have the right programming tools installed, and that our project folders are neatly laid out.

## 💡 Key Concept: Environment Setup (with analogy)

Imagine you're about to build a piece of IKEA furniture. Before you start assembling, you'd:
1. Check you have the instruction manual (AWS account & credentials — your "permission slip" to use Amazon's cloud computers)
2. Lay out all the tools — screwdriver, Allen key, etc. (AWS CLI, Python, boto3 — the software tools we'll use)
3. Identify which room you're building in and measure the space (VPC, subnets, security groups — the "rooms" and "doors" inside AWS's cloud network)
4. Organize the parts into labeled piles (project folders and empty files — our organized workspace)

Without this prep, you'd be hunting for a missing screw halfway through the build. Same idea here.

## 🔍 How Does It Work? (step by step)

1. **Verify AWS access** — We confirm our computer has a "key card" (credentials) that lets us into AWS, and we check who we're logged in as. This is like swiping your badge at the office door to make sure it works.

2. **Check our tools** — We verify that the AWS CLI (a command-line remote control for AWS), Python (our programming language), and boto3 (a Python library that talks to AWS services) are all installed and working.

3. **Scout the network** — AWS organizes its cloud into VPCs (Virtual Private Clouds — think of them as private office buildings). Inside each VPC are subnets (individual floors). We need to find a VPC with at least two subnets in different locations so our load balancer (traffic director) can spread visitors across them. We also need a security group (a firewall rule) that allows web traffic in on port 80.

4. **Create the project skeleton** — We set up folders and empty files so everything has a home before we start writing code.

## 🔧 Our Game Plan

```
Check AWS credentials ➜ Verify tools installed ➜ Discover network resources ➜ Create project folders
       (keys)              (toolbox)              (find the right rooms)       (organize workspace)
```

## 💬 Quick Check

If the AWS CLI is like a remote control for AWS, what do you think boto3 is? (Hint: it's the same idea, but built for Python programs to use instead of you typing commands by hand.)
