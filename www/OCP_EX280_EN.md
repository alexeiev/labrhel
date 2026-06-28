# OpenShift EX280 Exam Practice Questions

## Cluster Environment Information
* **Wild-card domain for the cluster:** `apps.ocp4.example.com`
* **Documentation URL:** `https://access.redhat.com/documentation/en-us/openshift_container_platform/4.12/`
* **Kubeadmin password location:** `/home/student/kubeadmin-password` (on the workbench VM)
* **Root password for workbench VM:** Provided during the exam

---

## 1. Configure the Identity Provider for OpenShift
Configure an Htpasswd Identity Provider with the following specifications:
* **Identity Provider Name:** `htpass-ex280`
* **Secret Name for users:** `htpass-idp-ex280`
* Create the following user accounts and passwords:
  * User: `jobs` | Password: `deluges`
  * User: `wozniak` | Password: `grannies`
  * User: `collins` | Password: `culverins`
  * User: `adlerin` | Password: `artiste`
  * User: `armstrong` | Password: `spacesuits`

## 2. Configure Cluster Permissions
Assign and restrict cluster-wide privileges as follows:
* User `jobs` must be able to modify and manage the cluster (`cluster-admin`).
* User `wozniak` must be able to create new projects.
* User `armstrong` must be restricted from creating any projects.
* User `wozniak` must be restricted from modifying cluster-wide configurations.
* Completely remove or disable the default `kubeadmin` user access from the cluster.

## 3. Configure Project Permissions
Create the required projects and apply specific user roles:
* Create the following projects: `apollo`, `titan`, `gemini`, `bluebook`, and `apache`.
* User `armstrong` must be the administrator (`admin`) for both the `apollo` and `titan` projects.
* User `collins` must have read-only access (`view`) to the `apollo` project.

## 4. Create Groups and Configure Permissions
Manage team access permissions using OpenShift groups:
* Create a group named `commander` and add user `armstrong` as a member.
* Create a group named `pilot` and add users `adlerin` and `collins` as members.
* Members of the `commander` group must have edit permissions (`edit`) in the `apollo` project.
* Members of the `pilot` group must have view permissions (`view`) in the `apollo` project.

## 5. Configure Resource Quotas for a Project
Apply resource usage restrictions within a specific project:
* Create a `ResourceQuota` named `ex280-quota` inside the `apache` project.
* Total memory consumed across all containers cannot exceed `1Gi`.
* Total CPU across all containers cannot exceed `2` full cores.
* The maximum number of Replication Controllers cannot exceed `3`.
* The maximum number of Pods cannot exceed `3`.
* The maximum number of Services cannot exceed `6`.

## 6. Configure Limit Ranges for a Project
Set default resource requests and constraints for individual workloads:
* Create a `LimitRange` named `ex280-limits` inside the `bluebook` project.
* **Pod constraints:** Memory must be between `100Mi` and `300Mi`; CPU must be between `10m` and `500m`.
* **Container constraints:** Memory must be between `100Mi` and `300Mi` (with a default request of `100Mi`); CPU must be between `10m` and `500m` (with a default request of `100m`).

## 7. Deploy a Helm Chart Application
Deploy a third-party application using a Helm repository:
* Ensure the target project `ascii-hall` exists.
* Add the repository located at `http://helm.domain.23.example.com/charts/`.
* Deploy the chart named `redhat-cinema` into the project. Validate that the deployment successfully scales up.

## 8. Scale an Application Manually
Adjust application instances to meet scaling requirements:
* Navigate to the project named `lerna`.
* Identify the application deployment named `hydra`.
* Manually scale the `hydra` application to exactly `5` replicas.

## 9. Configure Autoscaling for an Application
Implement horizontal scaling automation based on resource demand:
* Inside the project `gru`, configure an Horizontal Pod Autoscaler (HPA) for the deployment/deploymentconfig named `scale`.
* **Minimum replicas:** `6`
* **Maximum replicas:** `40`
* **Target CPU utilization:** `60%`
* Set the application container resources to have a CPU request of `25m` and a CPU limit of `100m`.

## 10. Configure and Deploy a Secure Route
Expose an application over HTTPS using an Edge TLS termination route:
* Work within the project named `area51` for the application `oxcart`.
* Generate self-signed TLS certificates for the subject: `/C=US/ST=NC/L=Raleigh/O=RedHat/OU=RHT/CN=oxcart.apps.ocp4.example.com`
* Secure the route using the generated certificate and key.
* The application must be reachable securely at `https://oxcart.apps.ocp4.example.com`.

## 11. Configure a Secret
Store sensitive configurations securely inside the cluster:
* Inside the `math` project, create a generic secret named `magic`.
* The secret must contain the following key-value pair: `Decoder_Ring: ASDA142hfh-gfrhhueo-erfdk345v`.

