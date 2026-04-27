# 📚 Task 2.3 Mini Lecture — Configure CDK App Entry Point

## 🎯 What Are We Building?

Now we're going to wire up the "front door" of our CDK application. Right now, our entry point file (`bin/pipeline-app.ts`) just creates an empty CDK App — like having a building with a front door but no rooms inside. We're going to tell it to create our first "room": the PipelineStack (the stack that will eventually hold our entire CI/CD pipeline).

## 💡 Key Concept: The CDK App Entry Point

Think of a CDK App like a company headquarters building:

- The **App** is the building itself — the container for everything
- Each **Stack** is a department inside the building (like HR, Engineering, Finance) — each one manages a group of related resources
- The **entry point file** is the building's reception desk — it's where visitors (CDK commands) arrive and get directed to the right department
- **Props** (properties) are like the department's setup instructions — "you're in this office, on this floor, with this budget." For our PipelineStack, the props include which AWS account and region to use, what to name the code repository, and which branch to watch.

Without telling the App about the PipelineStack, CDK wouldn't know there's anything to build!

## 🔍 How Does It Work?

1. The entry point file creates a CDK App — this is the top-level container that holds all your stacks.

2. It then creates a PipelineStack inside that App, passing along configuration like your AWS account ID (`628326705801`) and region (`us-east-1`). This tells CDK where to deploy things.

3. It also passes pipeline-specific settings: the repository name (`pipeline-app-repo`) and the branch to watch (`main`). These will be used later when the pipeline stack creates the CodeCommit repository and source trigger.

4. When you run `cdk synth`, CDK walks through the App, finds the PipelineStack, and translates it into a CloudFormation template — the actual instructions AWS uses to create resources.

## 🔧 Our Game Plan

```
Update bin/pipeline-app.ts with environment config
        ↓
Create a minimal PipelineStack in lib/pipeline-stack.ts
        ↓
Wire them together (App → PipelineStack with props)
        ↓
Run cdk synth to verify it produces a valid template
        ↓
✅ CDK app entry point configured!
```

## 💬 Quick Check

Why do we need to pass the AWS account ID and region to the PipelineStack? (Answer: Because CDK needs to know which AWS account and which geographic region to deploy resources into — just like a delivery service needs a specific address to know where to drop off a package!)
