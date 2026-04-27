# 📚 Task 3.2 Mini Lecture — Create Synth Step and Pipeline

## 🎯 What Are We Building?

Now we're wiring up the actual pipeline — the conveyor belt that moves code from the repository through the build process. We're creating two things:

1. A "synth step" (the build instructions that tell AWS how to compile our project)
2. The pipeline itself (the CodePipeline resource that orchestrates everything)

This is where the magic happens — after this, pushing code to your repository will automatically kick off a build.

## 💡 Key Concept: The Recipe Card and the Kitchen

Think of a restaurant kitchen. The chef doesn't memorize every dish — they follow recipe cards. Each recipe card says things like "first, gather ingredients" → "then, mix them" → "finally, plate the dish."

Our synth step is like a recipe card. It tells CodeBuild (the kitchen):
- "First, install all the project dependencies" (`npm ci` — like gathering ingredients)
- "Then, compile the TypeScript code" (`npm run build` — like mixing ingredients)
- "Finally, synthesize the CDK app into CloudFormation templates" (`npx cdk synth` — like plating the finished dish)

The pipeline is the kitchen manager — it reads the recipe card, hands it to the right cook (CodeBuild), and makes sure everything happens in the right order.

We put the recipe card in its own file (`buildspec-configs.ts`) so it's easy to find and reuse — just like keeping recipe cards in a binder rather than scribbling them on the wall.

## 🔍 How Does It Work?

1. We create a helper file (`buildspec-configs.ts`) with a function called `createSynthStep()` that returns a configured CodeBuildStep (a set of build instructions)
2. The CodeBuildStep specifies three phases: install dependencies, build the project, and synthesize CDK templates — and it tells the pipeline where to find the output (`cdk.out/` directory)
3. In our PipelineStack, we add a `createPipeline()` method that creates a CDK Pipeline, connecting it to our CodeCommit repository as the source and using the synth step as the build instructions
4. CDK Pipelines automatically adds a self-mutation stage (UpdatePipeline) — so if you change the pipeline definition itself, it updates itself before deploying your app. Pretty neat!

## 🔧 Our Game Plan

```
buildspec-configs.ts
    │
    └──→ createSynthStep(source)  →  CodeBuildStep with build instructions
                                          │
pipeline-stack.ts                         │
    │                                     │
    └──→ createPipeline()                 │
              │                           │
              ├── Source: CodeCommit repo ─┘
              │
              ├── Synth: uses the CodeBuildStep from above
              │
              └── Self-Mutation: auto-created by CDK Pipelines!
```

## 💬 Quick Check

The pipeline has a "self-mutation" stage that updates the pipeline itself when you change its code. Why is this useful? (Hint: imagine you want to add a new stage to the pipeline — without self-mutation, how would you deploy that change?)
