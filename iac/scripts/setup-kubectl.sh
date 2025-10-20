#!/bin/bash

# Script para configurar kubectl para el cluster del hackathon
# Uso: ./setup-kubectl.sh [REGION]

set -e

# Configuración
REGION=${1:-us-east-1}
CLUSTER_NAME="hackathon-cluster"

echo "⚙️  Configurando kubectl para el cluster del hackathon"
echo "📍 Región: $REGION"
echo "🏷️  Cluster: $CLUSTER_NAME"
echo ""

# Verificar que AWS CLI está configurado
echo "🔍 Verificando AWS CLI..."
aws sts get-caller-identity --region $REGION > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ AWS CLI no está configurado"
    exit 1
fi

# Configurar kubectl
echo "🔧 Configurando kubectl..."
aws eks update-kubeconfig \
    --region $REGION \
    --name $CLUSTER_NAME

if [ $? -eq 0 ]; then
    echo "✅ kubectl configurado correctamente"
else
    echo "❌ Error configurando kubectl"
    exit 1
fi

echo ""
echo "🔍 Verificando conectividad..."

# Verificar nodos
echo "📋 Nodos disponibles:"
kubectl get nodes -o wide

echo ""
echo "📋 Información del cluster:"
kubectl cluster-info

echo ""
echo "📋 Contexto actual:"
kubectl config current-context

echo ""
echo "🎉 ¡kubectl configurado y listo para usar!"
echo ""
echo "🚀 Comandos útiles:"
echo "   • Ver nodos: kubectl get nodes"
echo "   • Ver pods: kubectl get pods --all-namespaces"  
echo "   • Cambiar contexto: kubectl config use-context <context>"
echo "   • Ver contextos: kubectl config get-contexts"