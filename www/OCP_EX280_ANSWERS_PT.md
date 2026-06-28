# OCP EX280 - Respostas

## 1. Configurar o Provedor de Identidade (Identity Provider) do OpenShift

Configure um Provedor de Identidade do tipo Htpasswd com as seguintes especificações:
* **Nome do Provedor de Identidade:** `htpass-ex280`
* **Nome do Secret para os usuários:** `htpass-idp-ex280`
* Crie as seguintes contas de usuário e senhas:
  * Usuário: `jobs` | Senha: `deluges`
  * Usuário: `wozniak` | Senha: `grannies`
  * Usuário: `collins` | Senha: `culverins`
  * Usuário: `adlerin` | Senha: `artiste`
  * Usuário: `armstrong` | Senha: `spacesuits`

### Solução

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

## 2. Configurar Permissões de Cluster

Atribua e restrinja privilégios em nível de cluster da seguinte forma:
* O usuário `jobs` deve ser capaz de modificar e gerenciar o cluster (`cluster-admin`).
* O usuário `wozniak` deve ser capaz de criar novos projetos.
* O usuário `armstrong` deve ser impedido de criar qualquer projeto.
* O usuário `wozniak` deve ser impedido de modificar configurações globais do cluster.
* Remova ou desative completamente o acesso do usuário padrão `kubeadmin` do cluster.

### Solução

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

## 3. Configurar Permissões de Projeto

Crie os projetos necessários e aplique papéis de usuário específicos:
* Crie os seguintes projetos: `apollo`, `titan`, `gemini`, `bluebook` e `apache`.
* O usuário `armstrong` deve ser o administrador (`admin`) dos projetos `apollo` e `titan`.
* O usuário `collins` deve ter acesso de apenas leitura (`view`) ao projeto `apollo`.

### Solução

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

## 4. Criar Grupos e Configurar Permissões

Gerencie as permissões de acesso das equipes usando grupos do OpenShift:
* Crie um grupo chamado `commander` e adicione o usuário `armstrong` como membro.
* Crie um grupo chamado `pilot` e adicione os usuários `adlerin` e `collins` como membros.
* Os membros do grupo `commander` devem ter permissões de edição (`edit`) no projeto `apollo`.
* Os membros do grupo `pilot` devem ter permissões de visualização (`view`) no projeto `apollo`.

### Solução

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

## 5. Configurar Quotas de Recursos (Resource Quotas) para um Projeto

Aplique restrições de uso de recursos dentro de um projeto específico:
* Crie uma `ResourceQuota` chamada `ex280-quota` dentro do projeto `apache`.
* A memória total consumida por todos os containers não pode exceder `1Gi`.
* O uso total de CPU por todos os containers não pode exceder `2` cores completos.
* O número máximo de Replication Controllers não pode exceder `3`.
* O número máximo de Pods não pode exceder `3`.
* O número máximo de Services não pode exceder `6`.

### Solução

```bash
oc project apache
oc create quota ex280-quota --hard memory=1Gi,cpu=2,replicationcontrollers=3,pods=3,services=6
oc describe quotas ex280-quota
```

## 6. Configurar Intervalos de Limite (Limit Ranges) para um Projeto

Defina requisições e restrições de recursos padrão para workloads individuais:
* Crie um `LimitRange` chamado `ex280-limits` dentro do projeto `bluebook`.
* **Restrições de Pod:** A memória deve estar entre `100Mi` e `300Mi`; a CPU deve estar entre `10m` e `500m`.
* **Restrições de Container:** A memória deve estar entre `100Mi` e `300Mi` (com uma requisição padrão de `100Mi`); a CPU deve estar entre `10m` e `500m` (com uma requisição padrão de `100m`).

### Solução

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

## 7. Implantar uma Aplicação via Helm Chart

Implante uma aplicação de terceiros usando um repositório Helm:
* Garanta que o projeto de destino `ascii-hall` exista.
* Adicione o repositório localizado em `http://helm.domain.23.example.com/charts/`.
* Implante o chart chamado `redhat-cinema` dentro do projeto. Valide se a implantação escalou com sucesso.

### Solução

```bash
oc project ascii-hall (If already exists)
helm repo add do280-repo http://helm.domain.23.example.com/charts/
help search repo -versions
helm install redhat-cinema do280-repo http://helm.domain.23.example.com/charts/
oc get all
```

## 8. Escalar uma Aplicação Manualmente