## 12. Inject Secret Values into an Application
Provide sensitive data to an application deployment dynamically:
* In the `math` project, inject the secret `magic` into the deployment config / deployment named `qed` as environment variables.
* Verify that once the secret is injected, the application updates successfully and stops outputting the error message: `"App is not configured properly"`.

## 13. Troubleshoot and Repair a Resource-Constrained Deployment
Debug a failing application deployment that cannot schedule pods:
* Inspect the application `mercury` inside the project `bluebook`.
* Without deleting or re-creating the base deployment object, fix the deployment so that pods can successfully be scheduled (Hint: Check and fix excessive or incorrect CPU/Memory resource requests).

## 14. Inject Configuration Data via ConfigMaps
Deploy and update an application using externalized text configurations:
* Create a project named `czech`.
* Deploy an application named `ernie` using the image `quay.io/redhattraining/hello-openshift`.
* Create a `ConfigMap` named `ex280-cm` containing the key `RESPONSE` with the value `'six czech cricket critics'`.
* Inject this ConfigMap into the deployment so the application outputs the phrase when accessed at `http://ernie.apps.ocp4.example.com`.

## 15. Configure a Service Account with Specific SCCs
Elevate privileges for a specialized application workflow:
* Inside the project `apples`, create a Service Account named `ex280-sa`.
* Grant this service account the ability to run containers using any user ID (`anyuid` Security Context Constraint).

## 16. Fix Application Pod Placement and Service Selectors
Debug a service that fails to route traffic to active application pods:
* Troubleshoot the application `oranges` in the project `apples`.
* Ensure the application is configured to use the `ex280-sa` service account.
* Fix any discrepancies between the Service selector labels and the Pod labels so that the application route responds correctly.

## 17. Configure a Network Policy
Restrict network traffic between namespaces to secure a database:
* Inside the `database` project, create a `NetworkPolicy` named `db-allow-mysql-comm`.
* The policy applies to pods matching the label `network.openshift.io/policy-group: database`.
* Restrict ingress traffic exclusively to deployments coming from the `checker` project.
* The traffic must be filtered from namespaces with the label `team=devsecops` and pods with the label `deployment=web-mysql`.
* Allow incoming connections only on port `3304/TCP`.

## 18. Configure Persistent Network Storage
Set up persistent backend volumes for a web application:
* Create a project named `page` and deploy an application named `landing` using the image `registry.domin12.example.com/nginxinc/nginx-unprivileged:latest`.
* Create a `PersistentVolume` named `landing-pv` (`1Gi`, `ReadWriteMany`, mapped to the target NFS server/path).
* Create a `PersistentVolumeClaim` named `landing-pvc` matching the same specifications and storage class.
* Mount the volume to the application deployment at `/usr/share/nginx/html` and scale the deployment to `3` pods.

## 19. Install an Operator
Extend cluster functionality by deploying an automated infrastructure component:
* Install the `file-integrity` operator.
* The operator must be targeting the `openshift-file-integrity` project.
* The update approval strategy must be set to `Automatic`.
* Ensure cluster monitoring metrics are enabled/created for this project.

## 20. Schedule an Automated CronJob
Create a recurring batch task inside the cluster architecture:
* In the project `elementum`, deploy a `CronJob` named `job-runner` using the image `registry.domain12.example.com/library/job-runner:latest`.
* **Schedule:** Run exactly at `04:05` on the 2nd day of every month.
* **History limit:** Set the successful jobs history limit to `14`.
* The job must execute utilizing a custom Service Account named `magna`.

## 21. Configure a Custom Project Template
Enforce corporate resource boundaries automatically on every new project creation:
* Generate and customize the cluster bootstrap project template.
* Configure it so that any new project automatically receives a `LimitRange` named `PROJECT_NAME-limits`.
* **Container memory constraints within the template:** Minimum `128Mi`, Maximum `1Gi`, Default limit `512Mi`, Default request `256Mi`.
* Apply the template cluster-wide via the cluster project configuration.

## 22. Collect Cluster Information for Red Hat Support
Gather cluster diagnostics data required for support engineering tickets:
* Use the cluster diagnostic tools (`must-gather`) to collect the logs and definitions.
* Compress the collected data into a tarball named `ex280-ocp.<CLUSTER_ID>.tar.gz`, replacing `<CLUSTER_ID>` with your unique cluster identifier.
* Upload the archive using the diagnostic script utility located at `/usr/local/bin/upload-cluster-data`.

## 23. Configure a Container Health Probe
Increase application reliability by implementing automatic self-healing:
* Within the project `mercary`, target the deployment config / deployment named `atlas`.
* Add a **Liveness Probe** that executes a TCP socket check on port `8080`.
* Configure the probe to have an initial delay of `10` seconds and a timeout of `30` seconds. Ensure changes survive an application rebuild.