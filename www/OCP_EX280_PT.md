# Questões Práticas para o Exame OpenShift EX280

## Informações do Ambiente do Cluster
* **Domínio Wild-card do cluster:** `apps.ocp4.example.com`
* **URL da Documentação:** `https://access.redhat.com/documentation/en-us/openshift_container_platform/4.12/`
* **Localização da senha do Kubeadmin:** `/home/student/kubeadmin-password` (na VM workbench)
* **Senha do Root para a VM workbench:** Fornecida durante o exame

---

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

## 2. Configurar Permissões de Cluster
Atribua e restrinja privilégios em nível de cluster da seguinte forma:
* O usuário `jobs` deve ser capaz de modificar e gerenciar o cluster (`cluster-admin`).
* O usuário `wozniak` deve ser capaz de criar novos projetos.
* O usuário `armstrong` deve ser impedido de criar qualquer projeto.
* O usuário `wozniak` deve ser impedido de modificar configurações globais do cluster.
* Remova ou desative completamente o acesso do usuário padrão `kubeadmin` do cluster.

## 3. Configurar Permissões de Projeto
Crie os projetos necessários e aplique papéis de usuário específicos:
* Crie os seguintes projetos: `apollo`, `titan`, `gemini`, `bluebook` e `apache`.
* O usuário `armstrong` deve ser o administrador (`admin`) dos projetos `apollo` e `titan`.
* O usuário `collins` deve ter acesso de apenas leitura (`view`) ao projeto `apollo`.

## 4. Criar Grupos e Configurar Permissões
Gerencie as permissões de acesso das equipes usando grupos do OpenShift:
* Crie um grupo chamado `commander` e adicione o usuário `armstrong` como membro.
* Crie um grupo chamado `pilot` e adicione os usuários `adlerin` e `collins` como membros.
* Os membros do grupo `commander` devem ter permissões de edição (`edit`) no projeto `apollo`.
* Os membros do grupo `pilot` devem ter permissões de visualização (`view`) no projeto `apollo`.

## 5. Configurar Quotas de Recursos (Resource Quotas) para um Projeto
Aplique restrições de uso de recursos dentro de um projeto específico:
* Crie uma `ResourceQuota` chamada `ex280-quota` dentro do projeto `apache`.
* A memória total consumida por todos os containers não pode exceder `1Gi`.
* O uso total de CPU por todos os containers não pode exceder `2` cores completos.
* O número máximo de Replication Controllers não pode exceder `3`.
* O número máximo de Pods não pode exceder `3`.
* O número máximo de Services não pode exceder `6`.

## 6. Configurar Intervalos de Limite (Limit Ranges) para um Projeto
Defina requisições e restrições de recursos padrão para workloads individuais:
* Crie um `LimitRange` chamado `ex280-limits` dentro do projeto `bluebook`.
* **Restrições de Pod:** A memória deve estar entre `100Mi` e `300Mi`; a CPU deve estar entre `10m` e `500m`.
* **Restrições de Container:** A memória deve estar entre `100Mi` e `300Mi` (com uma requisição padrão de `100Mi`); a CPU deve estar entre `10m` e `500m` (com uma requisição padrão de `100m`).

## 7. Implantar uma Aplicação via Helm Chart
Implante uma aplicação de terceiros usando um repositório Helm:
* Garanta que o projeto de destino `ascii-hall` exista.
* Adicione o repositório localizado em `http://helm.domain.23.example.com/charts/`.
* Implante o chart chamado `redhat-cinema` dentro do projeto. Valide se a implantação escalou com sucesso.

## 8. Escalar uma Aplicação Manualmente
Ajuste as instâncias de uma aplicação para atender aos requisitos de dimensionamento:
* Navegue até o projeto chamado `lerna`.
* Identifique a implantação (deployment) da aplicação chamada `hydra`.
* Escale manualmente a aplicação `hydra` para exatamente `5` réplicas.

