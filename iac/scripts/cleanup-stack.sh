#!/bin/bash

# Script para eliminar toda la infraestructura del hackathon K8s
# Uso: ./cleanup-stack.sh [REGION]

set -e  # Salir si hay algún error

# Configuración
REGION=${1:-us-east-1}
CLUSTER_NAME="hackathon-cluster"

echo "🧹 Iniciando limpieza de infraestructura del Hackathon K8s"
echo "📍 Región: $REGION"
echo "🏷️  Cluster: $CLUSTER_NAME"
echo ""

# Función para esperar a que un stack sea eliminado
wait_for_stack_deletion() {
    local stack_name=$1
    
    echo "⏳ Esperando eliminación del stack '$stack_name'..."
    
    aws cloudformation wait stack-delete-complete \
        --stack-name $stack_name \
        --region $REGION
        
    if [ $? -eq 0 ]; then
        echo "✅ Stack '$stack_name' eliminado correctamente"
    else
        echo "❌ Error eliminando el stack '$stack_name'"
        # No salir aquí, intentar con los siguientes
    fi
}

# Verificar que AWS CLI está configurado
echo "🔍 Verificando configuración de AWS CLI..."
aws sts get-caller-identity --region $REGION > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ AWS CLI no está configurado. Ejecuta 'aws configure'"
    exit 1
fi

echo "⚠️  ADVERTENCIA: Esto eliminará toda la infraestructura del hackathon"
echo "   Esto incluye:"
echo "   • Cluster EKS y todos los pods"
echo "   • Nodo worker y volúmenes"
echo "   • VPC, subnets y security groups"
echo "   • Roles IAM"
echo ""

read -p "¿Continuar con la eliminación? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "❌ Eliminación cancelada"
    exit 0
fi

echo ""
echo "🚀 Iniciando eliminación en orden inverso..."
echo ""

# 1. Eliminar aplicaciones del cluster primero (si existe)
echo "1️⃣  Limpiando aplicaciones del cluster..."
if kubectl get nodes &>/dev/null; then
    echo "   • Eliminando todos los recursos de aplicaciones..."
    kubectl delete all --all -n default --timeout=60s || true
    kubectl delete ingress --all --timeout=60s || true
    kubectl delete pvc --all --timeout=60s || true
    echo "   ✅ Aplicaciones limpiadas"
else
    echo "   ℹ️  Cluster no accesible, continuando..."
fi
echo ""

# 2. Eliminar node group
echo "2️⃣  Eliminando nodo worker..."
aws cloudformation delete-stack \
    --stack-name ${CLUSTER_NAME}-nodes \
    --region $REGION || echo "   ⚠️  Stack de nodos no encontrado"

wait_for_stack_deletion "${CLUSTER_NAME}-nodes"
echo ""

# 3. Eliminar cluster EKS
echo "3️⃣  Eliminando cluster EKS..."
aws cloudformation delete-stack \
    --stack-name ${CLUSTER_NAME}-eks \
    --region $REGION || echo "   ⚠️  Stack del cluster no encontrado"

wait_for_stack_deletion "${CLUSTER_NAME}-eks"
echo ""

# 4. Eliminar roles IAM
echo "4️⃣  Eliminando roles IAM..."
aws cloudformation delete-stack \
    --stack-name ${CLUSTER_NAME}-iam \
    --region $REGION || echo "   ⚠️  Stack de IAM no encontrado"

wait_for_stack_deletion "${CLUSTER_NAME}-iam"
echo ""

# 5. Eliminar VPC y red
echo "5️⃣  Eliminando VPC y red..."
aws cloudformation delete-stack \
    --stack-name ${CLUSTER_NAME}-vpc \
    --region $REGION || echo "   ⚠️  Stack de VPC no encontrado"

wait_for_stack_deletion "${CLUSTER_NAME}-vpc"
echo ""

# 6. Limpiar configuración local de kubectl
echo "6️⃣  Limpiando configuración local..."
kubectl config delete-context arn:aws:eks:${REGION}:*:cluster/${CLUSTER_NAME} 2>/dev/null || true
kubectl config delete-cluster arn:aws:eks:${REGION}:*:cluster/${CLUSTER_NAME} 2>/dev/null || true
echo "   ✅ Configuración local limpiada"
echo ""

# Verificar que todo se eliminó
echo "🔍 Verificando eliminación..."
stacks=$(aws cloudformation list-stacks \
    --region $REGION \
    --query "StackSummaries[?contains(StackName, '${CLUSTER_NAME}') && StackStatus != 'DELETE_COMPLETE'].StackName" \
    --output text)

if [ -z "$stacks" ]; then
    echo ""
    echo "🎉 ¡Limpieza completada exitosamente!"
    echo ""
    echo "✅ Todos los recursos han sido eliminados:"
    echo "   • Cluster EKS: eliminado"
    echo "   • Nodos workers: eliminados" 
    echo "   • VPC y red: eliminadas"
    echo "   • Roles IAM: eliminados"
    echo "   • Configuración kubectl: limpiada"
    echo ""
    echo "💰 No se generarán más costos por estos recursos"
else
    echo ""
    echo "⚠️  Algunos stacks aún existen:"
    echo "$stacks"
    echo ""
    echo "Puedes verificar el estado en la consola de CloudFormation:"
    echo "https://console.aws.amazon.com/cloudformation/home?region=${REGION}"
fi