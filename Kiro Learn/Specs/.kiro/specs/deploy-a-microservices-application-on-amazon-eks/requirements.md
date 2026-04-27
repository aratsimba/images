

# Requirements Document

## Introduction

This project guides learners through deploying a microservices application on Amazon Elastic Kubernetes Service (Amazon EKS). Learners will experience the complete microservice deployment lifecycle — from containerizing applications and storing images in Amazon ECR, to deploying workloads on an EKS cluster using Kubernetes manifests and Helm charts, and finally automating the process with a CI/CD pipeline. This progression mirrors real-world practices where teams evolve from manual deployments to fully automated pipelines.

Understanding how to deploy and manage microservices on Kubernetes is a foundational skill for modern cloud-native development. Amazon EKS removes the burden of managing the Kubernetes control plane, allowing learners to focus on application deployment patterns, service exposure, stateful workload management, and continuous deployment strategies. By working with two example microservices, learners will gain hands-on experience with the declarative model of Kubernetes and how AWS services integrate with it.

The project is structured so that learners first deploy microservices manually using raw Kubernetes manifests, then graduate to packaging deployments with Helm charts, and finally build an automated CI/CD pipeline using GitHub Actions. Along the way, learners will explore different methods for exposing services to the internet and understand how to run stateful applications on EKS.

## Glossary

- **amazon_eks**: Amazon Elastic Kubernetes Service — a managed service that runs Kubernetes control plane infrastructure so users can deploy and manage containerized applications without operating their own Kubernetes clusters.
- **amazon_ecr**: Amazon Elastic Container Registry — a fully managed container image registry for storing, managing, and deploying container images.
- **kubernetes_manifest**: A YAML or JSON file that declaratively describes the desired state of Kubernetes resources such as Deployments, Services, and ConfigMaps.
- **helm_chart**: A package of pre-configured Kubernetes resource definitions that simplifies deploying and managing applications on Kubernetes.
- **kubernetes_deployment**: A Kubernetes resource that declares the desired state for a set of pods, managing their creation, scaling, and updates.
- **kubernetes_service**: A Kubernetes resource that defines a network abstraction for exposing a set of pods, enabling communication within or outside the cluster.
- **load_balancer_controller**: An EKS add-on that provisions and manages AWS Elastic Load Balancers in response to Kubernetes Service and Ingress resource definitions.
- **stateful_application**: An application that requires persistent data storage across pod restarts, typically managed using Kubernetes StatefulSets and Persistent Volume Claims.
- **ci_cd_pipeline**: A continuous integration and continuous deployment workflow that automates the building, testing, and deployment of application code changes.
- **desired_state**: The declared configuration of how applications and resources should run in Kubernetes; the system continuously reconciles actual state toward this target.

## Requirements

### Requirement 1: EKS Cluster and ECR Repository Provisioning

**User Story:** As a microservices learner, I want to provision an Amazon EKS cluster and Amazon ECR repositories, so that I have the foundational infrastructure to deploy containerized microservices.

#### Acceptance Criteria

1. WHEN the learner creates an Amazon EKS cluster, THE cluster SHALL reach an active state with a functioning control plane and at least two worker nodes available for scheduling workloads.
2. THE learner SHALL create an Amazon ECR private repository for each of the two example microservices, and each repository SHALL be capable of accepting pushed container images.
3. WHEN the learner configures worker nodes, THE nodes SHALL have the necessary IAM permissions to pull container images from Amazon ECR.

### Requirement 2: Container Image Build and Registry Push

**User Story:** As a microservices learner, I want to containerize two example microservices and push their images to Amazon ECR, so that they are available for deployment to my EKS cluster.

#### Acceptance Criteria

1. WHEN the learner builds a container image for each microservice using a Dockerfile, THE resulting image SHALL be tagged with a version identifier and the ECR repository URI.
2. WHEN the learner authenticates to Amazon ECR and pushes a container image, THE image SHALL appear in the corresponding ECR repository and be retrievable by tag.
3. IF the learner pushes an image with a tag that already exists in the repository, THEN THE existing image SHALL be replaced with the newly pushed image.

### Requirement 3: Microservice Deployment Using Raw Kubernetes Manifests

**User Story:** As a microservices learner, I want to deploy my containerized microservices to EKS using raw Kubernetes manifests, so that I understand how declarative resource definitions drive the desired state of an application in Kubernetes.

