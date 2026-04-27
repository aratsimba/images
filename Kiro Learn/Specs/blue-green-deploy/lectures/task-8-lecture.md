# 📚 Task 8 Mini Lecture: Execute Blue-Green Deployment and Monitor

This task has two subtasks, each with its own lecture.

---

## Task 8 (Parent) — Execute Blue-Green Deployment and Monitor

### 🎯 What Are We Building?

In this task, we're going to actually *launch* a blue-green deployment and watch it happen in real time. Think of everything we've built so far — the roles, the servers, the load balancer, the application code bundle, the CodeDeploy setup — as preparing a rocket on the launch pad. Now we're pressing the launch button and watching it fly.

We'll trigger a deployment and then build a monitoring tool that lets us watch every step as CodeDeploy spins up new servers (the "green" environment), installs our app on them, checks that everything is healthy, and then switches all traffic over from the old servers (the "blue" environment) to the new ones.

### 💡 Key Concept: Deployment Monitoring

Imagine you're a restaurant owner opening a second location across the street. You don't just open the doors and hope for the best — you walk through the new restaurant checking that the kitchen works, the tables are set, and the food tastes right. Only after everything checks out do you put up the "OPEN" sign and redirect customers from the old location.

That's exactly what deployment monitoring does. After CodeDeploy starts building the green environment, our monitor keeps checking in: "Are the new servers ready? Did the app install correctly? Did the health checks pass?" It's like a project manager with a clipboard walking through each step of the opening checklist.

### 🔍 How Does It Work?

1. **Trigger the deployment** — We tell CodeDeploy "go!" by calling `create_deployment` with our app name, deployment group, and the revision bundle (the zip file we uploaded to S3). We pick the "AllAtOnce" strategy, meaning all traffic switches in one step rather than gradually.

2. **CodeDeploy does its thing** — Behind the scenes, CodeDeploy copies our Auto Scaling Group (ASG) to create brand-new green servers, installs the CodeDeploy agent on them, downloads our revision from S3, runs the lifecycle hook scripts (BeforeInstall, AfterInstall, ValidateService), and waits for everything to pass.

3. **We poll for status** — Our monitoring tool asks CodeDeploy "how's it going?" every few seconds. It gets back a status like "InProgress", "Succeeded", or "Failed", along with details about what's happening on each individual server.

4. **Traffic shifts** — Once all green instances pass validation, CodeDeploy tells the load balancer (ALB) to send all traffic to the new servers. The old blue servers stick around for a few minutes (our configured wait time) and then get terminated.

### 🔧 Our Game Plan

```
Trigger Deployment (AllAtOnce)
        ↓
CodeDeploy provisions green instances
        ↓
App installed → lifecycle hooks run
        ↓
Monitor polls status every few seconds
        ↓
All checks pass → traffic shifts to green
        ↓
Verify green instances are healthy in ALB
```

### 💬 Quick Check

If our ValidateService script (the one that curls localhost to check the app is running) fails on one of the green instances, what do you think happens — does traffic still switch over, or does the deployment stop?