Ajuste as instâncias de uma aplicação para atender aos requisitos de dimensionamento:
* Navegue até o projeto chamado `lerna`.
* Identifique a implantação (deployment) da aplicação chamada `hydra`.
* Escale manualmente a aplicação `hydra` para exatamente `5` réplicas.

### Solução

```bash
oc project lerna
oc get pods
oc get all | grep deploy
oc scale --replicas 5 deployment.apps/hydra
oc scale --replicas 5 deploymentconfig.apps/hydra
oc get pods
```

## 9. Configurar Autonivelamento (Autoscaling) para uma Aplicação

Implemente a automação de dimensionamento horizontal com base na demanda de recursos:
* Dentro do projeto `gru`, configure um Horizontal Pod Autoscaler (HPA) para o deployment/deploymentconfig chamado `scale`.
* **Mínimo de réplicas:** `6`
* **Máximo de réplicas:** `40`
* **Uso de CPU alvo:** `60%`
* Defina os recursos do container da aplicação para ter uma requisição de CPU (requests) de `25m` e um limite de CPU (limits) de `100m`.

### Solução

```bash
oc project gru
oc get pods
oc get deploy
oc autoscale --min 6 --max 40 --cpu-percent 60 deploy/scale
oc get hpa
oc set resources --requests cpu=25m --limits cpu=100m deployment.apps/scala
oc describe deployment.apps/scala | grep -A1 -E 'Request|Limits'
```

## 10. Configurar e Implantar uma Rota Segura (Secure Route)

Exponha uma aplicação via HTTPS usando uma rota com terminação TLS do tipo Edge:
* Trabalhe dentro do projeto chamado `area51` para a aplicação `oxcart`.
* Gere certificados TLS autoassinados para o subject: `/C=US/ST=NC/L=Raleigh/O=RedHat/OU=RHT/CN=oxcart.apps.ocp4.example.com`
* Proteja a rota usando o certificado e a chave gerados.
* A aplicação deve estar acessível de forma segura em `https://oxcart.apps.ocp4.example.com`.

### Solução

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

## 11. Configurar um Secret

Armazene configurações sensíveis de forma segura dentro do cluster:
* Dentro do projeto `math`, crie um secret genérico chamado `magic`.
* O secret deve conter o seguinte par chave-valor: `Decoder_Ring: ASDA142hfh-gfrhhueo-erfdk345v`.

### Solução

```bash
oc project math
oc create secret generic magic --from-literal Decoder_Ring=ASDA142hfh-gfrhhueo-erfdk345v
oc get secret
oc describe secret magic
```

## 12. Injetar Valores de Secret em uma Aplicação

Forneça dados sensíveis para a implantação de uma aplicação de forma dinâmica:
* No projeto `math`, injete o secret `magic` no deployment config / deployment chamado `qed` como variáveis de ambiente.
* Verifique se, após a injeção do secret, a aplicação é atualizada com sucesso e para de exibir a mensagem de erro: `"App is not configured properly"`.

### Solução

```bash
oc get pods
oc get deploy
oc describe deploy/qed | grep Env
oc set env --from secret/magic deploy/qed
oc describe deploy/qed | grep -A1 Env
oc get route
curl qed.apps.ocp4.example.com
```

## 13. Solucionar Problemas de Implantação com Restrição de Recursos

Depure uma aplicação com falha que não consegue agendar pods devido a restrições:
* Inspecione a aplicação `mercury` dentro do projeto `bluebook`.
* Sem deletar ou recriar o objeto de deployment base, corrija a configuração para que os pods possam ser agendados com sucesso (Dica: Verifique e corrija requisições excessivas ou incorretas de recursos de CPU/Memória).

### Solução

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

## 14. Injetar Dados de Configuração via ConfigMaps

Implante e atualize uma aplicação usando configurações textuais externalizadas:
* Crie um projeto chamado `czech`.
* Implante uma aplicação chamada `ernie` usando a imagem `quay.io/redhattraining/hello-openshift`.
* Crie um `ConfigMap` chamado `ex280-cm` contendo a chave `RESPONSE` com o valor `'six czech cricket critics'`.
* Injete este ConfigMap no deployment para que a aplicação exiba a frase ao ser acessada em `http://ernie.apps.ocp4.example.com`.

### Solução

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

## 15. Configurar uma Service Account com SCCs Específicas

Eleve os privilégios para o fluxo de trabalho de uma aplicação especializada:
* Dentro do projeto `apples`, crie uma Service Account chamada `ex280-sa`.
* Conceda a esta service account a capacidade de executar containers usando qualquer ID de usuário (Security Context Constraint do tipo `anyuid`).

### Solução

