# 📚 Task 9 Mini Lectures

---

## Task 9 — Traffic Shifting Strategies and Rollback (Parent)

### 🎯 What Are We Building?

In this task, we're going to experiment with different ways to shift traffic (move users) from the old version of our app to the new version — and we'll also learn how to "undo" a bad deployment (called a rollback). Think of it like this: so far we've done the equivalent of flipping a light switch — all traffic moves at once. Now we're going to learn how to use a dimmer switch instead, gradually moving traffic over.

### 💡 Key Concept: Traffic Shifting Strategies

Imagine you own a restaurant and you've just redesigned the menu. You have three ways to roll it out:

- **All-at-Once**: You swap every table's menu at the same time. Fast, but if the new menu has a typo, everyone sees it.
- **Half-at-a-Time**: You give the new menu to half the tables first. If those diners are happy, you swap the rest. This is like `CodeDeployDefault.HalfAtATime` — it deploys to roughly half the instances, then the other half.
- **One-at-a-Time**: You swap one table at a time, checking after each one. This is `CodeDeployDefault.OneAtATime` — the most cautious approach.

**Rollback** is like saying "Oops, the new menu has problems — give everyone the old menu back!" AWS CodeDeploy can do this automatically when it detects a failure, or you can trigger it manually by stopping a deployment.

### 🔍 How Does It Work? (Step by Step)

1. **Create a new version** — We update our HTML page (like printing a new menu) and upload it to S3 (our storage shelf).
2. **Deploy with a cautious strategy** — Instead of all-at-once, we use HalfAtATime or OneAtATime so traffic shifts gradually across instances (servers).
3. **Test a failure scenario** — We intentionally create a broken version (a validation script that always fails) to see CodeDeploy's automatic rollback kick in — traffic stays on the working old version.
4. **Manual stop** — We also practice stopping a deployment mid-way, which keeps traffic on the blue (original) environment.

### 🔧 Our Game Plan

```
Update HTML (v2) → Bundle & Upload to S3 → Deploy with HalfAtATime → Monitor
                                                    ↓
                                          Observe gradual traffic shift
                                                    ↓
Create BROKEN version → Deploy → Watch it FAIL → Automatic Rollback kicks in
                                                    ↓
                                    Traffic stays on blue (safe!) environment
                                                    ↓
            Implement stop_deployment() → Test manual stop mid-deployment
```

### 💬 Quick Check

If you deploy a new version and the validation script (a small test that checks if the app is working) fails on the green instances, what happens to your users? **Answer:** They keep using the old (blue) version — CodeDeploy automatically rolls back, so nobody sees the broken version.

---

## Task 9.1 — Experiment with Canary and Linear Strategies

### 🎯 What Are We Building?

We're going to deploy a new version of our web page using a more cautious approach. Instead of switching all traffic at once (like we did before), we'll use strategies that move traffic gradually — so if something goes wrong, only some users are affected.

### 💡 Key Concept: Deployment Configurations

Think of a highway with multiple lanes being repaved:

- **AllAtOnce**: Close all lanes, repave them all, reopen. Fast but risky — if the new pavement is bad, every driver hits it.
- **HalfAtATime**: Repave half the lanes while traffic uses the other half. Then swap. A nice middle ground.
- **OneAtATime**: Repave one lane at a time, testing each before moving to the next. Slowest but safest.

On EC2 (the servers that run your app), CodeDeploy uses these "deployment configurations" (rules that control how many instances get updated at once). Each instance is like one lane on the highway — the configuration decides how many lanes get repaved simultaneously.

**Important note**: True canary and linear percentage-based traffic shifting (like "send 10% of traffic first") is only available for Lambda and ECS deployments. For EC2, we control the rollout speed by choosing how many instances get the new version at a time.

### 🔍 How Does It Work?

1. **Update the app** — We change our HTML page to say "Version 2" (like printing a new sign for the restaurant).
2. **Bundle and upload** — We package the new files into a zip and upload to S3 (our cloud storage shelf).
3. **Deploy with HalfAtATime** — CodeDeploy updates half the instances first, checks they're healthy, then updates the rest.
4. **Monitor** — We watch the deployment progress, seeing instances update in waves rather than all at once.

### 🔧 Our Game Plan

```
Edit index.html → "Version 2.0"
        ↓
Bundle into revision.zip → Upload to S3 as v2.zip
        ↓
Trigger deployment with HalfAtATime config
        ↓
Monitor: first batch of instances updated → health check → second batch
        ↓
Trigger another deployment with OneAtATime config
        ↓
Monitor: one instance at a time updated → observe the slower, safer rollout
```

### 💬 Quick Check

If you have 4 instances and use HalfAtATime, how many instances get the new version in the first wave? **Answer:** 2 — half of them get updated first, and once those are healthy, the other 2 follow.

---

## Task 9.2 — Test Deployment Rollback

### 🎯 What Are We Building?

We're going to test what happens when a deployment goes wrong — and how CodeDeploy protects your users by automatically "rolling back" (undoing the change). We'll also build a manual stop button so you can halt a deployment mid-way if you spot trouble.

### 💡 Key Concept: Rollback

Imagine you're a pilot and you've started taxiing down the runway for takeoff. Suddenly, a warning light comes on. You have two options:

- **Automatic abort**: The plane's computer detects the problem and automatically stops the takeoff, bringing you safely back to the gate. This is like CodeDeploy's **automatic rollback** — when a validation script (a small health check) fails, CodeDeploy automatically keeps traffic on the old, working version.

- **Manual abort**: You, the pilot, decide something doesn't look right and hit the brakes yourself. This is like **stopping a deployment manually** — you call `stop_deployment()` and CodeDeploy halts the process, keeping users on the safe blue (original) environment.

In both cases, the key idea is the same: your users never see the broken version. The old version keeps running as if nothing happened.

### 🔍 How Does It Work?

1. **Create a broken version** — We make a validation script (the health check that runs after installation) that always fails on purpose (it exits with an error code).
2. **Deploy the broken version** — CodeDeploy installs it on the green instances, runs the validation script, and it fails.
3. **Automatic rollback kicks in** — Because we enabled auto-rollback on our deployment group, CodeDeploy reroutes traffic back to the blue environment. Users are safe.
4. **Test manual stop** — We trigger another deployment and call `stop_deployment()` while it's still in progress, proving we can halt things ourselves too.

### 🔧 Our Game Plan

```
Create broken validate_service.sh (always exits with error)
        ↓
Bundle & upload as v4-fail.zip → Trigger deployment
        ↓
CodeDeploy installs on green → Runs validation → FAILS!
        ↓
Automatic rollback → Traffic stays on blue (safe!)
        ↓
Implement stop_deployment() in deployment_monitor.py
        ↓
Trigger another deployment → Call stop_deployment() mid-flight
        ↓
Deployment halted → Blue environment still serving traffic
        ↓
Check deployment history → See rollback and stopped events
```

### 💬 Quick Check

If you deploy a broken version and the validation script fails, do your users see the broken page? **Answer:** No! CodeDeploy's automatic rollback keeps traffic on the old (blue) version. The green instances with the broken code never receive real user traffic.
