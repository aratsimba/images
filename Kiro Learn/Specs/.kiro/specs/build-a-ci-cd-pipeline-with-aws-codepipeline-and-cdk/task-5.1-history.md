# Task 5.1 - Create ApplicationStack

## What was done
- Created `lib/application-stack.ts` with `ApplicationStack` class extending `cdk.Stack`
- Implemented `createLambdaFunction(functionName)` method with Node.js 18.x runtime, `index.handler`, and code from `lambda/` directory
- Created `lambda/index.ts` handler returning `{ statusCode: 200, body: "Hello from pipeline!" }`
- Constructor derives function name from stack ID and calls `createLambdaFunction()`

## Files created
- `cicd-pipeline/lib/application-stack.ts`
- `cicd-pipeline/lambda/index.ts`

## Issues
- None
