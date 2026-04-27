# Task 10: Cleanup - Resource Teardown — Mini Lectures

---

## 📚 Task 10 (Parent) Mini Lecture

### 🎯 What Are We Building?

We're not building anything this time — we're *cleaning up*. Think of it like breaking down camp after a great trip. You set up tents, a fire pit, and a cooking station (your pipeline, stacks, and repository). Now it's time to pack everything away so you don't leave a mess (or keep paying for resources you're no longer using).

### 💡 Key Concept: Cloud Resource Cleanup

Imagine you rented a bunch of equipment for a party — tables, chairs, a sound system. When the party's over, you need to return everything or you'll keep getting charged. Cloud resources work the same way. Every S3 bucket (a storage container), Lambda function (a small program that runs on demand), and CodePipeline (your automated assembly line) costs money while it exists. Cleanup means telling AWS "I'm done with all of this, please take it back."

The tricky part? Some items depend on others. You can't return the tablecloth if it's still on the table. Similarly, you need to empty S3 buckets before deleting them, and remove application stacks before tearing down the pipeline that created them.

### 🔍 How Does It Work?

1. **Empty the storage first** — S3 buckets (storage containers) can't be deleted if they still have files inside. So we list them, find the ones our pipeline created, and clear them out.
2. **Tear down the stacks** — CDK (our infrastructure tool) has a `destroy` command that reverses everything it built. It reads the same blueprint it used to create resources and removes them in the right order.
3. **Clean up stragglers** — Some stacks were deployed *by the pipeline itself* (not directly by us), so CDK might not know about them. We delete those manually through CloudFormation (the AWS service that manages resource creation and deletion).
4. **Verify everything is gone** — We double-check that no pipelines, stacks, or repositories are left behind. Think of it as doing a final walkthrough of the campsite before you leave.

### 🔧 Our Game Plan

```
Empty S3 Buckets → cdk destroy --all → Delete leftover stacks manually
        ↓
Delete CodeCommit Repo → Delete CDK Bootstrap Stack
        ↓
Verify: No pipelines → No stacks → No repo → No surprise charges
```

### 💬 Quick Check

Why do you think we need to empty S3 buckets *before* trying to delete the stacks that contain them? (Hint: think about trying to throw away a box that still has stuff inside it.)

---

## 📚 Task 10.1 Mini Lecture — Deleting Pipeline and Application Stacks

### 🎯 What Are We Doing?

We're dismantling the main structures we built — the pipeline itself and the application environments (Dev and Prod). It's like tearing down a factory and the two warehouses it was shipping products to.

### 💡 Key Concept: Stack Deletion Order

Think of a stack of plates. You can't pull one from the middle without risking a crash. AWS CloudFormation stacks (blueprints that describe a group of cloud resources) work similarly — some resources inside them depend on others. CDK's `destroy` command is smart enough to figure out the right order, but there's a catch: the pipeline *itself* created some stacks (the Dev and Prod application stacks). Since CDK didn't directly create those, it might not be able to delete them. That's when we step in and delete them manually, like pulling out the last few plates by hand.

Also, S3 buckets (storage containers) have a safety rule: they refuse to be deleted if they still contain files. So we have to empty them first — like dumping out a trash can before you can throw the can away.

### 🔍 How Does It Work?

1. **Find pipeline S3 buckets** — We list all S3 buckets and filter for ones with "pipeline" in the name.
2. **Empty each bucket** — Remove all files inside so the bucket can be deleted.
3. **Run `cdk destroy --all`** — This tells CDK to reverse-engineer its blueprints and delete every resource it created.
4. **Handle leftovers** — If the pipeline-deployed stacks (Dev and Prod application stacks) weren't caught by CDK, we delete them directly through CloudFormation.

### 🔧 Our Game Plan

```
List S3 buckets → Empty pipeline buckets
        ↓
cdk destroy --all --force
        ↓
Check for leftover stacks → Manually delete Dev & Prod stacks if needed
```

### 💬 Quick Check

Why might `cdk destroy` not be able to delete the Dev and Prod application stacks? (Hint: who created them — you, or the pipeline?)

---

## 📚 Task 10.2 Mini Lecture — Deleting the Repository and Bootstrap Resources

### 🎯 What Are We Doing?

We're removing the last two pieces of infrastructure: the CodeCommit repository (where our code lived) and the CDK bootstrap stack (the foundational scaffolding CDK needs to operate in your AWS account). Think of it as returning the filing cabinet where you stored your blueprints, and then removing the workbench you used to build everything.

### 💡 Key Concept: Bootstrap Resources

When you first set up CDK, you ran `cdk bootstrap`. That created a special CloudFormation stack called "CDKToolkit" which includes an S3 bucket for storing deployment assets, IAM roles (permission badges) for CDK to use, and other supporting resources. It's like the foundation of a workshop — every project you build with CDK in that account and region relies on it.

Deleting the CDKToolkit stack is a bigger decision than deleting your project. If you have *other* CDK projects in the same account and region, removing it would break them. It's like tearing up the workshop floor — fine if you're done with all projects, but a problem if you're still working on something else.

### 🔍 How Does It Work?

1. **Delete the CodeCommit repository** — This removes the remote code repository and all its commit history. Your local copy of the code still exists on your machine, but the AWS-hosted version is gone forever.
2. **Delete the CDK bootstrap stack** — This removes the CDKToolkit CloudFormation stack, including its S3 bucket and IAM roles. Only do this if you're sure no other CDK apps depend on it.
3. **Verify** — Confirm both resources are gone by trying to access them (they should return errors).

### 🔧 Our Game Plan

```
Delete CodeCommit repo ("pipeline-app-repo")
        ↓
Delete CDKToolkit bootstrap stack
        ↓
Verify both are gone
```

### 💬 Quick Check

Why should you think twice before deleting the CDKToolkit bootstrap stack? (Hint: does anything else in your account depend on it?)

---

## 📚 Task 10.3 Mini Lecture — Verifying the Cleanup

### 🎯 What Are We Doing?

We're doing the final walkthrough — making sure every resource we created during this project is actually gone. It's like checking every room in a rental house before you hand back the keys. You want to make sure you didn't leave anything behind that could cost you (literally, since AWS charges for resources that still exist).

### 💡 Key Concept: Verification After Deletion

Deleting something in the cloud doesn't always mean it's instantly gone. Some deletions take time (CloudFormation stacks can take minutes to fully tear down), and some might silently fail if there's a dependency you missed. Verification is your safety net — it confirms the cleanup actually worked. Think of it like flushing a document through a shredder and then checking the bin to make sure the pieces are actually there.

### 🔍 How Does It Work?

1. **Check for pipelines** — List all CodePipeline pipelines in the account. Our pipeline should no longer appear.
2. **Check for stacks** — List all active CloudFormation stacks. None of our project stacks (PipelineStack, Dev, Prod, CDKToolkit) should show up.
3. **Check for the repository** — Try to describe the CodeCommit repo. It should return an error saying it doesn't exist.
4. **Cost awareness** — A reminder to check AWS Cost Explorer in a day or two to confirm no lingering charges from CodeBuild runs, S3 storage, or Lambda invocations.

### 🔧 Our Game Plan

```
List pipelines → should be empty or not contain ours
        ↓
List CloudFormation stacks → none of ours should remain
        ↓
Describe CodeCommit repo → should return "not found" error
        ↓
Remind: check Cost Explorer in 1-2 days
```

### 💬 Quick Check

Why is it a good idea to check AWS Cost Explorer a day or two after cleanup, even if all the verification commands look clean? (Hint: some charges are calculated after the fact.)
