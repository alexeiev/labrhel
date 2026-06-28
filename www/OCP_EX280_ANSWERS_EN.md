# OCP EX280 - Answers

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

### Solution

```bash
# oc login -u kubeadmin -p XxoiQ-9PZjt-Jea2a-iRiKU
https://api.ocp4.example.com:6443
##Create an htpasswd file to store the user and password information.
htpasswd -c -b -B htpassfile jobs deluges
htpasswd -bB htpassfile wozniak grannies
htpasswd -bB htpassfile collins culverins
htpasswd -bB htpassfile adlerin artiste
htpasswd -bB htpassfile armstrong spacesuits
##Create a Secret object that contains the htpasswd users file
oc create secret generic htpass-idp-ex280 --from-file htpasswd=htpassfile -n
openshift-config
oc get htpass-idp-ex280 -o yaml -n openshift-config
oc get secret htpass-idp-ex280 -o yaml -n openshift-config
oc get -o yaml oauth cluster > oauth.yaml
vim oauth.yaml
```
```text
spec:
identityProviders:
- htpasswd:
fileData:
name: htpass-idp-ex280
mappingMethod: claim
name: htpass-ex280
type: HTPasswd
```
```bash
oc replace -f oauth.yaml
oc get oauth cluster -o yaml
oc get pods -n openshift-authentication
watch oc get pods -n openshift-authentication
oc whoami
oc logout
oc login -u jobs -p deluges
oc whoami
oc logout
oc login -u wozniak -p grannies
oc whoami
oc logout
oc login -u collins -p culverins
oc whoami
oc logout
```

## 2. Configure Cluster Permissions

Assign and restrict cluster-wide privileges as follows:
* User `jobs` must be able to modify and manage the cluster (`cluster-admin`).
* User `wozniak` must be able to create new projects.
* User `armstrong` must be restricted from creating any projects.
* User `wozniak` must be restricted from modifying cluster-wide configurations.
* Completely remove or disable the default `kubeadmin` user access from the cluster.

### Solution

```bash
oc get clusterrole cluster-admin
oc get clusterrolebindings -o wide | grep jobs
oc adm policy add-cluster-role-to-user cluster-admin jobs
oc get clusterrolebindings -o wide | grep jobs
oc get clusterrolebindings -o wide | grep wozniak
oc get clusterrole self-provisioner
oc adm policy add-cluster-role-to-user self-provisioner wozniak
oc get clusterrolebindings -o wide | grep wozniak
oc get clusterrolebindings -o wide | grep armstrong
oc describe clusterrolebindings self-provisioners
oc adm policy remove-cluster-role-from-group self-provisioner system:authenticated:oauth
oc describe clusterrolebindings self-provisioners
oc login -u armstrong -p spacesuits
oc new-project test
oc logout
oc login -u wozniak -p grannies
oc get nodes
oc adm top nodes
oc logout
oc login -u kubeadmin -p XxoiQ-9PZjt-Jea2a-iRiKU https://api.ocp4.example.com:6443
oc get secret kubeadmin -n kube-system
oc logout
oc login -u jobs -p deluges
oc get secret kubeadmin -n kube-system
oc delete secrets kubeadmin -n kube-system
oc get secret kubeadmin -n kube-system
```

## 3. Configure Project Permissions

Create the required projects and apply specific user roles:
* Create the following projects: `apollo`, `titan`, `gemini`, `bluebook`, and `apache`.
* User `armstrong` must be the administrator (`admin`) for both the `apollo` and `titan` projects.
* User `collins` must have read-only access (`view`) to the `apollo` project.

### Solution

```bash
oc new-project apollo
oc new-project titan
oc new-project gemini
oc new-project bluebook
oc new-project apache
oc get projects
oc get projects | grep gemini
oc get clusterrole admin
oc policy add-role-to-user admin armstrong -n apollo
oc policy add-role-to-user admin armstrong -n titan
oc get clusterrole view
oc policy add-role-to-user view collins -n apollo
oc get rolebinding -o wide -n apollo
```

## 4. Create Groups and Configure Permissions

