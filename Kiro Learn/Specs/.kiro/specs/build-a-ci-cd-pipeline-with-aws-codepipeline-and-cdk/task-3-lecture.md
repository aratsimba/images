# 📚 Task 3 Mini Lecture — Pipeline Stack with Source and Build Stages

## 🎯 What Are We Building?

In this task, we're building the core of our CI/CD pipeline — think of it as constructing the main highway that our code will travel along from "just written" to "running in the cloud." Specifically, we're creating two things:

1. A source code repository (a place to store our code, like a shared folder everyone on a team can access)
2. A pipeline that watches that repository and automatically builds our project whenever we push new code

## 💡 Key Concept: The Assembly Line

Imagine a car factory. Raw materials come in one end, and a finished car rolls out the other. Along the way, there are stations — one welds the frame, another paints it, another installs the engine.

Our CI/CD pipeline works the same way:
- The "raw materials" are your code files sitting in a repository (CodeCommit — Amazon's version of a shared code folder)
- The "first station" is the Source Stage — it grabs the latest code when you push changes
- The "second station" is the Build/Synth Stage — it takes your CDK code (infrastructure definitions written in TypeScript) and converts it into CloudFormation templates (the actual blueprints AWS uses to create resources)

The pipeline itself is defined using CDK Pipelines — a special library that makes it easy to set up this whole assembly line with just a few lines of code.

## 🔍 How Does It Work?

1. You push code to the CodeCommit repository (like dropping off materials at the factory door)
2. The pipeline detects the change and starts running automatically (the conveyor belt starts moving)
3. The Build Stage runs `npm ci` (installs all the project's dependencies — like gathering all the tools needed) and then `cdk synth` (converts your CDK code into CloudFormation templates — like turning a sketch into a detailed blueprint)
4. The output (the CloudFormation templates) gets stored as an artifact (a packaged result) that later stages will use to actually deploy your application

## 🔧 Our Game Plan

```
PipelineStack (the main container)
    │
    ├──→ createRepository()  →  CodeCommit Repo (where code lives)
    │
    ├──→ createSynthStep()   →  Build instructions (install deps + synth)
    │         ↓
    └──→ createPipeline()    →  CodePipeline (the assembly line itself)
              │
              ├── Source Stage (watches the repo)
              ├── Build Stage (runs the synth step)
              └── Self-Mutation Stage (auto-created by CDK Pipelines!)
```

We'll also create a separate helper file (`buildspec-configs.ts`) that holds the build instructions — keeping things organized, like having a recipe card separate from the kitchen.

## 💬 Quick Check

Think about it: why do you think we separate the build instructions (the synth step) into their own file instead of putting everything in one big file? (Hint: think about what happens when you want to add more "stations" to the assembly line later — like linting and security scanning.)