```bash
oc project apples
oc create serviceaccount ex280-sa
oc adm policy add-scc-to-user anyuid -z ex280-sa
oc describe sa ex280-sa
```

## 16. Corrigir Seletores de Serviço e Identificadores de Pods

Depure um serviço que falha ao rotear tráfego para os pods ativos da aplicação:
* Solucione os problemas da aplicação `oranges` no projeto `apples`.
* Garanta que a aplicação esteja configurada para usar a service account `ex280-sa`.
* Corrija quaisquer divergências entre as labels do seletor do Service e as labels do Pod para que a rota da aplicação responda corretamente.

### Solução

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

## 17. Configurar uma Política de Rede (Network Policy)

Restrinja o tráfego de rede entre namespaces para proteger um banco de dados:
* Dentro do projeto `database`, crie uma `NetworkPolicy` chamada `db-allow-mysql-comm`.
* A política se aplica aos pods que possuem a label `network.openshift.io/policy-group: database`.
* Restrinja o tráfego de entrada (ingress) exclusivamente para implantações vindas do projeto `checker`.
* O tráfego deve ser filtrado a partir de namespaces com a label `team=devsecops` e pods com a label `deployment=web-mysql`.
* Permita conexões de entrada apenas na porta `3304/TCP`.

### Solução

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

## 18. Configurar Armazenamento Persistente de Rede

Configure volumes persistentes de backend para uma aplicação web:
* Crie um projeto chamado `page` e implante uma aplicação chamada `landing` usando a imagem `registry.domin12.example.com/nginxinc/nginx-unprivileged:latest`.
* Crie um `PersistentVolume` chamado `landing-pv` (`1Gi`, `ReadWriteMany`, mapeado para o servidor/caminho NFS correto).
* Crie uma `PersistentVolumeClaim` chamada `landing-pvc` correspondendo às mesmas especificações e storage class.
* Monte o volume no deployment da aplicação em `/usr/share/nginx/html` e escale a aplicação para `3` pods.

### Solução

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

## 19. Instalar um Operator

Estenda as funcionalidades do cluster implantando um componente automatizado de infraestrutura:
* Instale o operator `file-integrity`.
* O operator deve ter como alvo o projeto `openshift-file-integrity`.
* A estratégia de aprovação de atualização deve ser definida como `Automatic`.
* Garanta que as métricas de monitoramento do cluster estejam ativas/criadas para este projeto.

### Solução

```bash
oc whoami --show-console
```

```text
Operators -> OperatorHub -> search for the requested operator -> Install
Use the namespace and approval strategy specified in the exam. The transcript describes this as a simple console task, but the exact values still matter.
```

## 20. Agendar um CronJob Automatizado

Crie uma tarefa em lote recorrente dentro da arquitetura do cluster:
* No projeto `elementum`, implante um `CronJob` chamado `job-runner` usando a imagem `registry.domain12.example.com/library/job-runner:latest`.
* **Cronograma:** Executar exatamente às `04:05` no 2º dia de cada mês.
* **Limite de histórico:** Defina o limite de histórico de execuções bem-sucedidas para `14`.
* O job deve ser executado utilizando uma Service Account personalizada chamada `magna`.

### Solução

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

## 21. Configurar um Modelo de Projeto Personalizado (Project Template)

Imponha limites de recursos corporativos automaticamente em cada nova criação de projeto:
* Gere e personalize o modelo de projeto de bootstrap do cluster.
* Configure-o para que qualquer novo projeto receba automaticamente um `LimitRange` chamado `PROJECT_NAME-limits`.
* **Restrições de memória do container no modelo:** Mínimo `128Mi`, Máximo `1Gi`, Limite padrão `512Mi`, Requisição padrão `256Mi`.
* Aplique o modelo em todo o cluster através da configuração global de projetos.

### Solução

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

## 22. Configurar uma Sonda de Saúde (Liveness Probe)

Aumente a resiliência da aplicação implementando autorreparação automática:
* Dentro do projeto `mercary`, escolha como alvo o deployment config / deployment chamado `atlas`.
* Adicione uma **Sonda de Liveness** (Liveness Probe) que execute uma verificação de socket TCP na porta `8080`.
* Configure a sonda para ter um atraso inicial de `10` segundos e um tempo limite (timeout) de `30` segundos. Garanta que as alterações sobrevivam a reconstruções da imagem.

### Solução

```bash
oc project mercury
oc get pods
oc set probe --liveness --open-tcp 8080 --initial-delay-seconds 10 --timeout-seconds 30 deploy/atlas
oc describe deploy/atlas | grep Live
```