Manage team access permissions using OpenShift groups:
* Create a group named `commander` and add user `armstrong` as a member.
* Create a group named `pilot` and add users `adlerin` and `collins` as members.
* Members of the `commander` group must have edit permissions (`edit`) in the `apollo` project.
* Members of the `pilot` group must have view permissions (`view`) in the `apollo` project.

### Solution

```bash
oc adm groups new commander
oc adm groups add-users commander armstrong
oc adm groups new pilot
oc adm groups add-users pilot adlerin
oc adm groups add-users pilot collins
oc get groups
oc get clusterrole edit
oc policy add-role-to-group edit commander -n apollo
oc policy add-role-to-group view pilot -n apollo
oc get rolebinding -o wide -n apollo
```

## 5. Configure Resource Quotas for a Project

Apply resource usage restrictions within a specific project:
* Create a `ResourceQuota` named `ex280-quota` inside the `apache` project.
* Total memory consumed across all containers cannot exceed `1Gi`.
* Total CPU across all containers cannot exceed `2` full cores.
* The maximum number of Replication Controllers cannot exceed `3`.
* The maximum number of Pods cannot exceed `3`.
* The maximum number of Services cannot exceed `6`.

### Solution

```bash
oc project apache
oc create quota ex280-quota --hard memory=1Gi,cpu=2,replicationcontrollers=3,pods=3,services=6
oc describe quotas ex280-quota
```

## 6. Configure Limit Ranges for a Project

Set default resource requests and constraints for individual workloads:
* Create a `LimitRange` named `ex280-limits` inside the `bluebook` project.
* **Pod constraints:** Memory must be between `100Mi` and `300Mi`; CPU must be between `10m` and `500m`.
* **Container constraints:** Memory must be between `100Mi` and `300Mi` (with a default request of `100Mi`); CPU must be between `10m` and `500m` (with a default request of `100m`).

### Solution

```bash
# vim limit.yml
apiVersion: "v1"
kind: "LimitRange"
metadata:
name: ex280-limits
spec:
limits:
- type: "Pod"
max:
cpu: “500m”
memory: “300Mi”
min:
cpu: “10m”
memory: “100Mi”
- type: “Container”
max:
cpu: “500m”
memory: “300Mi”
min:
cpu: “10m”
memory: “100Mi”
defaultRequest:
cpu: "30m"
memory: "30Mi"
# :wq!
oc create -f limits.yaml
oc describe limitranges ex280-limits
```

## 7. Deploy a Helm Chart Application

Deploy a third-party application using a Helm repository:
* Ensure the target project `ascii-hall` exists.
* Add the repository located at `http://helm.domain.23.example.com/charts/`.
* Deploy the chart named `redhat-cinema` into the project. Validate that the deployment successfully scales up.

### Solution

```bash
oc project ascii-hall (If already exists)
helm repo add do280-repo http://helm.domain.23.example.com/charts/
help search repo -versions
helm install redhat-cinema do280-repo http://helm.domain.23.example.com/charts/
oc get all
```

## 8. Scale an Application Manually

Adjust application instances to meet scaling requirements:
* Navigate to the project named `lerna`.
* Identify the application deployment named `hydra`.
* Manually scale the `hydra` application to exactly `5` replicas.

### Solution

```bash
oc project lerna
oc get pods
oc get all | grep deploy
oc scale --replicas 5 deployment.apps/hydra
oc scale --replicas 5 deploymentconfig.apps/hydra
oc get pods
```

## 9. Configure Autoscaling for an Application

Implement horizontal scaling automation based on resource demand:
* Inside the project `gru`, configure an Horizontal Pod Autoscaler (HPA) for the deployment/deploymentconfig named `scale`.
* **Minimum replicas:** `6`
* **Maximum replicas:** `40`
* **Target CPU utilization:** `60%`
* Set the application container resources to have a CPU request of `25m` and a CPU limit of `100m`.

### Solution

```bash
oc project gru
oc get pods
oc get deploy
oc autoscale --min 6 --max 40 --cpu-percent 60 deploy/scale
oc get hpa
oc set resources --requests cpu=25m --limits cpu=100m deployment.apps/scala
oc describe deployment.apps/scala | grep -A1 -E 'Request|Limits'
```

## 10. Configure and Deploy a Secure Route

