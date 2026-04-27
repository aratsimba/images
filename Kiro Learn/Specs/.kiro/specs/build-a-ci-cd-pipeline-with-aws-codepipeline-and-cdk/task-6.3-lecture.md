# 📚 Task 6.3 Mini Lecture — Property Test: Pipeline Stage Ordering

## 🎯 What Are We Building?

We're writing a "property test" — a special kind of test that checks whether a rule (a "property") always holds true about our pipeline. Specifically, we want to verify that our pipeline stages always appear in the correct order: the Dev environment gets deployed before the Prod environment, and a manual approval gate always sits between them.

## 💡 Key Concept: Property Testing (with analogy)

Think of a property test like a building inspector checking a house. The inspector doesn't care what color you painted the walls — they care about structural rules: "Is the foundation below the first floor? Is the roof above the second floor?" These rules must always be true, no matter what the house looks like.

In our case, the "structural rule" is: the pipeline stages must always flow in a specific order — Source → Build → Self-Update → Validation/Dev → Approval → Prod. If someone accidentally rearranges the stages, this test catches it, just like an inspector would catch a roof below a foundation.

## 🔍 How Does It Work?

1. We create the pipeline stack in a test environment (no real AWS account needed — CDK can "synthesize" everything locally into a CloudFormation template, which is like a blueprint).
2. We use CDK's `assertions` library (a toolkit for inspecting those blueprints) to look at the generated template.
3. We find all the pipeline stages in the template and check their order.
4. We verify that the "ManualApproval" step appears before the Prod deployment — confirming the approval gate is in place.

## 🔧 Our Game Plan

```
Instantiate PipelineStack in test
        ↓
Synthesize to CloudFormation template
        ↓
Extract pipeline stage definitions
        ↓
Assert: Dev stage comes before Prod stage
        ↓
Assert: ManualApproval exists before Prod deploy
```

## 💬 Quick Check

Why do we test stage ordering instead of just trusting the code? Because someone could accidentally swap `addDevStage()` and `addProdStageWithApproval()` — and without this test, code would deploy straight to production without going through Dev first!
