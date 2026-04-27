# 📚 Task 3.1 Mini Lecture — Create PipelineStack with CodeCommit Repository

## 🎯 What Are We Building?

We're upgrading our PipelineStack (the main container that holds all our pipeline pieces) to actually do something — specifically, it will create a CodeCommit repository. Think of this as setting up a shared locker where your team stores all the project files, and anyone can grab the latest version.

## 💡 Key Concept: The Shared Locker

Imagine you're working on a group school project. Instead of emailing files back and forth (chaos!), you all agree to put everything in one shared locker. Whenever someone updates a file, they put the new version in the locker. Everyone always knows where to find the latest work.

That's what CodeCommit is — a Git repository (a version-controlled shared folder) hosted by AWS. Our pipeline will watch this locker and spring into action whenever new code appears.

The `createRepository()` method is like the instruction that says "hey AWS, please build me a locker with this name."

## 🔍 How Does It Work?

1. We define a `PipelineStack` class (a blueprint for our pipeline infrastructure) that extends `cdk.Stack` (inherits all the basic CDK stack abilities)
2. The constructor (the setup function that runs when the stack is created) accepts props (properties/settings) including the repository name and which branch to watch
3. The `createRepository()` method uses the `codecommit.Repository` construct (a CDK building block) to tell AWS "create a CodeCommit repo with this name"
4. We store a reference to the repository so other parts of the pipeline can use it later — like keeping the locker key handy

## 🔧 Our Game Plan

```
PipelineStack constructor receives props
    │
    ├──→ Store repositoryName + mainBranch from props
    │
    └──→ createRepository()
              │
              └──→ AWS CodeCommit Repository created
                        │
                        └──→ Clone URL available for later use
```

## 💬 Quick Check

Why do you think we pass the repository name as a prop (a setting from outside) rather than hardcoding it directly inside the stack? (Hint: what if you wanted to reuse this same stack for a different project?)