Expose an application over HTTPS using an Edge TLS termination route:
* Work within the project named `area51` for the application `oxcart`.
* Generate self-signed TLS certificates for the subject: `/C=US/ST=NC/L=Raleigh/O=RedHat/OU=RHT/CN=oxcart.apps.ocp4.example.com`
* Secure the route using the generated certificate and key.
* The application must be reachable securely at `https://oxcart.apps.ocp4.example.com`.

### Solution

```bash
oc project area51
oc get pods
oc get route
oc delete route oxcart
oc get route
mkdir cert
cd cert
newcert "/C=US/ST=NC/L=Raleigh/O=RedHat/OU=RHT/CN=oxcart.apps.ocp4.example.com"
 # newcert command is already installed
ls
oc get service
oc create route edge --service oxcart --cert apps-crc.testing.crt --key apps-crc.testing.key -hostname oxcart.apps.ocp4.example.com
oc get route 
#https://oxcart.apps.ocp4.example.com
```

## 11. Configure a Secret

Store sensitive configurations securely inside the cluster:
* Inside the `math` project, create a generic secret named `magic`.
* The secret must contain the following key-value pair: `Decoder_Ring: ASDA142hfh-gfrhhueo-erfdk345v`.

### Solution

```bash
oc project math
oc create secret generic magic --from-literal Decoder_Ring=ASDA142hfh-gfrhhueo-erfdk345v
oc get secret
oc describe secret magic
```

## 12. Inject Secret Values into an Application

Provide sensitive data to an application deployment dynamically:
* In the `math` project, inject the secret `magic` into the deployment config / deployment named `qed` as environment variables.
* Verify that once the secret is injected, the application updates successfully and stops outputting the error message: `"App is not configured properly"`.

### Solution

```bash
oc get pods
oc get deploy
oc describe deploy/qed | grep Env
oc set env --from secret/magic deploy/qed
oc describe deploy/qed | grep -A1 Env
oc get route
curl qed.apps.ocp4.example.com
```

## 13. Troubleshoot and Repair a Resource-Constrained Deployment

Debug a failing application deployment that cannot schedule pods:
* Inspect the application `mercury` inside the project `bluebook`.
* Without deleting or re-creating the base deployment object, fix the deployment so that pods can successfully be scheduled (Hint: Check and fix excessive or incorrect CPU/Memory resource requests).

### Solution

```bash
oc project bluebook
oc get pods
oc logs mercury-6b6b777877-rgddeploy
oc get events
# when you run this command you will get error insufficient cpu/memory
oc get deploy
oc edit deploy mercury
# remove resources section, because it take 80G memory
oc get pods
oc describe deploy/mercury
```

## 14. Inject Configuration Data via ConfigMaps

Deploy and update an application using externalized text configurations:
* Create a project named `czech`.
* Deploy an application named `ernie` using the image `quay.io/redhattraining/hello-openshift`.
* Create a `ConfigMap` named `ex280-cm` containing the key `RESPONSE` with the value `'six czech cricket critics'`.
* Inject this ConfigMap into the deployment so the application outputs the phrase when accessed at `http://ernie.apps.ocp4.example.com`.

### Solution

```bash
oc new-project czech
oc new-app --name=ernie --image=quay.io/redhattraining/hello-openshift
# Registry server name information is given exam instruction link ,
oc get pods
oc get service
oc expose service ernie --hostname=ernie.apps.ocp4.example.com
oc get route
# http://ernie.apps.ocp4.example.com

oc create configmap ex280-cm --from-literal RESPONSE='six czech cricket critics'
oc get cm ex280-cm
oc describe cm ex280-cm
oc get pods
oc get cm ex280-cm
oc get deploy
oc describe pod ernie-96c76bc57-kllql | grep Env
oc set env --from configmap/ex280-cm deploy/ernie
oc get pod
```

## 15. Configure a Service Account with Specific SCCs

Elevate privileges for a specialized application workflow:
* Inside the project `apples`, create a Service Account named `ex280-sa`.
* Grant this service account the ability to run containers using any user ID (`anyuid` Security Context Constraint).

### Solution

