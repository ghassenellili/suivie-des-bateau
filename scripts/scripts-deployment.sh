#!/bin/bash

# ==================================================
# SCRIPT: setup-cicd.sh
# Initialisation complète du pipeline CI/CD
# ==================================================

set -e  # Exit on error

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup CI/CD Flutter - Jenkins - Docker - K8s${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Variables
DOCKER_USERNAME=${1:-"your-username"}
DOCKER_TOKEN=${2:-"your-token"}
KUBE_CONTEXT=${3:-"docker-desktop"}

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# ================================================== 
# 1. Vérifications des prérequis
# ==================================================
log_info "Vérification des prérequis...\n"

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 n'est pas installé!"
        return 1
    fi
    echo -e "${GREEN}✓${NC} $1 trouvé"
}

check_command "docker"
check_command "kubectl"
check_command "git"
check_command "curl"

echo ""

# ==================================================
# 2. Configuration Kubernetes
# ==================================================
log_info "Configuration Kubernetes...\n"

# Créer le namespace
log_info "Création du namespace flutter-app..."
kubectl create namespace flutter-app || log_warning "Namespace déjà existant"

# Créer le secret Docker Registry
log_info "Création du secret Docker Registry..."
kubectl create secret docker-registry docker-credentials \
    --docker-server=docker.io \
    --docker-username=${DOCKER_USERNAME} \
    --docker-password=${DOCKER_TOKEN} \
    -n flutter-app || log_warning "Secret déjà existant"

echo ""

# ==================================================
# 3. Appliquer les manifests Kubernetes
# ==================================================
log_info "Application des manifests Kubernetes...\n"

if [ ! -d "k8s" ]; then
    log_error "Répertoire k8s/ non trouvé!"
    exit 1
fi

log_info "Créer le namespace..."
kubectl apply -f k8s/namespace.yaml

log_info "Créer la ConfigMap..."
kubectl apply -f k8s/configmap.yaml

log_info "Créer le Deployment..."
kubectl apply -f k8s/deployment.yaml

log_info "Créer le Service..."
kubectl apply -f k8s/service.yaml

log_info "Créer l'HPA..."
kubectl apply -f k8s/hpa.yaml

log_info "Créer la NetworkPolicy..."
kubectl apply -f k8s/networkpolicy.yaml

log_info "Créer le PDB..."
kubectl apply -f k8s/pdb.yaml

echo ""

# ==================================================
# 4. Vérification du déploiement
# ==================================================
log_info "Vérification du déploiement...\n"

log_info "Attente du déploiement (timeout: 5min)..."
kubectl rollout status deployment/flutter-app -n flutter-app --timeout=5m

log_info "Pods en cours d'exécution:"
kubectl get pods -n flutter-app -o wide

log_info "Services:"
kubectl get svc -n flutter-app

echo ""

# ==================================================
# 5. Résumé
# ==================================================
log_info "========================================\n"
log_info "✅ Setup CI/CD terminé avec succès!\n"

