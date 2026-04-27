

# Implementation Plan: Deploy a Microservices Application on Amazon EKS

## Overview

This implementation plan guides learners through deploying a microservices application on Amazon EKS, progressing from infrastructure provisioning through manual deployments, Helm-based packaging, stateful workloads, and CI/CD automation. The plan follows the natural learning progression: first establish the foundational infrastructure (EKS cluster, ECR repositories, and required add-ons), then build and push container images, deploy using raw Kubernetes manifests, expose services via load balancers, graduate to Helm chart deployments, deploy a stateful application, and finally automate everything with GitHub Actions.

The implementation is organized into key phases aligned with the six design components. Phase 1 covers environment setup and infrastructure provisioning (ClusterProvisioner and ImageBuilder). Phase 2 focuses on core Kubernetes deployment patterns using raw manifests and load balancer exposure (ManifestDeployer). Phase 3 introduces Helm-based deployment management (HelmDeployer) and stateful workloads (StatefulDeployer). Phase 4 implements the CI/CD pipeline (CIPipeline). Checkpoints are placed after infrastructure setup and after the manifest/Helm deployment phases to validate progress incrementally.

Key dependencies dictate task ordering: the EKS cluster and ECR repositories must exist before images can be pushed; images must be in ECR before deployments can reference them; the AWS Load Balancer Controller and EBS CSI driver must be installed before load balancer services and stateful workloads can function. The two example microservices — a Flask-based frontend-api and backend-api — are intentionally simple so learners can focus on deployment mechanics rather than application logic.

## Tasks

- [ ] 1. Prerequisites - Environment Setup
  - [ ] 1.1 AWS Account and Credentials
    - Ensure you have an active AWS account with admin access
    - Configure AWS CLI: `aws configure` (set access key, secret key, default region, output format)
    - Verify access: `aws sts get-caller-identity`
    - Note your AWS account ID: `export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`
    - _Requirements: (all)_
  - [ ] 1.2 Required Tools and SDKs
    - Install AWS CLI v2: verify with `aws --version`
    - Install Docker: verify with `docker --version`
    - Install `eksctl`: verify with `eksctl version`
    - Install `kubectl`: verify with `kubectl version --client`
    - Install `helm`: verify with `helm version`
    - Install Python 3.12 for example microservices: verify with `python3 --version`
    - Ensure you have a GitHub account with a repository for the project
    - _Requirements: (all)_
  - [ ] 1.3 AWS Region and Resource Configuration
    - Set default region: `export AWS_DEFAULT_REGION=us-east-1`
    - Verify service quotas for EKS clusters (default limit is typically sufficient)
    - Verify IAM permissions allow creating EKS clusters, ECR repositories, IAM roles, and ELB resources
    - _Requirements: (all)_