```bash
oc project apples
oc create serviceaccount ex280-sa
oc adm policy add-scc-to-user anyuid -z ex280-sa
oc describe sa ex280-sa
```

## 16. Fix Application Pod Placement and Service Selectors

Debug a service that fails to route traffic to active application pods:
* Troubleshoot the application `oranges` in the project `apples`.
* Ensure the application is configured to use the `ex280-sa` service account.
* Fix any discrepancies between the Service selector labels and the Pod labels so that the application route responds correctly.

### Solution

```bash
oc get pods
oc logs oranges-6b6b777877-rgddeploy
oc describe pod oranges-6b6b777877-rgddeploy | grep scc
oc get deploy
oc set serviceaccount deploy/oranges ex280-sa
oc get pods
oc describe pod oranges-8666b4574f-npw78 | grep scc
oc get route
# http://oranges.apps.ocp4.example.com
oc get pods -o wide
oc get service
oc describe service oranges | grep Endpoints
oc describe service oranges | grep Selector
oc describe pod oranges-8666b4574f-npw78 | grep Labels
oc edit service oranges Deploymen=oranges 
#[In exam you need to verify pod label and Service selector After modify following line]
oc describe service oranges | grep Selector
oc describe pod oranges-8666b4574f-npw78 | grep Labels
oc describe service oranges | grep Endpoints
oc get route
curl http://oranges.apps.ocp4.example.com
```

## 17. Configure a Network Policy

Restrict network traffic between namespaces to secure a database:
* Inside the `database` project, create a `NetworkPolicy` named `db-allow-mysql-comm`.
* The policy applies to pods matching the label `network.openshift.io/policy-group: database`.
* Restrict ingress traffic exclusively to deployments coming from the `checker` project.
* The traffic must be filtered from namespaces with the label `team=devsecops` and pods with the label `deployment=web-mysql`.
* Allow incoming connections only on port `3304/TCP`.

### Solution

