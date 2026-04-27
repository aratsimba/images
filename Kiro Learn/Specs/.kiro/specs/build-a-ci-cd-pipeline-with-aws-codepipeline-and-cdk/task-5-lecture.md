# Task 5 — Mini Lectures, Game Plans & Quick Checks

---

## 📚 Task 5: Application Stage and Stack

### 🎯 What Are We Building?
We're creating the "thing" our pipeline will actually deploy — an application! So far we've built the conveyor belt (the pipeline), but we haven't put anything on it yet. Now we're going to create a simple application (a small program that runs in the cloud) and package it so the pipeline knows how to deliver it to different environments (like "Dev" for testing and "Prod" for real users).

### 💡 Key Concept: Stages and Stacks
Imagine you're shipping a gift. The gift itself is your **Application Stack** (the actual cloud resources — in our case, a small function that says "Hello from pipeline!"). But to ship it, you need to put it in a box with a label. That labeled box is your **Application Stage** — it wraps your application and tells the pipeline *where* to deliver it (Dev environment? Prod environment?).

So: **Stack** = the gift (your actual app), **Stage** = the labeled shipping box (tells the pipeline which environment to deploy to).

### 🔧 Our Game Plan
```
Lambda handler code (the actual program)
        ↓
ApplicationStack (packages the Lambda as a cloud resource)
        ↓
ApplicationStage (wraps the stack with an environment label)
        ↓
Ready for the pipeline to deploy! (next task)
```

### 💬 Quick Check
If the ApplicationStack is the "gift" and the ApplicationStage is the "labeled shipping box," what happens if you put the same gift in two different boxes — one labeled "Dev" and one labeled "Prod"?

**Answer:** You get the same application deployed to two different environments — which is exactly what a CI/CD pipeline does!

---

## 📚 Subtask 5.1: Create ApplicationStack

### 🎯 What Are We Building?
The ApplicationStack — the actual cloud application that our pipeline will deploy. This includes a Lambda function (a tiny program that lives in the cloud and runs only when called, like a light that turns on only when you flip the switch).

### 💡 Key Concept: Lambda Functions
Think of a Lambda function like a food truck. A restaurant (a traditional server) is always open, always using electricity, always paying rent — even when no customers are there. A food truck (Lambda) only shows up when there's demand, serves the food, and then parks. You only pay for the time it's actually cooking. That's what makes Lambda so popular for simple tasks.

### 🔍 How Does It Work?
1. We create a handler file — this is the recipe the food truck follows. Ours just says: "When someone asks, reply with 'Hello from pipeline!'"
2. We define an ApplicationStack — this is like the business license and parking permit for the food truck. It tells AWS: "Create a Lambda function, use this handler code, and here's how to run it."
3. The stack uses a `createLambdaFunction` method (a reusable set of instructions) to set up the Lambda with the right settings: which programming language to use (Node.js 18), which file to run (index.handler), and where to find the code (the lambda/ folder).
4. When CDK synthesizes (converts our TypeScript into a CloudFormation template — the blueprint AWS reads), it packages everything up so the pipeline can deploy it.

### 🔧 Our Game Plan
```
Create lambda/ folder with index.ts handler
        ↓
Define ApplicationStack class in lib/application-stack.ts
        ↓
Implement createLambdaFunction() method
        ↓
Call it from the constructor → Lambda is defined!
```

### 💬 Quick Check
Why do we put the Lambda handler code in a separate `lambda/` folder instead of inside the stack file?

**Answer:** Because the stack file describes *what* to create (the infrastructure), while the handler file is the *actual code* the Lambda runs. They're two different concerns — like a building blueprint vs. the furniture inside.

---

## 📚 Subtask 5.2: Create ApplicationStage

### 🎯 What Are We Building?
The ApplicationStage — the "labeled shipping box" from our earlier analogy. We just built the gift (the ApplicationStack with its Lambda function). Now we need to wrap it in a stage so the pipeline knows *which environment* to deliver it to.

### 💡 Key Concept: Stages as Deployment Units
Imagine a theater production. The **stage** is the physical space where the show happens — it has a name (like "Main Stage" or "Rehearsal Stage"), a location, and everything needed to put on the performance. In CDK Pipelines, a Stage works the same way: it's a named container that holds one or more stacks (the "performances") and tells the pipeline where to deploy them.

The beauty is you can reuse the same show (ApplicationStack) on different stages — one called "Dev" for rehearsals, one called "Prod" for the real audience. Same show, different venues.

### 🔍 How Does It Work?
1. We create an ApplicationStage class that extends CDK's Stage (a built-in concept that CDK Pipelines understands as "a group of stacks to deploy together").
2. The stage accepts props (configuration settings) including the target environment (which AWS account and region) and a stage name (like "Dev" or "Prod").
3. Inside the stage's constructor (the setup instructions that run when a stage is created), we create an ApplicationStack — this is where the stage says "here's what I want deployed."
4. When the pipeline encounters this stage, it knows to deploy everything inside it to the specified environment. CDK handles all the CloudFormation orchestration automatically.

### 🔧 Our Game Plan
```
Define ApplicationStage class
        ↓
Accept environment + stageName in constructor
        ↓
Create ApplicationStack inside the stage
        ↓
Verify with cdk synth → stage appears in output!
```

### 💬 Quick Check
If you create two ApplicationStages — one named "Dev" and one named "Prod" — how many Lambda functions will eventually exist in your AWS account?

**Answer:** Two! One in each environment. The same ApplicationStack definition gets deployed separately for each stage, creating independent copies of the resources.