*(Answer: The deployment stops and traffic stays on the blue environment — that's the safety net of blue-green deployments!)*

---

## Task 8.1 — Trigger All-at-Once Deployment

### 🎯 What Are We Building?

In this subtask, we're going to trigger our very first blue-green deployment. We already have the `create_deployment` function written in our deployment manager — now we're going to actually *call* it and tell AWS CodeDeploy to start swapping our environments.

Think of it like this: we've been rehearsing a play for weeks, and now it's opening night. We're raising the curtain.

### 💡 Key Concept: All-at-Once Deployment

Imagine you're moving into a new apartment. An "all-at-once" strategy means you move everything in one trip — all your furniture, all your boxes, everything at once. It's the fastest approach, but if something goes wrong (the truck breaks down), everything is affected at the same time.

In deployment terms, "AllAtOnce" means CodeDeploy shifts 100% of traffic from the old servers (blue) to the new servers (green) in a single step. There's no gradual rollout — it's a clean, instant switch. This is the simplest strategy and great for learning, though in production you might prefer a more gradual approach.

### 🔍 How Does It Work?

1. **We call `create_deployment`** — We pass in our app name ("BlueGreenApp"), deployment group ("BlueGreenDG"), the S3 location of our revision bundle, and the deployment config name "CodeDeployDefault.AllAtOnce".

2. **CodeDeploy receives the request** — It returns a deployment ID (a unique identifier, like a tracking number for a package). This ID is how we'll check on the deployment's progress later.

3. **CodeDeploy starts working** — Behind the scenes, it copies our Auto Scaling Group to create fresh green instances, installs our app using the AppSpec file (the instruction sheet we created earlier), and runs the lifecycle hook scripts.

4. **Traffic switches** — Once all green instances pass their health checks, the load balancer (ALB — the traffic director) sends all incoming requests to the green servers instead of the blue ones.

### 🔧 Our Game Plan

```
Call create_deployment() with AllAtOnce config
        ↓
CodeDeploy returns a deployment ID
        ↓
CodeDeploy copies ASG → new green instances
        ↓
Installs app → runs BeforeInstall, AfterInstall, ValidateService
        ↓
All pass → ALB shifts 100% traffic to green
```

### 💬 Quick Check

When we call `create_deployment`, does the function wait until the entire deployment finishes, or does it return right away with a tracking ID?

*(Answer: It returns right away with a deployment ID — the deployment runs in the background on AWS, and we need a separate monitoring tool to watch its progress!)*

---

## Task 8.2 — Implement Deployment Monitoring

### 🎯 What Are We Building?

We just launched a deployment — but right now we're flying blind. We have a deployment ID (like a package tracking number), but no way to see what's happening. In this task, we're building a deployment monitor — a tool that watches the deployment in real time and tells us exactly what's going on at every step.

This is the "mission control" for our deployment. Just like NASA has screens showing rocket telemetry (data about speed, altitude, fuel), our monitor will show us which servers are being set up, which lifecycle scripts are running, and whether everything is passing or failing.

### 💡 Key Concept: Polling for Status

Imagine you ordered a pizza online. You keep refreshing the order tracker page: "Is it being prepared? Is it in the oven? Is the driver on the way?" That's polling (asking the same question repeatedly at regular intervals until you get the answer you're waiting for).

Our deployment monitor does exactly this. It asks CodeDeploy "what's the status?" every few seconds. CodeDeploy responds with the current state — "InProgress", "Succeeded", or "Failed" — along with details about each server and each lifecycle event (like BeforeInstall, AfterInstall, ValidateService). We keep asking until the deployment is done.

### 🔍 How Does It Work?

1. **Get deployment status** — We ask CodeDeploy for the overall status of a deployment using its ID. It tells us things like "InProgress" or "Succeeded", when it started, and what config it's using.

2. **Get instance targets** — A deployment touches multiple servers (instances). We ask CodeDeploy for the list of target instances and what's happening on each one — are they pending, in progress, or done?

3. **Get lifecycle events** — For each instance, we can drill down into the individual lifecycle events (BeforeInstall, AfterInstall, ValidateService). Each event has its own status, start time, end time, and error details if something went wrong.

4. **Wait and repeat** — We wrap all of this in a loop that polls every few seconds, printing status updates, until the deployment reaches a final state (Succeeded, Failed, or Stopped).

### 🔧 Our Game Plan

```
get_deployment_status(deployment_id)
        ↓
get_instance_targets(deployment_id)
        ↓
get_lifecycle_events(deployment_id, target_id)
        ↓
wait_for_deployment() — polls in a loop
        ↓
list_deployments() — view deployment history
        ↓
Verify green instances healthy in ALB
```

### 💬 Quick Check

If our monitor polls CodeDeploy and gets back status "InProgress", what should it do — stop and report success, or wait a few seconds and ask again?

*(Answer: Wait a few seconds and ask again! "InProgress" means the deployment is still running. We only stop polling when we see a final status like "Succeeded" or "Failed".)*
