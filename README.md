# Hackathon K8s

## Descripción

Este repositorio contiene toda la **Infraestructura como Código (IaC)** y **manifiestos de Kubernetes** necesarios para levantar un cluster completo durante el hackathon. El proyecto está diseñado para facilitar el despliegue rápido y reproducible de aplicaciones en Kubernetes.

## Requisitos & Tecnologías

### Prerequisitos
- **Git** - Control de versiones
- **AWS CLI** v2 - Cliente de línea de comandos de AWS
- **kubectl** - Cliente de línea de comandos de Kubernetes
- **Helm** - Gestor de paquetes para Kubernetes
- **Cuenta AWS** con permisos para EKS, EC2, VPC, IAM

### Stack Tecnológico
- [Kubernetes](https://kubernetes.io/) - Orquestador de contenedores
- [AWS CloudFormation](https://aws.amazon.com/cloudformation/) - Infrastructure as Code
- [Amazon EKS](https://aws.amazon.com/eks/) - Kubernetes gestionado en AWS
- [Helm](https://helm.sh/) - Gestor de paquetes K8s
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) - Controlador de ingreso

## Estructura del Proyecto

```
📦 hackaton-k8s/
├── 📂 iac/                         # Infrastructure as Code
│   ├── 📂 cloudformation/          # Templates de CloudFormation
│   │   ├── eks-cluster.yaml         # Stack principal del cluster EKS
│   │   ├── vpc-network.yaml         # Red y subredes
│   │   ├── node-groups.yaml         # Grupos de nodos workers
│   │   ├── iam-roles.yaml           # Roles y políticas IAM
│   └── 📂 scripts/                 # Scripts de automatización
│       ├── deploy-stack.sh          # Despliegue automático completo
│       ├── cleanup-stack.sh         # Limpieza automática de recursos
│       └── setup-kubectl.sh         # Configuración de kubectl
├── 📂 manifests/                   # Manifiestos K8s
│   └── 📂 frontend/                # Aplicación Frontend del hackathon
│       ├── configmap.yaml           # ConfigMap con HTML personalizable
│       ├── deployment.yaml          # Deployment del frontend
│       ├── service.yaml             # Service para el frontend
│       └── ingress.yaml             # Ingress con routing por paths
├── 📄 README.md                    # Documentación principal del proyecto
├── 📄 K8S_CHEAT_SHEET.md           # Guía de comandos de Kubernetes
```

##  Instalación

### 1. Clonar el Repositorio
```bash
git clone https://github.com/dev-elliotesco/hackaton-k8s.git
cd hackaton-k8s
```

### 2. Verificar Herramientas
```bash
# Verificar AWS CLI
aws --version

# Verificar kubectl
kubectl version --client

# Verificar Helm
helm version
```

### 3. Configurar AWS CLI
```bash

# Configurar credenciales AWS
aws configure
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region: us-east-1
# Default output format: json

# Verificar configuración
aws sts get-caller-identity
```

## Configuración y Despliegue

### Opción 1: Despliegue Automático (Recomendado)
```bash
# Navegar al directorio de scripts
cd iac/scripts

# Hacer ejecutable el script (Linux/Mac)
chmod +x deploy-stack.sh

# Ejecutar despliegue completo (toma ~20-25 minutos)
./deploy-stack.sh us-east-1

# El script hace todo automáticamente:
# 1. VPC y red pública
# 2. Roles IAM necesarios  
# 3. Cluster EKS
# 4. Un nodo worker t3.large (hasta ~30 pods)
# 5. Configura kubectl automáticamente
```

### Opción 2: Despliegue Manual (paso a paso)
```bash
# Navegar al directorio de CloudFormation
cd iac/cloudformation

# 1. Desplegar VPC y red (~3 min)
aws cloudformation create-stack \
  --stack-name hackathon-vpc \
  --template-body file://vpc-network.yaml \
  --region us-east-1

# 2. Desplegar roles IAM (~2 min)
aws cloudformation create-stack \
  --stack-name hackathon-iam \
  --template-body file://iam-roles.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1

# 3. Desplegar cluster EKS (~15 min)
aws cloudformation create-stack \
  --stack-name hackathon-eks \
  --template-body file://eks-cluster.yaml \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# 4. Desplegar nodo worker (~5 min)
aws cloudformation create-stack \
  --stack-name hackathon-nodes \
  --template-body file://node-groups.yaml \
  --region us-east-1
```

### Configurar kubectl
```bash
# Configurar kubectl para conectar al cluster EKS
aws eks update-kubeconfig --region us-east-1 --name hackathon-cluster

# Verificar conectividad
kubectl get nodes
kubectl get pods --all-namespaces

# Verificar que el cluster está listo
kubectl get svc kubernetes
```

##  Ejecución y Despliegue

### 1. Verificar Cluster
```bash
# Ver información del cluster
kubectl cluster-info
kubectl get nodes -o wide

# Verificar capacidad de pods
kubectl describe node | grep -A 5 "Allocatable"
```

### 2. Crear Namespace para la Aplicación
```bash
# Crear namespace para el proyecto del hackathon
kubectl create namespace hackaton-app

# Verificar que el namespace fue creado
kubectl get namespaces
```

### 3. Instalar NGINX Ingress Controller con Helm
```bash
# Agregar el repositorio de Helm para NGINX Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Instalar NGINX Ingress Controller (optimizado para EKS)
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \

# Verificar instalación
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Esperar a que el LoadBalancer esté listo (puede tomar 2-3 minutos)
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -w
```

### 4. Desplegar Aplicación Base del Hackathon
```bash
# Desplegar todos los manifiestos del hackathon
kubectl apply -f manifests/frontend/ -n hackaton-app

# Verificar que los recursos se crearon correctamente
kubectl get deployment,service,ingress,configmap -n hackaton-app

# Ver los logs del deployment
kubectl logs -f deployment/frontend-app -n hackaton-app
```

## Personalización para Participantes

### Cambiar tu nombre en la aplicación
Edita el archivo `manifests/frontend/configmap.yaml` y cambia:
```html
<!-- CAMBIA ESTE NOMBRE POR EL TUYO -->
<div class="participant-name">Participante Demo</div>
```

### Agregar tu ruta personalizada
Edita el archivo `manifests/frontend/ingress.yaml` y agrega tu ruta:
```yaml
# Copia este bloque y cambia "demo" por tu nombre
- path: /tu-nombre(/|$)(.*)
  pathType: ImplementationSpecific
  backend:
    service:
      name: frontend-service
      port:
        number: 80
```

### Aplicar cambios
```bash
# Aplicar solo el ConfigMap actualizado
kubectl apply -f manifests/frontend/configmap.yaml -n hackaton-app

# Aplicar el Ingress actualizado
kubectl apply -f manifests/frontend/ingress.yaml -n hackaton-app

# Reiniciar pods para cargar el nuevo ConfigMap
kubectl rollout restart deployment/frontend-app -n hackaton-app
```

### 5. Verificar Despliegue
```bash
# Verificar pods en el namespace del hackathon
kubectl get pods -n hackaton-app

# Verificar todos los pods en todos los namespaces
kubectl get pods --all-namespaces

# Verificar servicios en el namespace del hackathon
kubectl get svc -n hackaton-app

# Verificar servicios en todos los namespaces
kubectl get svc --all-namespaces

# Verificar que NGINX Ingress esté listo
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Obtener la URL externa del Load Balancer
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx
```

### 6. Acceder a las Aplicaciones del Hackathon
```bash
# Obtener URL del NGINX Ingress Load Balancer
INGRESS_HOST=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# URLs disponibles por defecto
echo "🏠 Aplicación base: http://$INGRESS_HOST"
echo "🟦 Ruta demo: http://$INGRESS_HOST/demo"

# Verificar que el ingress esté configurado
kubectl get ingress hackathon-ingress -n hackaton-app

# Ver logs si hay problemas
kubectl logs -f deployment/frontend-app -n hackaton-app
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```
### URLs de Ejemplo para Participantes
```bash
# Ejemplos de URLs personalizadas
echo "Participante Juan: http://$INGRESS_HOST/juan"
echo "Equipo Alpha: http://$INGRESS_HOST/alpha"
echo "Equipo Beta: http://$INGRESS_HOST/beta"
```

## Limpiar Recursos

### Limpieza Automática (Recomendado)
```bash
# Navegar a los scripts
cd iac/scripts

# Ejecutar script de limpieza
./cleanup-stack.sh us-east-1

# Este script elimina TODO:
# - Aplicaciones del cluster
# - Node group y nodos
# - Cluster EKS  
# - Roles IAM
# - VPC y red
# - Configuración local de kubectl
```

### Limpieza Manual
```bash
# 1. Limpiar aplicaciones primero
kubectl delete all --all -n default
kubectl delete ingress --all
kubectl delete pvc --all

# 2. Eliminar stacks en orden inverso
aws cloudformation delete-stack --stack-name hackathon-nodes
aws cloudformation delete-stack --stack-name hackathon-eks  
aws cloudformation delete-stack --stack-name hackathon-iam
aws cloudformation delete-stack --stack-name hackathon-vpc

# 3. Verificar eliminación
aws cloudformation list-stacks --stack-status-filter DELETE_COMPLETE
```

## Autor

- Elliot Escovicth Riaño 
- [Github](https://github.com/dev-elliotesco)
- [LinkedIn](https://https://www.linkedin.com/in/elliot-escovitch-580007205/)
- Correo electrónico: dev.elliot.escovitch@gmail.com