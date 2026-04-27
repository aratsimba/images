# Task 5 - Application Stage and Stack

## What was done
- Created ApplicationStack (`lib/application-stack.ts`) with a Lambda function (Node.js 18.x, `index.handler`)
- Created Lambda handler (`lambda/index.ts`) returning `{ statusCode: 200, body: "Hello from pipeline!" }`
- Created ApplicationStage (`lib/application-stage.ts`) wrapping ApplicationStack with environment/stage name props
- Verified `cdk synth` succeeds with all new files

## Files created
- `cicd-pipeline/lib/application-stack.ts`
- `cicd-pipeline/lambda/index.ts`
- `cicd-pipeline/lib/application-stage.ts`

## Issues
- None