```bash
oc project database
oc get pods
oc get route
oc describe pod mercury-58786b7869-66lw6 | grep Labels
oc describe pod mercury-58786b7869-66lw6 | grep Ports
oc describe pod rocky-74b5d6fd7d-cmhsw -n checker | grep Labels
oc describe project checker | grep Labels
vim policy.yml
````
```text
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: db-allow-mysql-comm
spec:
podSelector:
matchLabels:
network.openshift.io/policy-group: database
policyTypes:
- Ingress
ingress:
- from:
- namespaceSelector:
matchLabels:
team: devsecops
podSelector:
matchLabels:
deployment: web-mysql
ports:
- protocol: TCP
port: 3304
# :wq!
```
```bash
oc create -f policy.yml
oc get networkpolicy
oc get networkpolicy
oc describe networkpolicy db-allow-mysql-comm
oc get pod -o wide
oc project checker
oc get pods
```

## 18. Configure Persistent Network Storage

Set up persistent backend volumes for a web application:
* Create a project named `page` and deploy an application named `landing` using the image `registry.domin12.example.com/nginxinc/nginx-unprivileged:latest`.
* Create a `PersistentVolume` named `landing-pv` (`1Gi`, `ReadWriteMany`, mapped to the target NFS server/path).
* Create a `PersistentVolumeClaim` named `landing-pvc` matching the same specifications and storage class.
* Mount the volume to the application deployment at `/usr/share/nginx/html` and scale the deployment to `3` pods.

### Solution

```bash
oc new-project page
oc new-app --name=landing --image=registry.domain12.example.com/nginxinc/nginx-unprivileged:latest
oc get pods
oc get service
oc expose service landing -hostname=landing.page.apps.domain12.example.com
oc get route
# http://landing.page.apps.domain12.example.com
oc get sc
#  know the storage class name
oc describe sc <storage class name>
#  This command will help you to know the information like your shared nfs information, reclaim policy information and more, Generally shared nfs information available in Important.configuration.Information
vim pv.yaml
```
```text
apiVersion: v1
kind: PersistentVolume
metadata:
name: landing-pv
spec:
capacity:
storage: 1Gi
accessModes:
- ReadWriteMany
persistentVolumeReclaimPolicy: Retain
nfs:
path: /exports-ocp4
server: 192.168.50.254
# :wq!
```
```bash
oc create -f pv.yaml
oc get pv
oc describe pv landing-pv
vim pvc.yml
```
```text
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
name: landing-pvc
spec:
accessModes:
- ReadWriteMany
resources:
requests:
storage: 1Gi
storageClassName: your-storage-class # Specify the storage class name here
```
```bash
oc get pvc
oc describe pvc landing-pvc
oc get all |grep deploy
oc edit deploy/landing
```
```text
containers:
- name: nginx-container
image: registry.domain12.example.com/nginxinc/nginx-unprivileged:latest
// ADD Following Parametters
volumeMounts:
- name: nginx-html
mountPath: /usr/share/nginx/html
volumes:
- name: nginx-html
persistentVolumeClaim:
claimName: landing-pvc
```
```bash
oc get pods
oc rsh landing-5c494cf5bf-d7jqt
```

## 19. Install an Operator

Extend cluster functionality by deploying an automated infrastructure component:
* Install the `file-integrity` operator.
* The operator must be targeting the `openshift-file-integrity` project.
* The update approval strategy must be set to `Automatic`.
* Ensure cluster monitoring metrics are enabled/created for this project.

### Solution

```bash
oc whoami --show-console
```

```text
Operators -> OperatorHub -> search for the requested operator -> Install
Use the namespace and approval strategy specified in the exam. The transcript describes this as a simple console task, but the exact values still matter.
```


## 20. Schedule an Automated CronJob

Create a recurring batch task inside the cluster architecture:
* In the project `elementum`, deploy a `CronJob` named `job-runner` using the image `registry.domain12.example.com/library/job-runner:latest`.
* **Schedule:** Run exactly at `04:05` on the 2nd day of every month.
* **History limit:** Set the successful jobs history limit to `14`.
* The job must execute utilizing a custom Service Account named `magna`.

### Solution

```bash
oc new-project elementum
oc create cronjob job-runner --imageregistry.domain12.example.com/library/job-runner:latest --schedule '5 4 2 * *'
oc get cronjobs.batch
oc create serviceaccount magna
oc adm policy add-cluster-role-to-user cluster-admin -z magna
oc set sa cronjob.batch/job-runner magna
oc describe cronjobs.batch job-runner
oc edit cronjobs.batch
oc describe cronjobs.batch job-runner
```

## 21. Configure a Custom Project Template

Enforce corporate resource boundaries automatically on every new project creation:
* Generate and customize the cluster bootstrap project template.
* Configure it so that any new project automatically receives a `LimitRange` named `PROJECT_NAME-limits`.
* **Container memory constraints within the template:** Minimum `128Mi`, Maximum `1Gi`, Default limit `512Mi`, Default request `256Mi`.
* Apply the template cluster-wide via the cluster project configuration.

### Solution

```bash
oc adm create-bootstrap-project-template -o yaml > proj-temp.yaml
cat limitrange.yaml
```

```yaml
- apiVersion: v1
  kind: LimitRange
  metadata:
    name: ${PROJECT_NAME}-limits
  spec:
    limits:
      - type: Container
        default:
          memory: <default-memory>
        defaultRequest:
          memory: <default-request-memory>
        min:
          memory: <min-memory>
        max:
          memory: <max-memory>
```
```bash
vim template.yaml
# Add the required object before the `parameters` section:
```
```bash
oc create -f proj-temp.yaml -n openshift-config
oc edit projects.config.openshift.io/cluster
```

```yaml
spec:
  projectRequestTemplate:
    name: <template-name>
```
```bash
oc get pods -n openshift-apiserver
```

## 22. Configure a Container Health Probe

Increase application reliability by implementing automatic self-healing:
* Within the project `mercary`, target the deployment config / deployment named `atlas`.
* Add a **Liveness Probe** that executes a TCP socket check on port `8080`.
* Configure the probe to have an initial delay of `10` seconds and a timeout of `30` seconds. Ensure changes survive an application rebuild.

### Solution

```bash
oc project mercury
oc get pods
oc set probe --liveness --open-tcp 8080 --initial-delay-seconds 10 --timeout-seconds 30 deploy/atlas
oc describe deploy/atlas | grep Live
```
