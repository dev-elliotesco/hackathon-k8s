#!/bin/bash

# Script para desplegar la infraestructura completa del hackathon K8s
# Uso: ./deploy-stack.sh [REGION]

set -e  # Salir si hay algún error

# Configuración
REGION=${1:-us-east-1}
CLUSTER_NAME="hackathon-cluster"

echo "🚀 Iniciando despliegue de infraestructura para Hackathon K8s"
echo "📍 Región: $REGION"
echo "🏷️  Cluster: $CLUSTER_NAME"
echo ""

# Función para esperar a que un stack esté completo
wait_for_stack() {
    local stack_name=$1
    local action=$2
    
    echo "⏳ Esperando que el stack '$stack_name' esté $action..."
    
    aws cloudformation wait stack-${action}-complete \
        --stack-name $stack_name \
        --region $REGION
        
    if [ $? -eq 0 ]; then
        echo "✅ Stack '$stack_name' $action correctamente"
    else
        echo "❌ Error en el stack '$stack_name'"
        exit 1
    fi
}

# Verificar que AWS CLI está configurado
echo "🔍 Verificando configuración de AWS CLI..."
aws sts get-caller-identity --region $REGION > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ AWS CLI no está configurado. Ejecuta 'aws configure'"
    exit 1
fi
echo "✅ AWS CLI configurado correctamente"
echo ""

# 1. Desplegar VPC y red
echo "1️⃣  Desplegando VPC y red..."
aws cloudformation create-stack \
    --stack-name ${CLUSTER_NAME}-vpc \
    --template-body file://vpc-network.yaml \
    --region $REGION \
    --tags Key=Project,Value=hackathon-k8s Key=Environment,Value=development

wait_for_stack "${CLUSTER_NAME}-vpc" "create"
echo ""

# 2. Desplegar roles IAM
echo "2️⃣  Desplegando roles IAM..."
aws cloudformation create-stack \
    --stack-name ${CLUSTER_NAME}-iam \
    --template-body file://iam-roles.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --tags Key=Project,Value=hackathon-k8s Key=Environment,Value=development

wait_for_stack "${CLUSTER_NAME}-iam" "create"
echo ""

# 3. Desplegar cluster EKS
echo "3️⃣  Desplegando cluster EKS (esto puede tomar 10-15 minutos)..."
aws cloudformation create-stack \
    --stack-name ${CLUSTER_NAME}-eks \
    --template-body file://eks-cluster.yaml \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --tags Key=Project,Value=hackathon-k8s Key=Environment,Value=development

wait_for_stack "${CLUSTER_NAME}-eks" "create"
echo ""

# 4. Desplegar node group
echo "4️⃣  Desplegando nodo worker (esto puede tomar 5-10 minutos)..."
aws cloudformation create-stack \
    --stack-name ${CLUSTER_NAME}-nodes \
    --template-body file://node-groups.yaml \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --tags Key=Project,Value=hackathon-k8s Key=Environment,Value=development

wait_for_stack "${CLUSTER_NAME}-nodes" "create"
echo ""

# 5. Configurar kubectl
echo "5️⃣  Configurando kubectl..."
aws eks update-kubeconfig \
    --region $REGION \
    --name $CLUSTER_NAME

if [ $? -eq 0 ]; then
    echo "✅ kubectl configurado correctamente"
else
    echo "❌ Error configurando kubectl"
    exit 1
fi

# Verificar conectividad
echo ""
echo "🔍 Verificando conectividad del cluster..."
kubectl get nodes

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 ¡Infraestructura desplegada exitosamente!"
    echo ""
    echo "📋 Información del cluster:"
    echo "   • Nombre: $CLUSTER_NAME"
    echo "   • Región: $REGION" 
    echo "   • Nodos: 1 x t3.large (hasta ~30 pods)"
    echo "   • Tipo: Público (acceso directo desde internet)"
    echo ""
    echo "🚀 Próximos pasos:"
    echo "   1. Instalar NGINX Ingress: helm install nginx-ingress..."
    echo "   2. Desplegar aplicaciones: kubectl apply -f manifests/frontend/"
    echo "   3. ¡Empezar el hackathon!"
    echo ""
    echo "🧹 Para limpiar recursos cuando termines:"
    echo "   ./cleanup-stack.sh $REGION"
else
    echo "❌ No se pudo conectar al cluster. Revisa los logs."
    exit 1
fi