- [ ] 2. Provision EKS Cluster and ECR Repositories
  - [ ] 2.1 Create the EKS cluster with worker nodes
    - Create `infrastructure/cluster_provisioner.sh` implementing the ClusterProvisioner interface
    - Define ClusterConfig values: cluster name `eks-microservices-lab`, region `us-east-1`, 2 nodes, `t3.medium` instance type, Kubernetes version `1.29`
    - Run: `eksctl create cluster --name eks-microservices-lab --region us-east-1 --nodes 2 --node-type t3.medium --version 1.29`
    - Implement `verify_cluster_ready`: `kubectl get nodes` — confirm at least 2 nodes in `Ready` state
    - Configure kubeconfig: `aws eks update-kubeconfig --name eks-microservices-lab --region us-east-1`
    - _Requirements: 1.1_
  - [ ] 2.2 Create ECR repositories for both microservices
    - Implement `create_ecr_repository` for both services:
    - `aws ecr create-repository --repository-name eks-lab/frontend-api --region us-east-1`
    - `aws ecr create-repository --repository-name eks-lab/backend-api --region us-east-1`
    - Store ECR URIs: `export FRONTEND_ECR_URI=$(aws ecr describe-repositories --repository-names eks-lab/frontend-api --query 'repositories[0].repositoryUri' --output text)`
    - Verify repositories exist: `aws ecr describe-repositories --repository-names eks-lab/frontend-api eks-lab/backend-api`
    - Confirm worker node IAM role includes `AmazonEC2ContainerRegistryReadOnly` policy for ECR pull access
    - _Requirements: 1.2, 1.3_
  - [ ] 2.3 Install AWS Load Balancer Controller and EBS CSI Driver
    - Implement `install_lb_controller`: create IAM OIDC provider, IAM policy, and service account, then install via Helm: `helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=eks-microservices-lab --set serviceAccountName=aws-load-balancer-controller`
    - Verify controller running: `kubectl get deployment -n kube-system aws-load-balancer-controller`
    - Implement `install_ebs_csi_driver`: create IAM role for EBS CSI driver and install as EKS add-on: `aws eks create-addon --cluster-name eks-microservices-lab --addon-name aws-ebs-csi-driver`
    - Verify EBS CSI driver: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver`
    - _Requirements: 4.1, 6.1_

- [ ] 3. Build Container Images and Push to ECR
  - [ ] 3.1 Create the example microservices
    - Create `services/frontend-api/` with a Flask app (`app.py`) that serves HTTP requests and calls the backend-api via its ClusterIP DNS name
    - Create `services/backend-api/` with a Flask app (`app.py`) that returns JSON responses
    - Create `services/frontend-api/Dockerfile` and `services/backend-api/Dockerfile` using `python:3.12-slim` base image
    - Define MicroserviceConfig for each: frontend-api on port 8080, backend-api on port 8081, 2 replicas each
    - _Requirements: 2.1_
  - [ ] 3.2 Build, tag, and push images to ECR
    - Create `images/image_builder.sh` implementing the ImageBuilder interface
    - Implement `authenticate_ecr`: `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com`
    - Implement `build_image` and `tag_image` for both services:
    - `docker build -t frontend-api:v1.0.0 ./services/frontend-api/`
    - `docker tag frontend-api:v1.0.0 ${FRONTEND_ECR_URI}:v1.0.0`
    - Implement `push_image`: `docker push ${FRONTEND_ECR_URI}:v1.0.0` (repeat for backend-api)
    - Implement `verify_image_in_ecr`: `aws ecr describe-images --repository-name eks-lab/frontend-api --image-ids imageTag=v1.0.0`
    - Verify that pushing an image with an existing tag replaces the previous image
    - _Requirements: 2.1, 2.2, 2.3_

- [ ] 4. Checkpoint - Validate Infrastructure and Images
  - Verify EKS cluster is active: `aws eks describe-cluster --name eks-microservices-lab --query 'cluster.status'`
  - Verify worker nodes are ready: `kubectl get nodes` — expect 2 nodes in `Ready` state
  - Verify ECR repositories contain images: `aws ecr list-images --repository-name eks-lab/frontend-api` and `aws ecr list-images --repository-name eks-lab/backend-api`
  - Verify Load Balancer Controller is running: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
  - Verify EBS CSI driver is running: `kubectl get addon --cluster-name eks-microservices-lab --addon-name aws-ebs-csi-driver`
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Deploy Microservices Using Raw Kubernetes Manifests
  - [ ] 5.1 Create and apply Deployment and ClusterIP Service manifests
    - Create `manifests/` directory and implement ManifestDeployer scripts
    - Create `manifests/backend-api-deployment.yaml`: Deployment with 2 replicas referencing `${BACKEND_ECR_URI}:v1.0.0`, rolling update strategy (`maxSurge: 1`, `maxUnavailable: 0`), container port 8081
    - Create `manifests/backend-api-service.yaml`: Service type ClusterIP exposing port 80 targeting container port 8081
    - Create `manifests/frontend-api-deployment.yaml`: Deployment with 2 replicas referencing `${FRONTEND_ECR_URI}:v1.0.0`, env var `BACKEND_URL=http://backend-api-service` for inter-service communication
    - Create `manifests/frontend-api-service.yaml`: Service type ClusterIP exposing port 80 targeting container port 8080
    - Implement `apply_deployment` and `apply_service`: `kubectl apply -f manifests/`
    - Implement `verify_pods_ready`: `kubectl get pods -l app=frontend-api` and `kubectl get pods -l app=backend-api` — all pods should be `Running` and `Ready`
    - Verify internal DNS communication: `kubectl exec -it <frontend-pod> -- curl http://backend-api-service`
    - _Requirements: 3.1, 3.2_
  - [ ] 5.2 Verify self-healing and rolling updates
    - Test self-healing: delete a pod with `kubectl delete pod <pod-name>` and verify a replacement is created automatically via `kubectl get pods -w`
    - Implement `update_image_tag`: build and push `v2.0.0` image, update `manifests/frontend-api-deployment.yaml` image tag to `v2.0.0`
    - Reapply manifest: `kubectl apply -f manifests/frontend-api-deployment.yaml`
    - Verify rolling update: `kubectl rollout status deployment/frontend-api` — old pods replaced with new pods running `v2.0.0`
    - _Requirements: 3.3, 3.4_
  - [ ] 5.3 Expose microservices via Load Balancer and Ingress
    - Create `manifests/frontend-api-lb-service.yaml`: Service type LoadBalancer with appropriate annotations for NLB provisioning
    - Implement `get_load_balancer_endpoint`: `kubectl get svc frontend-api-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`
    - Create `manifests/ingress.yaml`: Kubernetes Ingress resource with `alb.ingress.kubernetes.io` annotations for ALB with path-based routing (`/frontend` → frontend-api, `/backend` → backend-api)
    - Apply: `kubectl apply -f manifests/ingress.yaml`
    - Implement `get_ingress_endpoint`: `kubectl get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'`
    - Test external access: `curl http://<lb-endpoint>` and `curl http://<alb-endpoint>/frontend` — verify responses from microservices
    - Implement `delete_resources` for cleanup of LoadBalancer and Ingress resources before Helm tasks
    - _Requirements: 4.2, 4.3, 4.4_

