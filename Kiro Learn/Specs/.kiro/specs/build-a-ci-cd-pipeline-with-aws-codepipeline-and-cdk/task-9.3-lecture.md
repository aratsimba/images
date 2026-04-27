# Task 9.3 — Mini Lecture

## 📚 Task Mini Lecture

### 🎯 What Are We Building?

We're not building anything new this time — we're *breaking things on purpose* to make sure our pipeline catches mistakes. Think of it as a fire drill for your CI/CD pipeline. We want to confirm that when something goes wrong, the pipeline stops and doesn't let bad code reach your users.

### 💡 Key Concept: Failure Propagation

Imagine a factory assembly line making toys. There are quality inspectors at different stations along the line. If an inspector finds a broken toy, they hit a big red button and the whole line stops — no broken toys get shipped to stores.

Your CI/CD pipeline works the same way. Each stage (building, linting, security scanning, approval) is like an inspector. If any inspector finds a problem, the pipeline halts and nothing gets deployed. This is called "failure propagation" — a failure at one stage *propagates* (spreads) to stop everything downstream.

### 🔍 How Does It Work?

1. **Break the build** — We'll introduce a deliberate typo in the Lambda code (the small program our pipeline deploys). When the pipeline tries to compile it, the build stage will fail and everything stops. This proves the pipeline won't deploy broken code.

2. **Break the linter** — We'll fix the typo but introduce a code style violation (like leaving a messy room when the rules say "keep it tidy"). The linting step (an automated code style checker) will catch it and halt the pipeline before deployment.

3. **Reject the approval** — We'll let the pipeline run successfully all the way to the manual approval gate (the human checkpoint before production). Then we'll click "Reject" instead of "Approve" and confirm that the production deployment never happens.

4. **Clean up** — After each test, we revert our intentional mistakes so the code is back to a healthy state.

### 🔧 Our Game Plan

```
Introduce syntax error → Push → Watch build FAIL → Pipeline stops ✅
        ↓
Revert error, add lint violation → Push → Watch lint FAIL → Pipeline stops ✅
        ↓
Revert violation, push clean code → Pipeline runs → Reject approval → Prod NOT deployed ✅
        ↓
All failure scenarios verified! 🎉
```

### 💬 Quick Check

If the linting step fails, should the pipeline continue and deploy your code to the Dev environment?

*(Hint: think about the factory inspector analogy — what happens when they find a problem?)*

**Answer:** No — just like a factory inspector hitting the big red button, a linting failure halts the pipeline and prevents deployment to any environment.
