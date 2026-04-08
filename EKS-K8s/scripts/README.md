# AWS Load Balancer Controller — Script de Instalação

Script de automação para instalação e configuração do [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) em clusters EKS.

---

## Pré-requisitos

Antes de executar o script, certifique-se de que as seguintes ferramentas estão instaladas e configuradas:

| Ferramenta | Versão mínima | Descrição |
|---|---|---|
| `aws cli` | v2+ | Configurado com credenciais válidas e permissões adequadas |
| `eksctl` | qualquer | CLI para gerenciamento de clusters EKS |
| `kubectl` | compatível com o cluster | Configurado para acesso ao cluster |
| `helm` | v3+ | Gerenciador de pacotes Kubernetes — **obrigatório**, o script encerra com erro se não estiver presente |
| `curl` | qualquer | Usado para download da policy IAM caso o arquivo não exista localmente |

> **Atenção:** O script verifica a presença do Helm e encerra com erro caso não esteja instalado. As demais ferramentas devem ser instaladas previamente (via script de bootstrap ou manualmente).

### Instalação rápida dos pré-requisitos

```bash
# AWS CLI (Linux)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# eksctl
brew install eksctl  # macOS
# ou: https://eksctl.io/installation/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Uso

```bash
./script.sh <cluster-name> [region]
```

### Parâmetros

| Parâmetro | Obrigatório | Padrão | Descrição |
|---|---|---|---|
| `cluster-name` | Sim | — | Nome do cluster EKS alvo |
| `region` | Não | `us-east-1` | Região AWS do cluster |

### Exemplos

```bash
# Com região padrão (us-east-1)
./script.sh meu-cluster

# Com região específica
./script.sh meu-cluster sa-east-1
```

---

## Variáveis de Ambiente

Todas as variáveis podem ser sobrescritas via ambiente antes da execução:

| Variável | Padrão | Descrição |
|---|---|---|
| `CLUSTER_NAME` | 1º argumento | Nome do cluster EKS |
| `REGION` | `us-east-1` | Região AWS |
| `ACCOUNT_ID` | Auto-detectado via `aws sts` | ID da conta AWS |
| `NAMESPACE` | `kube-system` | Namespace Kubernetes de destino |
| `SERVICE_ACCOUNT_NAME` | `aws-load-balancer-controller` | Nome da ServiceAccount |
| `POLICY_NAME` | `AWSLoadBalancerControllerIAMPolicy` | Nome da policy IAM |
| `POLICY_FILE` | `iam_policy.json` | Caminho local do arquivo de policy |
| `POLICY_URL` | URL oficial v2.14.1 | URL para download da policy caso o arquivo não exista localmente |
| `RELEASE_NAME` | `aws-load-balancer-controller` | Nome do release Helm |

### Exemplo com variáveis customizadas

```bash
NAMESPACE=infra REGION=us-west-2 ./script.sh meu-cluster

# Usando um arquivo de policy local customizado
POLICY_FILE=./minha-policy.json ./script.sh meu-cluster
```

---

## O que o script faz

O script executa as seguintes etapas em ordem:

1. **Valida o nome do cluster** — encerra com erro se não for informado.
2. **Atualiza o kubeconfig** — executa `aws eks update-kubeconfig` para apontar `kubectl` ao cluster alvo.
3. **Verifica/cria o OIDC Provider** — necessário para autenticação de ServiceAccounts com IAM. Se não existir, cria via `eksctl`.
4. **Verifica/cria a policy IAM** — checa se a policy já existe na conta AWS antes de tentar criá-la. Caso não exista, verifica se o arquivo `iam_policy.json` está presente localmente; se não estiver, faz o download a partir da `POLICY_URL`.
5. **Cria/atualiza a IAM ServiceAccount** — associa a policy IAM à ServiceAccount no cluster via `eksctl`, com `--override-existing-service-accounts` para garantir idempotência.
6. **Verifica o Helm** — encerra com erro se o Helm não estiver instalado.
7. **Instala/atualiza via Helm** — adiciona o repositório `eks`, atualiza os repos e executa `helm upgrade --install` do chart `aws-load-balancer-controller`.

---

## Idempotência

O script foi projetado para ser seguro em reexecuções:

| Etapa | Comportamento na reexecução |
|---|---|
| kubeconfig | Sobrescreve sem erro |
| OIDC Provider | Verifica antes de criar |
| IAM Policy | Verifica antes de criar (`aws iam get-policy`) |
| ServiceAccount | `--override-existing-service-accounts` |
| Helm release | `helm upgrade --install` |

---

## Permissões IAM Necessárias

O usuário ou role que executar o script precisa das seguintes permissões mínimas:

- `sts:GetCallerIdentity`
- `eks:DescribeCluster`, `eks:UpdateClusterConfig`
- `iam:GetPolicy`, `iam:CreatePolicy`, `iam:AttachRolePolicy`, `iam:CreateRole`
- `cloudformation:*` (usado internamente pelo `eksctl`)

---

## Referências

- [Documentação oficial — AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Repositório do chart Helm](https://github.com/aws/eks-charts)
- [IAM Policy oficial (v2.14.1)](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json)