## 9. Configurar Autonivelamento (Autoscaling) para uma Aplicação
Implemente a automação de dimensionamento horizontal com base na demanda de recursos:
* Dentro do projeto `gru`, configure um Horizontal Pod Autoscaler (HPA) para o deployment/deploymentconfig chamado `scale`.
* **Mínimo de réplicas:** `6`
* **Máximo de réplicas:** `40`
* **Uso de CPU alvo:** `60%`
* Defina os recursos do container da aplicação para ter uma requisição de CPU (requests) de `25m` e um limite de CPU (limits) de `100m`.

## 10. Configurar e Implantar uma Rota Segura (Secure Route)
Exponha uma aplicação via HTTPS usando uma rota com terminação TLS do tipo Edge:
* Trabalhe dentro do projeto chamado `area51` para a aplicação `oxcart`.
* Gere certificados TLS autoassinados para o subject: `/C=US/ST=NC/L=Raleigh/O=RedHat/OU=RHT/CN=oxcart.apps.ocp4.example.com`
* Proteja a rota usando o certificado e a chave gerados.
* A aplicação deve estar acessível de forma segura em `https://oxcart.apps.ocp4.example.com`.

## 11. Configurar um Secret
Armazene configurações sensíveis de forma segura dentro do cluster:
* Dentro do projeto `math`, crie um secret genérico chamado `magic`.
* O secret deve conter o seguinte par chave-valor: `Decoder_Ring: ASDA142hfh-gfrhhueo-erfdk345v`.

## 12. Injetar Valores de Secret em uma Aplicação
Forneça dados sensíveis para a implantação de uma aplicação de forma dinâmica:
* No projeto `math`, injete o secret `magic` no deployment config / deployment chamado `qed` como variáveis de ambiente.
* Verifique se, após a injeção do secret, a aplicação é atualizada com sucesso e para de exibir a mensagem de erro: `"App is not configured properly"`.

## 13. Solucionar Problemas de Implantação com Restrição de Recursos
Depure uma aplicação com falha que não consegue agendar pods devido a restrições:
* Inspecione a aplicação `mercury` dentro do projeto `bluebook`.
* Sem deletar ou recriar o objeto de deployment base, corrija a configuração para que os pods possam ser agendados com sucesso (Dica: Verifique e corrija requisições excessivas ou incorretas de recursos de CPU/Memória).

## 14. Injetar Dados de Configuração via ConfigMaps
Implante e atualize uma aplicação usando configurações textuais externalizadas:
* Crie um projeto chamado `czech`.
* Implante uma aplicação chamada `ernie` usando a imagem `quay.io/redhattraining/hello-openshift`.
* Crie um `ConfigMap` chamado `ex280-cm` contendo a chave `RESPONSE` com o valor `'six czech cricket critics'`.
* Injete este ConfigMap no deployment para que a aplicação exiba a frase ao ser acessada em `http://ernie.apps.ocp4.example.com`.

## 15. Configurar uma Service Account com SCCs Específicas
Eleve os privilégios para o fluxo de trabalho de uma aplicação especializada:
* Dentro do projeto `apples`, crie uma Service Account chamada `ex280-sa`.
* Conceda a esta service account a capacidade de executar containers usando qualquer ID de usuário (Security Context Constraint do tipo `anyuid`).

## 16. Corrigir Seletores de Serviço e Identificadores de Pods
Depure um serviço que falha ao rotear tráfego para os pods ativos da aplicação:
* Solucione os problemas da aplicação `oranges` no projeto `apples`.
* Garanta que a aplicação esteja configurada para usar a service account `ex280-sa`.
* Corrija quaisquer divergências entre as labels do seletor do Service e as labels do Pod para que a rota da aplicação responda corretamente.

