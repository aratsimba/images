# 📚 Task 11 Mini Lecture — Cleanup & Resource Teardown

## 🎯 What Are We Building?

We're not building anything this time — we're *un*building! Throughout this project we created a whole constellation of AWS resources: roles, servers, load balancers, storage buckets, and deployment configurations. Now it's time to take them all down so you're not paying for resources you no longer need.

## 💡 Key Concept (with analogy)

Think of it like breaking down a stage after a concert. You set up the lights (IAM roles), the speakers (EC2 instances), the mixing board (ALB / load balancer), the playlist (S3 revision bucket), and the stage manager's booth (CodeDeploy). Teardown has to happen in the right order — you don't pull the stage out from under the speakers. You remove the performers first, then the equipment, then the stage itself.

In AWS, the same principle applies: you delete the things that *depend on* other things first, then work your way down to the foundational resources.

## 🔍 How Does It Work? (3-4 steps)

1. Remove the "stage manager" first — delete the CodeDeploy deployment group and application, since they orchestrate everything else.
2. Tear down the compute and networking — delete Auto Scaling groups (which terminates the EC2 instances), the launch template, the load balancer listeners, target groups, and the ALB itself.
3. Clean up storage — empty and delete the S3 bucket that held our application revision bundles.
4. Remove permissions last — detach policies from IAM roles, delete instance profiles, and delete the roles themselves. These are the foundation, so they go last.

## 🔧 Our Game Plan (visual flow with arrows)

```
CodeDeploy (deployment group → application)
        ↓
Infrastructure (ASGs → launch template → ALB listeners → target groups → ALB)
        ↓
Storage (empty S3 bucket → delete S3 bucket)
        ↓
IAM (instance profile → EC2 role → CodeDeploy service role)
```

## 💬 Quick Check

Why do we delete the CodeDeploy resources *before* the Auto Scaling groups and load balancer, rather than the other way around?

*(Answer: Because CodeDeploy references those infrastructure resources. If we deleted the infrastructure first, CodeDeploy operations could fail or leave things in a messy state.)*

---

# 📚 Task 11.1 Mini Lecture — Delete CodeDeploy Resources

## 🎯 What Are We Building?

In this subtask we're removing the two CodeDeploy resources we created: the deployment group (the set of rules that told CodeDeploy *how* to deploy — blue-green strategy, which servers to target, rollback settings) and the application (the top-level container that held our deployment groups).

## 💡 Key Concept (with analogy)

Imagine you have a recipe binder (the CodeDeploy application) with a specific recipe card inside it (the deployment group). To clean up, you pull out the recipe card first, then recycle the binder. If you tried to throw away the binder with the card still in it, things could get messy — AWS actually handles this gracefully, but it's good practice to be explicit and orderly.

## 🔍 How Does It Work? (3-4 steps)

1. Call the "delete deployment group" function, telling AWS which application and group name to remove.
2. AWS removes the deployment group configuration — the blue-green settings, rollback rules, and ASG/ALB references are all gone.
3. Call the "delete application" function, which removes the application container itself.
4. Both calls handle the "not found" case gracefully — if the resource was already deleted, the script just moves on.

## 🔧 Our Game Plan (visual flow with arrows)

```
Delete deployment group ('BlueGreenDG' from 'BlueGreenApp')
        ↓
Delete application ('BlueGreenApp')
        ↓
Verify both are gone ✓
```

## 💬 Quick Check

What happens if you try to delete a CodeDeploy application that doesn't exist?

*(Answer: Our cleanup function catches the "ApplicationDoesNotExistException" error and simply prints a message saying it doesn't exist — no crash, no problem!)*
