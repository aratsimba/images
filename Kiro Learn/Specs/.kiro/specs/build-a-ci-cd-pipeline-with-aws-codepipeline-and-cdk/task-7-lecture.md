# Task 7 — Mini Lectures: Validation Steps — Linting and Security Scanning

---

## 📚 Lecture 1: Task 7 Overview + Task 7.1 — Create Lint and Security Scan Steps

### 🎯 What Are We Building?

We're adding two automated quality checks to our pipeline — a linter (a tool that checks your code for style mistakes and common errors) and a security scanner (a tool that looks for security problems in your cloud templates). Think of these as two inspectors that review your work before it goes live.

### 💡 Key Concept (with analogy)

Imagine you're submitting an essay for publication. Before it gets printed, two editors review it at the same time:

- **Editor 1 (the Linter)** checks grammar, spelling, and formatting — making sure your writing follows the style guide.
- **Editor 2 (the Security Scanner)** checks the content for anything risky or problematic — like accidentally including private information.

Both editors work in parallel (at the same time), so the review is fast. If either editor finds a problem, the essay doesn't get published until you fix it. That's exactly what our pipeline validation steps do for code.

### 🔍 How Does It Work? (3-4 steps)

1. **Define the checks** — We create two "steps" (small jobs) in our pipeline configuration. One runs the linting tool (ESLint), the other runs the security tool (cfn-nag).
2. **Wire them into the pipeline** — We attach both steps as "pre" actions (things that happen before) on the Dev deployment stage. This means they run before any code gets deployed.
3. **Parallel execution** — Because both steps are added to the same "pre" list, the pipeline runs them side by side, saving time.
4. **Gate behavior** — If either check fails, the pipeline stops. No broken or insecure code reaches your environments.

### 🔧 Our Game Plan (visual flow with arrows)

```
Install ESLint (linting tool) into the project
        ↓
Add a "lint" script to package.json
        ↓
Create createLintStep() → runs "npm ci && npm run lint"
        ↓
Create createSecurityScanStep() → installs cfn-nag and scans templates
        ↓
Attach both steps as "pre" actions on the Dev stage
        ↓
Verify with cdk synth that the pipeline includes both validation actions
```

### 💬 Quick Check

Why do we add the lint and security scan as "pre" steps on the Dev stage instead of after it? (Hint: think about what happens if the checks find a problem — would you want broken code already deployed?)

---

## 📚 Lecture 2: Task 7.2 — Wiring Validation Into the Pipeline

### 🎯 What Are We Building?

Now that we've created the two inspector tools (lint step and security scan step), we need to plug them into the actual pipeline so they run automatically. We're going to attach them as "pre" steps (things that happen before) on the Dev deployment stage.

### 💡 Key Concept (with analogy)

Think of a restaurant kitchen. Before a dish goes out to the dining room (deployment), it passes through a quality station where two checkers work side by side — one checks presentation, the other checks temperature. Both work at the same time (in parallel), and if either says "not ready," the dish goes back. That's what "pre" steps do on a pipeline stage — they're the quality station that runs before deployment happens.

### 🔍 How Does It Work? (3-4 steps)

1. **Refactor the Dev stage setup** — We modify the `addDevStage()` method so it also accepts the lint and security scan steps.
2. **Pass steps as "pre" options** — When we call `pipeline.addStage(devStage, { pre: [...] })`, the pipeline knows to run those steps before the Dev deployment actions.
3. **Parallel execution** — Because both steps are in the same "pre" array, CodePipeline runs them at the same time — no waiting for one to finish before the other starts.
4. **Verify with synth** — We run `cdk synth` to confirm the generated CloudFormation template (the blueprint for our cloud resources) includes both validation actions.

### 🔧 Our Game Plan (visual flow with arrows)

```
Import createLintStep and createSecurityScanStep into pipeline-stack.ts
        ↓
Refactor addDevStage() to include pre steps
        ↓
Pass [lintStep, securityScanStep] as pre options on the Dev stage
        ↓
Run cdk synth to verify the pipeline template includes both actions
```

### 💬 Quick Check

If the lint step passes but the security scan step fails, does the Dev deployment still happen? (Hint: both must pass — the pipeline only proceeds when all "pre" steps succeed.)