SERVICE_IP=$(kubectl get svc flutter-app-service -n flutter-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
SERVICE_PORT=$(kubectl get svc flutter-app-service -n flutter-app -o jsonpath='{.spec.ports[0].port}')

echo -e "${GREEN}Application accessible à:${NC} http://${SERVICE_IP}:${SERVICE_PORT}"
echo ""
echo -e "${YELLOW}Prochaines étapes:${NC}"
echo "1. Configurer Jenkins (voir le guide complet)"
echo "2. Ajouter les credentials Docker dans Jenkins"
echo "3. Créer une nouvelle pipeline dans Jenkins"
echo "4. Ajouter le Jenkinsfile au repository"
echo "5. Configurer le Webhook sur GitHub/GitLab"
echo ""
echo -e "${BLUE}Commandes utiles:${NC}"
echo "  kubectl logs -f -n flutter-app -l app=flutter-app     # Logs en temps réel"
echo "  kubectl get pods -n flutter-app -w                    # Watch des pods"
echo "  kubectl describe pod <pod-name> -n flutter-app       # Détails d'un pod"
echo "  kubectl rollout history deployment/flutter-app -n flutter-app  # Historique"
echo ""

# ==================================================
# Script de déploiement manuel
# ==================================================

# ==================================================
# SCRIPT: deploy.sh
# Déploiement manuel d'une version spécifique
# ==================================================

#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: ./deploy.sh <version> [namespace]"
    echo "  version: tag de l'image Docker (ex: 1.0.0, latest)"
    echo "  namespace: namespace K8s (default: flutter-app)"
    exit 1
fi

VERSION=$1
NAMESPACE=${2:-"flutter-app"}
IMAGE="docker.io/your-username/flutter-app:${VERSION}"

echo "Déploiement de ${IMAGE} dans ${NAMESPACE}..."

# Mettre à jour l'image
kubectl set image deployment/flutter-app \
    flutter-app=${IMAGE} \
    -n ${NAMESPACE} \
    --record

# Attendre le rollout
kubectl rollout status deployment/flutter-app -n ${NAMESPACE} --timeout=5m

echo "✅ Déploiement réussi!"

# ==================================================
# Script de rollback
# ==================================================

#!/bin/bash

NAMESPACE=${1:-"flutter-app"}

echo "Rollback du déploiement dans ${NAMESPACE}..."

# Voir l'historique
echo "Historique des déploiements:"
kubectl rollout history deployment/flutter-app -n ${NAMESPACE}

echo ""
read -p "Entrez la révision à restaurer (ou laissez vide pour la précédente): " REVISION

if [ -z "$REVISION" ]; then
    kubectl rollout undo deployment/flutter-app -n ${NAMESPACE}
else
    kubectl rollout undo deployment/flutter-app -n ${NAMESPACE} --to-revision=${REVISION}
fi

echo "Attente du rollout..."
kubectl rollout status deployment/flutter-app -n ${NAMESPACE} --timeout=5m

echo "✅ Rollback réussi!"

# ==================================================
# Script de monitoring
# ==================================================

#!/bin/bash

NAMESPACE=${1:-"flutter-app"}

echo -e "\n=== Pods ==="
kubectl get pods -n ${NAMESPACE} -o wide

echo -e "\n=== Services ==="
kubectl get svc -n ${NAMESPACE}

echo -e "\n=== Deployment Status ==="
kubectl get deployment -n ${NAMESPACE}

echo -e "\n=== Recent Events ==="
kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp' | tail -10

echo -e "\n=== Pod Logs (last 100 lines) ==="
for pod in $(kubectl get pods -n ${NAMESPACE} -l app=flutter-app -o name); do
    echo ""
    echo "--- Logs from ${pod} ---"
    kubectl logs ${pod} -n ${NAMESPACE} --tail=100
done

# ==================================================
# Script de cleanup
# ==================================================

#!/bin/bash

NAMESPACE=${1:-"flutter-app"}

echo "⚠️  Suppression de tous les resources du namespace ${NAMESPACE}?"
read -p "Êtes-vous sûr? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Annulation..."
    exit 0
fi

log_info "Suppression du namespace ${NAMESPACE}..."
kubectl delete namespace ${NAMESPACE}

echo "✅ Cleanup réussi!"

# ==================================================
# Utilitaires
# ==================================================

# Voir les logs en temps réel
kubectl logs -f deployment/flutter-app -n flutter-app

# Port forward local
kubectl port-forward -n flutter-app service/flutter-app-service 8080:80

# Accéder à un pod
kubectl exec -it <pod-name> -n flutter-app -- /bin/sh

# Copier un fichier depuis un pod
kubectl cp flutter-app/<pod-name>:/app/logs.txt ./logs.txt

# Mettre à jour les ressources CPU/Memory
kubectl set resources deployment/flutter-app \
    -n flutter-app \
    --requests=cpu=200m,memory=256Mi \
    --limits=cpu=500m,memory=512Mi

# Scaler le deployment
kubectl scale deployment/flutter-app -n flutter-app --replicas=5

# Health check
curl -v http://localhost:8080/index.html

# ==================================================
# Nettoyage final
# ==================================================

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup terminé avec succès!${NC}"
echo -e "${GREEN}========================================${NC}\n"