- [ ] 6. Deploy Microservices Using Helm Charts
  - [ ] 6.1 Create Helm charts with templated values
    - Create `helm-charts/` directory and implement HelmDeployer scripts
    - Implement `create_chart`: `helm create helm-charts/frontend-api` and `helm create helm-charts/backend-api`
    - Customize chart templates to include templated Deployment, Service, and configurable `values.yaml`
    - Define HelmValues in `values.yaml`: `image.repository` (ECR URI), `image.tag` (`v1.0.0`), `replicaCount` (2), `service.type` (`ClusterIP`), `service.port` (80), `containerPort` (8080)
    - Create a second `values.yaml` for backend-api with `containerPort: 8081`
    - _Requirements: 5.1_
  - [ ] 6.2 Install, upgrade, and rollback Helm releases
    - Clean up previous manifest-based deployments: `kubectl delete -f manifests/` (excluding stateful resources)
    - Implement `install_release`: `helm install frontend-api ./helm-charts/frontend-api --set image.repository=${FRONTEND_ECR_URI} --set image.tag=v1.0.0`
    - Implement `verify_release_status`: `helm status frontend-api` — confirm deployed status and pods running
    - Repeat for backend-api
    - Implement `upgrade_release`: `helm upgrade frontend-api ./helm-charts/frontend-api --set image.tag=v2.0.0 --set replicaCount=3`
    - Verify rolling update and check release history: `helm history frontend-api` — confirm revision 2
    - Implement `rollback_release`: `helm rollback frontend-api 1`
    - Verify rollback restored `v1.0.0` image and original replica count
    - Implement `uninstall_release`: `helm uninstall frontend-api` (for later cleanup)
    - Implement `get_release_history`: verify multiple revisions tracked
    - _Requirements: 5.2, 5.3, 5.4_