## 17. Configurar uma Política de Rede (Network Policy)
Restrinja o tráfego de rede entre namespaces para proteger um banco de dados:
* Dentro do projeto `database`, crie uma `NetworkPolicy` chamada `db-allow-mysql-comm`.
* A política se aplica aos pods que possuem a label `network.openshift.io/policy-group: database`.
* Restrinja o tráfego de entrada (ingress) exclusivamente para implantações vindas do projeto `checker`.
* O tráfego deve ser filtrado a partir de namespaces com a label `team=devsecops` e pods com a label `deployment=web-mysql`.
* Permita conexões de entrada apenas na porta `3304/TCP`.

## 18. Configurar Armazenamento Persistente de Rede
Configure volumes persistentes de backend para uma aplicação web:
* Crie um projeto chamado `page` e implante uma aplicação chamada `landing` usando a imagem `registry.domin12.example.com/nginxinc/nginx-unprivileged:latest`.
* Crie um `PersistentVolume` chamado `landing-pv` (`1Gi`, `ReadWriteMany`, mapeado para o servidor/caminho NFS correto).
* Crie uma `PersistentVolumeClaim` chamada `landing-pvc` correspondendo às mesmas especificações e storage class.
* Monte o volume no deployment da aplicação em `/usr/share/nginx/html` e escale a aplicação para `3` pods.

## 19. Instalar um Operator
Estenda as funcionalidades do cluster implantando um componente automatizado de infraestrutura:
* Instale o operator `file-integrity`.
* O operator deve ter como alvo o projeto `openshift-file-integrity`.
* A estratégia de aprovação de atualização deve ser definida como `Automatic`.
* Garanta que as métricas de monitoramento do cluster estejam ativas/criadas para este projeto.

## 20. Agendar um CronJob Automatizado
Crie uma tarefa em lote recorrente dentro da arquitetura do cluster:
* No projeto `elementum`, implante um `CronJob` chamado `job-runner` usando a imagem `registry.domain12.example.com/library/job-runner:latest`.
* **Cronograma:** Executar exatamente às `04:05` no 2º dia de cada mês.
* **Limite de histórico:** Defina o limite de histórico de execuções bem-sucedidas para `14`.
* O job deve ser executado utilizando uma Service Account personalizada chamada `magna`.

## 21. Configurar um Modelo de Projeto Personalizado (Project Template)
Imponha limites de recursos corporativos automaticamente em cada nova criação de projeto:
* Gere e personalize o modelo de projeto de bootstrap do cluster.
* Configure-o para que qualquer novo projeto receba automaticamente um `LimitRange` chamado `PROJECT_NAME-limits`.
* **Restrições de memória do container no modelo:** Mínimo `128Mi`, Máximo `1Gi`, Limite padrão `512Mi`, Requisição padrão `256Mi`.
* Aplique o modelo em todo o cluster através da configuração global de projetos.

## 22. Coletar Informações do Cluster para o Suporte Red Hat
Reúna dados de diagnóstico do cluster necessários para abertura de chamados de suporte:
* Use as ferramentas de diagnóstico do cluster (`must-gather`) para coletar os logs e definições.
* Compacte os dados coletados em um arquivo tarball chamado `ex280-ocp.<CLUSTER_ID>.tar.gz`, substituindo `<CLUSTER_ID>` pelo identificador exclusivo do seu cluster.
* Faça o upload do arquivo usando o script utilitário localizado em `/usr/local/bin/upload-cluster-data`.

## 23. Configurar uma Sonda de Saúde (Liveness Probe)
Aumente a resiliência da aplicação implementando autorreparação automática:
* Dentro do projeto `mercary`, escolha como alvo o deployment config / deployment chamado `atlas`.
* Adicione uma **Sonda de Liveness** (Liveness Probe) que execute uma verificação de socket TCP na porta `8080`.
* Configure a sonda para ter um atraso inicial de `10` segundos e um tempo limite (timeout) de `30` segundos. Garanta que as alterações sobrevivam a reconstruções da imagem.