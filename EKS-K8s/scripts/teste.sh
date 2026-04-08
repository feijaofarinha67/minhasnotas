#!/bin/bash
set -euo pipefail

#Variables
ACCOUNT_ID="${ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-aws-load-balancer-controller}"
NAMESPACE="${NAMESPACE:-kube-system}"
POLICY_NAME="${POLICY_NAME:-AWSLoadBalancerControllerIAMPolicy}"
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"
POLICY_FILE="${POLICY_FILE:-iam_policy.json}"
POLICY_URL="${POLICY_URL:-https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json}"
CLUSTER_NAME="${CLUSTER_NAME:-${1:-}}"
REGION="${REGION:-${2:-us-east-1}}"
RELEASE_NAME="${RELEASE_NAME:-aws-load-balancer-controller}"

log() {
    echo "[$(date +'%H:%M:%S')] $1"
}

if [[ -z "$CLUSTER_NAME" ]]; then
    echo "informe o nome do cluster"
    echo "use: ./example.sh <cluster-name> [region]"
    exit 1
fi 

# Update kubeconfig para acesso ao cluster
#TODO
# log "Configurando kubeconfig para o cluster $CLUSTER_NAME"
# aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --alias "CLUSTER_NAME" >/dev/null
# log "kubeconfig atualizado com sucesso"

# OIDC provider
log "Verificando OIDC provider"

OIDC_ISSUER=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query "cluster.identity.oidc.issuer" --output text)

if [[ "$OIDC_ISSUER" == "None" || -z "$OIDC_ISSUER" ]]; then
    log "OIDC não encontrado, criando..."
    eksctl utils associate-iam-oidc-provider --region "$REGION" --cluster "$CLUSTER_NAME" --approve
    log "OIDC criado com sucesso"
else 
    log "OIDC já configurado"
fi

# Service Account
log "Checking IAM Policy for ServiceAccount"
if aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
    log "Policy already exists: $POLICY_ARN"
else
    log "Policy not found, creating..."
    if [[ ! -f "$POLICY_FILE" ]]; then
        log "Downloading policy from: $POLICY_URL"
        curl -fLo "$POLICY_FILE" "$POLICY_URL"
    else
        log "Policy file found locally"
    fi
    aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "file://$POLICY_FILE"
    log "IAM Policy created successfully"
fi
log "Criando/Atualizando ServiceAccount"
eksctl create iamserviceaccount --cluster="$CLUSTER_NAME" --region="$REGION" --namespace="$NAMESPACE" --name="$SERVICE_ACCOUNT_NAME" --attach-policy-arn="$POLICY_ARN" --override-existing-serviceaccounts --approve
log "ServiceAccount configurada"

# Verificando instalação do Helm e instalando LB Controler
if ! command -v helm >/dev/null 2>&1; then
    echo "Erro: Helm não está instalado."
    echo "Execute o script de bootstrap antes."
    exit 1
fi

log "Helm found: $(helm version --short)"
log "Configuring Helm repos"
helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
helm repo update >/dev/null
log "Updated Helm repos"

log "Instalando/Atualizando AWS Load Balancer Controller"
helm upgrade --install "$RELEASE_NAME" eks/aws-load-balancer-controller --namespace "$NAMESPACE" --create-namespace --set clusterName="$CLUSTER_NAME" --set serviceAccount.create=false --set serviceAccount.name="$SERVICE_ACCOUNT_NAME" --set region="$REGION" --wait
log "Helm LB Controller depoloy successful"