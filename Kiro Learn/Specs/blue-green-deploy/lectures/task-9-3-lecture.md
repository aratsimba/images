# 📚 Task 9.3 Mini Lecture — Property Test: Rollback Preserves Blue Environment

## 🎯 What Are We Building?

We're writing a "property test" — a special kind of test that checks whether a rule about our system always holds true. Specifically, we want to verify this rule: **when a deployment fails, the original (blue) environment must stay intact and keep serving traffic**. This is the safety net that makes blue-green deployments trustworthy.

## 💡 Key Concept: Property-Based Testing

Think of it like a fire drill at a building. You don't just run one drill and call it safe — you run drills under different conditions (different floors, different times of day, different numbers of people) and check that the same rule always holds: **everyone gets out safely**.

A property test works the same way. Instead of testing one specific scenario, we define a *property* (a rule that must always be true) and then check it across a variety of conditions. Our property here is: "If a deployment fails for any reason, traffic must remain on the blue environment — the users never see downtime."

Property-based testing (PBT) is different from regular testing because:
- Regular test: "When the validate script exits with code 1, rollback happens" (one specific case)
- Property test: "For ANY failure during deployment, the blue environment is preserved" (a universal rule)

## 🔍 How Does It Work?

1. **Define the property** — We state the rule formally: "After a failed deployment, the ALB (load balancer — the traffic cop that sends users to the right servers) must still be routing to the original blue instances."

2. **Check the evidence** — After triggering a failing deployment, we look at the deployment history and status. Did CodeDeploy report a failure? Did it trigger a rollback? Is the blue environment still healthy?

3. **Verify traffic routing** — We check that the ALB target group (the list of servers receiving traffic) still has healthy instances registered — meaning users are still being served.

4. **Assert the property** — We combine all the evidence into a pass/fail verdict. If any check fails, the property is violated and we know our rollback safety net has a hole.

## 🔧 Our Game Plan

```
Define Property (blue env preserved on failure)
        ↓
Query Deployment History (find failed deployments)
        ↓
Check Rollback Status (was rollback triggered?)
        ↓
Verify ALB Target Health (are blue instances healthy?)
        ↓
Assert Property Holds ✓ or ✗
```

## 💬 Quick Check

If a deployment fails but the load balancer is still sending traffic to the original servers, is that a good thing or a bad thing?

**Answer**: That's exactly the behavior we *want* — it means users never noticed anything went wrong! The blue environment stayed intact and kept serving traffic while the failed green deployment was cleaned up. That's the whole point of blue-green deployments.
