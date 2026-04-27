# Task 9 — Mini Lectures, Game Plans & Quick Checks

---

## 📚 Task 9 (Parent) — End-to-End Pipeline Verification

### 🎯 What Are We Building?

We've spent the previous tasks building an entire automated pipeline — think of it like a factory assembly line that takes your code, checks it for quality, and ships it out to where people can use it. Now it's time for the grand finale: we're going to actually *use* the pipeline end-to-end. We'll make a small change to our application, push it through the pipeline, and watch it travel through every stage until it's live in both our Dev and Prod environments (the "testing area" and the "real deal" area).

### 💡 Key Concept: End-to-End Verification

Think of this like a dress rehearsal for a play. You've built the stage, hung the lights, made the costumes, and rehearsed individual scenes. But you haven't yet run the *entire show* from curtain up to curtain down with everything working together. That's what end-to-end verification is — running the whole thing, start to finish, to make sure every piece connects smoothly to the next.

In our case, the "show" is: code change → source pickup → build → self-mutation check → linting & security scan → deploy to Dev → manual approval → deploy to Prod.

### 🔧 Our Game Plan

```
Change Lambda message ("Hello CI/CD!")
        ↓
Commit & push to CodeCommit
        ↓
Pipeline triggers automatically
        ↓
Source → Build → Self-Mutation → Lint + Security Scan
        ↓
Deploy to Dev ✅
        ↓
Manual Approval (you click "Approve")
        ↓
Deploy to Prod ✅
        ↓
Invoke both Lambdas → Confirm new message 🎉
```

### 💬 Quick Check

If the linting step (code style checker) finds a problem during the pipeline run, what do you think happens — does the pipeline keep going and deploy anyway, or does it stop?

*(Answer: It stops! That's the whole point of having quality gates in the pipeline — bad code never reaches deployment.)*

---

## 📚 Subtask 9.1 — Trigger Full Pipeline Execution

### 🎯 What Are We Building?

In this subtask, we're making a small change to our Lambda function (a tiny program that runs in the cloud) and pushing it through the pipeline. Think of it as dropping a package onto a conveyor belt and watching it pass through every checkpoint on its way to the shipping dock.

### 💡 Key Concept: Triggering a Pipeline

Imagine you have a mailbox at the end of your driveway. Every time you put a letter in it and raise the flag, the mail carrier picks it up and delivers it. Our CodeCommit repository (code storage) works the same way — every time we push new code, the pipeline automatically "sees" the change and starts running. No buttons to press, no manual steps. That's the magic of a CI/CD trigger.

### 🔧 Our Game Plan

```
Edit lambda/index.ts → change message
        ↓
git add → git commit → git push
        ↓
Pipeline auto-triggers
        ↓
Source ✅ → Build ✅ → Self-Mutation ✅ → Lint + Security ✅ → Dev Deploy ✅
        ↓
Pipeline pauses at Manual Approval ⏸️ (we'll handle this next)
```

### 💬 Quick Check

Why don't we need to manually start the pipeline after pushing code?

*(Answer: Because the pipeline is connected to the CodeCommit repository and is configured to automatically trigger whenever new code is pushed to the main branch!)*

---

## 📚 Subtask 9.2 — Approve and Verify Production Deployment

### 🎯 What Are We Building?

We're not building anything new here — we're *verifying* that everything we built actually works! This is the final confirmation step. We need to check that the Prod deployment went through and then actually call our Lambda functions in both Dev and Prod to confirm they return the updated "Hello CI/CD!" message.

### 💡 Key Concept: Invoking a Lambda Function

Think of a Lambda function like a vending machine. You put in a request (press a button), and it gives you back a response (drops a snack). When we "invoke" a Lambda, we're essentially pressing that button and checking what comes out. If the vending machine was recently restocked (our code was deployed), the snack should be the new flavor we put in — in our case, the message "Hello CI/CD!" instead of the old "Hello from pipeline!"

The manual approval step is like a security guard at the door of the production warehouse. Before anything gets shipped to real customers, someone has to say "yes, this looks good, let it through."

### 🔧 Our Game Plan

```
Confirm Prod stage = Succeeded ✅
        ↓
Invoke Dev Lambda → expect "Hello CI/CD!"
        ↓
Invoke Prod Lambda → expect "Hello CI/CD!"
        ↓
Both match? → End-to-end verification complete! 🎉
```

### 💬 Quick Check

Why do we check *both* the Dev and Prod Lambda functions, not just one?

*(Answer: Because they're deployed to separate environments! We want to confirm the pipeline correctly deployed the updated code to each environment independently.)*
