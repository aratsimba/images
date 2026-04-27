# Task 9.2 - Approve and Verify Production Deployment

## What Was Done
- Confirmed Prod stage status = Succeeded in pipeline execution
- Found Lambda function names: `Dev-ApplicationStack-AppFunction` and `Prod-ApplicationStack-AppFunction`
- Invoked Dev Lambda → returned `{"statusCode":200,"body":"Hello CI/CD!"}` ✅
- Invoked Prod Lambda → returned `{"statusCode":200,"body":"Hello CI/CD!"}` ✅
- Both environments reflect the updated code change

## Issues
- Manual approval (PromoteToProd) was already approved from the pipeline run, so no manual approval step was needed during this verification
- AWS CLI v1 doesn't support `--cli-binary-format` flag; removed it for successful invocation
