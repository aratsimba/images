# 📚 Task 3: Infrastructure — ALB, Auto Scaling Group, and EC2 Instances — Lectures

---

## Task 3 (Parent) — Infrastructure: ALB, Auto Scaling Group, and EC2 Instances

### 🎯 What Are We Building?

We're setting up the "stage" where our blue-green deployments will actually happen. Think of it like building a theater before the show can begin — we need the building (servers), the front door (load balancer), and the seating arrangement (auto scaling group) all in place before any actors (our application) can perform.

### 💡 Key Concept: The Load Balancer as a Traffic Cop

Imagine a busy intersection with two roads leading to two different neighborhoods. A traffic cop (the Application Load Balancer, or ALB) stands in the middle and directs cars (user requests) to whichever neighborhood is open and healthy. During a blue-green deployment, the traffic cop smoothly redirects all cars from the old neighborhood (blue) to the new one (green) — and nobody even notices the switch.

A Target Group is like a list the traffic cop carries — it says "these are the houses (servers) that are open for business right now." The cop also checks regularly (health checks) to make sure each house is still answering the door before sending anyone there.

### 🔍 How Does It Work?

1. **Create an ALB** — This is the single entry point that users hit. It lives across multiple availability zones (data centers in the same region) for reliability.
2. **Create a Target Group** — This is the registry of healthy servers. It includes health check settings so the ALB knows which servers are actually working.
3. **Create a Listener** — This connects the ALB's front door (port 80 for web traffic) to the target group, saying "when traffic arrives, send it to these servers."
4. **Create a Launch Template and Auto Scaling Group (ASG)** — The launch template is like a recipe for building identical servers, and the ASG makes sure we always have the right number of them running (in our case, 2).

### 🔧 Our Game Plan

```
Create ALB → Create Target Group → Create Listener (connects them)
                                          ↓
Create Launch Template → Create Auto Scaling Group → EC2 Instances spin up
                                          ↓
                              Instances register with Target Group
                                          ↓
                              ALB starts routing traffic ✅
```

### 💬 Quick Check

If the ALB is the traffic cop and the target group is the list of open houses — what happens when a health check fails for one of the houses?

**Answer:** The traffic cop stops sending visitors there until it's healthy again! The ALB removes the unhealthy instance from rotation so users never get sent to a broken server.

---

## Task 3.1 — Implement ALB and Target Group Creation

### 🎯 What Are We Building?

Just the first piece of our infrastructure puzzle: the load balancer, its target group, and the listener that wires them together. This is the networking foundation that CodeDeploy will later use to shift traffic between blue and green environments.

### 💡 Key Concept: Target Groups and Health Checks

Think of a restaurant with multiple kitchens. The host (ALB) needs to know which kitchens (servers) are actually cooking before seating guests there. The health check is like the host peeking into each kitchen every 30 seconds and asking "are you still serving food?" If a kitchen doesn't respond twice in a row, the host stops sending guests there. If it responds successfully twice (healthy threshold of 2), it's back in business.

### 🔍 How Does It Work?

1. We call AWS to create an ALB, giving it the subnets (network zones) it should live in and a security group (firewall rules) that allows web traffic on port 80.
2. We create a target group tied to our VPC (Virtual Private Cloud — our private network in AWS), with a health check that pings the root path `/` every 30 seconds.
3. We create a listener on port 80 that says "forward all incoming HTTP traffic to this target group."
4. We add a helper function to check the health status of whatever's registered in the target group.

### 🔧 Our Game Plan

```
create_application_load_balancer() → Returns ALB ARN (unique ID)
            ↓
create_target_group() → Returns Target Group ARN
            ↓
create_listener(ALB ARN, TG ARN, port 80) → Wires them together
            ↓
get_target_group_health() → Check if targets are healthy ✅
```

### 💬 Quick Check

Why do we need a listener?

**Answer:** Without it, the ALB has a front door but no instructions on where to send people — the listener is the rule that connects incoming traffic to the right target group!

---

## Task 3.2 — Implement Launch Template and Auto Scaling Group

### 🎯 What Are We Building?

The compute side of our infrastructure: a launch template (the recipe for building servers) and an Auto Scaling group (the manager that keeps the right number of servers running). These servers will have the CodeDeploy agent installed so they can participate in deployments, plus a simple web server (Apache) as the baseline application.

### 💡 Key Concept: Launch Templates and Auto Scaling (The Cookie Cutter and the Baker)

Imagine you're running a bakery. A launch template is like a cookie cutter — it defines the exact shape, size, and decoration of every cookie (server). Every cookie that comes out is identical: same operating system (Amazon Linux 2023), same size (instance type), same badge (IAM instance profile), same firewall rules (security group), and same setup instructions (user data script that installs the CodeDeploy agent and Apache).

The Auto Scaling group is the baker — it makes sure there are always exactly 2 cookies on the tray. If one breaks (an instance fails), the baker automatically makes a new one using the same cookie cutter. During a blue-green deployment, CodeDeploy will tell the baker to make a second batch of cookies (the green environment) using a copy of the original recipe.

### 🔍 How Does It Work?

1. We look up the latest Amazon Linux 2023 AMI (Amazon Machine Image — a pre-built server template) using an SSM parameter, so we always get the most current version.
2. We create a launch template that specifies the AMI, instance type (t2.micro), instance profile (the IAM badge from Task 2), security group, and a user data script. The user data script runs automatically when each server starts — it installs the CodeDeploy agent and Apache web server.
3. We create an Auto Scaling group that uses this launch template, registers instances with our target group (from Task 3.1), spreads across our two subnets, and maintains 2 instances. We tag it with `Name=BlueGreenDemo` so CodeDeploy can find it.
4. We build a cleanup function that tears everything down in the right order — ASG first (which terminates instances), then launch template, then listeners, target group, and finally the ALB.

### 🔧 Our Game Plan

```
Look up Amazon Linux 2023 AMI ID via SSM
            ↓
create_launch_template(AMI, instance type, profile, security group, user data)
            ↓
create_auto_scaling_group(launch template, target group, subnets, capacity=2)
            ↓
    EC2 instances launch → CodeDeploy agent installs → Apache starts
            ↓
    Instances register with Target Group → ALB routes traffic ✅

Cleanup (reverse order):
    delete ASG (force) → delete launch template → delete listeners → delete TG → delete ALB
```

### 💬 Quick Check

Why does the user data script need to install the CodeDeploy agent on each instance?

**Answer:** The CodeDeploy agent is the "ears" on each server — it listens for deployment instructions from the CodeDeploy service. Without it, CodeDeploy has no way to tell the server to download and install new application code. It's like having a delivery address but no one home to accept the package!