#### Acceptance Criteria

1. WHEN the learner applies a Deployment manifest referencing an ECR image, THE EKS cluster SHALL create the specified number of pod replicas and each pod SHALL reach a running and ready state.
2. WHEN the learner applies a Service manifest of type ClusterIP, THE service SHALL enable internal communication between microservices within the cluster using the service's DNS name.
3. IF a pod is deleted or fails, THEN THE Deployment controller SHALL automatically create a replacement pod to maintain the desired replica count.
4. WHEN the learner updates the container image tag in the Deployment manifest and reapplies it, THE cluster SHALL perform a rolling update, replacing old pods with pods running the new image version.

### Requirement 4: Exposing Microservices Using Load Balancing

**User Story:** As a microservices learner, I want to expose my microservices to the internet using AWS load balancers, so that I understand the different service exposure methods available in EKS.

#### Acceptance Criteria

1. WHEN the learner installs the AWS Load Balancer Controller add-on on the EKS cluster, THE controller SHALL be running and capable of provisioning AWS load balancer resources in response to Kubernetes Service and Ingress definitions.
2. WHEN the learner creates a Kubernetes Service of type LoadBalancer, THE system SHALL provision an AWS Network Load Balancer or Classic Load Balancer with a publicly accessible DNS endpoint that routes traffic to the target microservice pods.
3. WHEN the learner creates a Kubernetes Ingress resource with appropriate annotations, THE system SHALL provision an AWS Application Load Balancer with path-based or host-based routing to the target microservice.
4. WHEN the learner sends an HTTP request to the load balancer's public endpoint, THE response SHALL originate from the target microservice running inside the cluster.

### Requirement 5: Deploying Microservices Using Helm Charts

**User Story:** As a microservices learner, I want to package and deploy my microservices using Helm charts, so that I can manage deployments in a templated, repeatable, and version-controlled manner.

#### Acceptance Criteria

1. WHEN the learner creates a Helm chart for a microservice, THE chart SHALL include templated Kubernetes Deployment, Service, and configurable values files that parameterize key settings such as image repository, image tag, and replica count.
2. WHEN the learner installs a Helm release on the EKS cluster, THE microservice SHALL be deployed with all associated Kubernetes resources created and pods running in a healthy state.
3. WHEN the learner upgrades a Helm release with updated values (such as a new image tag or changed replica count), THE cluster SHALL apply the changes through a rolling update, and Helm SHALL track the new revision in its release history.
4. IF the learner rolls back a Helm release to a previous revision, THEN THE microservice SHALL revert to the configuration and image version defined in that earlier revision.

### Requirement 6: Deploying a Stateful Application on EKS

**User Story:** As a microservices learner, I want to deploy a stateful application with persistent storage on EKS, so that I understand how Kubernetes manages data that must survive pod restarts and rescheduling.

#### Acceptance Criteria

1. WHEN the learner creates a StatefulSet with a Persistent Volume Claim template, THE EKS cluster SHALL provision persistent storage (using Amazon EBS CSI driver or similar storage class) and attach a unique volume to each pod replica.
2. IF a StatefulSet pod is deleted or rescheduled, THEN THE replacement pod SHALL reattach to the same Persistent Volume, preserving previously written data.
3. WHEN the learner writes data to the persistent volume from within a pod and the pod is restarted, THE data SHALL remain accessible from the restarted pod.

### Requirement 7: Automated CI/CD Pipeline with GitHub Actions

**User Story:** As a microservices learner, I want to set up a CI/CD pipeline using GitHub Actions that automatically builds container images and deploys updated microservices to my EKS cluster, so that I understand real-world continuous deployment practices.

#### Acceptance Criteria

1. WHEN a code change is pushed to the designated branch of the GitHub repository, THE GitHub Actions workflow SHALL automatically trigger and execute the build, push, and deploy stages in sequence.
2. THE pipeline SHALL build a new container image, tag it with a unique identifier, and push it to the corresponding Amazon ECR repository.
3. WHEN the pipeline reaches the deploy stage, THE workflow SHALL update the microservice's Kubernetes Deployment on the EKS cluster with the newly built image, and THE updated pods SHALL reach a running and ready state.
4. IF the container image build step fails, THEN THE pipeline SHALL halt execution and SHALL NOT proceed to push or deploy stages.