- [ ] 7. Checkpoint - Validate Manifest and Helm Deployments
  - Verify Helm releases are deployed: `helm list` — confirm both frontend-api and backend-api releases
  - Verify all pods are running: `kubectl get pods` — all pods in `Running`/`Ready` state
  - Verify Helm rollback worked correctly by checking `helm history <release>` revision numbers
  - Test inter-service communication via ClusterIP DNS
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 8. Deploy a Stateful Application on EKS
  - [ ] 8.1 Create StorageClass and StatefulSet manifests
    - Create `manifests/stateful/` directory and implement StatefulDeployer scripts
    - Define StatefulAppConfig: name `redis`, storage class `ebs-sc`, storage size `5Gi`, 1 replica, mount path `/data`
    - Create `manifests/stateful/storage-class.yaml`: StorageClass named `ebs-sc` with provisioner `ebs.csi.aws.com`, volume binding mode `WaitForFirstConsumer`
    - Implement `apply_storage_class`: `kubectl apply -f manifests/stateful/storage-class.yaml`
    - Create `manifests/stateful/statefulset.yaml`: StatefulSet for Redis with `volumeClaimTemplates` requesting `5Gi` from `ebs-sc`, volume mounted at `/data`
    - Implement `apply_statefulset`: `kubectl apply -f manifests/stateful/statefulset.yaml`
    - Implement `verify_pvc_bound`: `kubectl get pvc` — confirm PVC is `Bound`
    - _Requirements: 6.1_
  - [ ] 8.2 Verify data persistence across pod restarts
    - Write test data to the pod: `kubectl exec redis-0 -- redis-cli SET testkey "hello-eks"`
    - Implement `restart_pod`: `kubectl delete pod redis-0` — wait for replacement pod
    - Implement `verify_data_persistence`: `kubectl exec redis-0 -- redis-cli GET testkey` — verify output is `hello-eks`
    - Confirm replacement pod reattached to the same PersistentVolume
    - Implement `delete_statefulset` for cleanup
    - _Requirements: 6.2, 6.3_

- [ ] 9. Implement CI/CD Pipeline with GitHub Actions
  - [ ] 9.1 Configure GitHub repository and AWS authentication
    - Push project code to a GitHub repository on the `main` branch
    - Define PipelineConfig: branch `main`, region `us-east-1`, cluster `eks-microservices-lab`, namespace `default`
    - Set up AWS authentication for GitHub Actions: create an IAM OIDC identity provider for GitHub, create an IAM role with permissions for ECR push and EKS deployment
    - Add GitHub repository secrets: `AWS_REGION`, `EKS_CLUSTER_NAME`, `AWS_ROLE_ARN`, `ECR_REPO_URI`
    - _Requirements: 7.1_
  - [ ] 9.2 Create the GitHub Actions workflow
    - Create `.github/workflows/deploy.yml` implementing the CIPipeline interface
    - Implement `trigger_on_push`: configure workflow trigger on push to `main` branch
    - Implement `step_configure_aws`: use `aws-actions/configure-aws-credentials@v4` with OIDC role ARN
    - Implement `step_login_ecr`: use `aws-actions/amazon-ecr-login@v2`
    - Implement `step_build_and_push`: build Docker image, tag with commit SHA (`${{ github.sha }}`), push to ECR
    - Add build failure guard: ensure deploy steps depend on successful build step (use `needs:` or sequential steps with `if: success()`)
    - Implement `step_deploy_to_eks`: update kubeconfig, then `kubectl set image deployment/frontend-api frontend-api=${ECR_REPO_URI}:${{ github.sha }}`
    - Implement `step_verify_deployment`: `kubectl rollout status deployment/frontend-api --timeout=120s`
    - _Requirements: 7.1, 7.2, 7.3, 7.4_
  - [ ]* 9.3 Test pipeline execution and failure handling
    - **Property 1: Pipeline Fail-Fast on Build Error**
    - **Validates: Requirements 7.4**
    - Push a code change to `main` and verify the workflow triggers automatically
    - Monitor GitHub Actions run: confirm build, push, and deploy stages execute in sequence
    - Verify updated pods are running the new image: `kubectl describe pod <pod> | grep Image`
    - Test failure scenario: introduce a Dockerfile syntax error, push, and verify pipeline halts without deploying

- [ ] 10. Checkpoint - Validate End-to-End Deployment Pipeline
  - Verify GitHub Actions workflow completed successfully in the Actions tab
  - Verify new image tag (commit SHA) appears in ECR: `aws ecr describe-images --repository-name eks-lab/frontend-api`
  - Verify pods are running the latest image: `kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}'`
  - Test microservice responds correctly via load balancer endpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Cleanup - Resource Teardown
  - [ ] 11.1 Delete Kubernetes resources
    - Uninstall Helm releases: `helm uninstall frontend-api` and `helm uninstall backend-api`
    - Delete stateful resources: `kubectl delete -f manifests/stateful/`
    - Delete any remaining manifest resources: `kubectl delete -f manifests/`
    - Delete Ingress resources to release ALB: `kubectl delete ingress --all`
    - Delete LoadBalancer services to release NLB: `kubectl delete svc --field-selector spec.type=LoadBalancer`
    - Wait for AWS load balancers to be fully deprovisioned before proceeding (check AWS console or `aws elbv2 describe-load-balancers`)
    - _Requirements: (all)_
  - [ ] 11.2 Delete EKS cluster and ECR repositories
    - Implement `delete_eks_cluster`: `eksctl delete cluster --name eks-microservices-lab --region us-east-1`
    - Delete ECR repositories: `aws ecr delete-repository --repository-name eks-lab/frontend-api --region us-east-1 --force` and `aws ecr delete-repository --repository-name eks-lab/backend-api --region us-east-1 --force`
    - Delete any orphaned EBS volumes created by PVCs: `aws ec2 describe-volumes --filters Name=tag:kubernetes.io/created-for/pvc/name,Values=* --query 'Volumes[*].VolumeId' --output text` and delete each
    - Delete IAM roles and policies created for Load Balancer Controller and EBS CSI driver
    - **Warning**: EKS clusters with NAT Gateways and Elastic IPs incur ongoing costs — ensure `eksctl delete cluster` completes fully
    - _Requirements: (all)_
  - [ ] 11.3 Verify cleanup
    - Verify cluster deleted: `aws eks describe-cluster --name eks-microservices-lab` should return `ResourceNotFoundException`
    - Verify ECR repos deleted: `aws ecr describe-repositories --repository-names eks-lab/frontend-api` should return error
    - Verify no orphaned load balancers: `aws elbv2 describe-load-balancers`
    - Verify no orphaned EBS volumes with Kubernetes tags remain
    - Check AWS Cost Explorer for any remaining charges from EKS, EC2, EBS, or ELB resources
    - _Requirements: (all)_

## Notes

- Tasks marked with `*` are optional property tests that validate specific behavioral requirements
- Each task references specific requirements for traceability (format: `_Requirements: X.Y_` where X is the requirement number and Y is the acceptance criteria number)
- Checkpoints ensure incremental validation — do not proceed past a checkpoint until all validations pass
- The two example microservices (frontend-api and backend-api) are intentionally simple Flask applications; the learning focus is on deployment mechanics, not application complexity
- Task 5 deploys using raw manifests and then cleans up before Task 6 deploys the same services via Helm to avoid resource conflicts
- The EKS cluster can take 15-20 minutes to provision — plan accordingly
- Ensure all load balancer resources are fully deprovisioned before deleting the EKS cluster to avoid orphaned AWS resources
