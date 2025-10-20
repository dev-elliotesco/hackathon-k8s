# 🚀 Kubernetes Cheat Sheet - Guía de Aprendizaje

## 📋 Comandos Básicos

### Información del Cluster
```bash
# Ver información del cluster
kubectl cluster-info

# Ver versión de kubectl y del cluster
kubectl version

# Ver nodos disponibles
kubectl get nodes

# Ver nodos con más detalles (IPs, OS, versión)
kubectl get nodes -o wide

# Ver capacidad y uso de recursos de los nodos
kubectl describe nodes

# Ver métricas de uso de nodos (requiere metrics-server)
kubectl top nodes
```

### Gestión de Namespaces
```bash
# Listar todos los namespaces
kubectl get namespaces
kubectl get ns  # versión corta

# Crear namespace
kubectl create namespace mi-proyecto

# Crear namespace usando YAML
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: mi-proyecto
EOF

# Eliminar namespace (elimina todo lo que contiene)
kubectl delete namespace mi-proyecto

# Ver recursos en un namespace específico
kubectl get all -n mi-proyecto

# Ver recursos en todos los namespaces
kubectl get all --all-namespaces
kubectl get all -A  # versión corta
```

## 📦 Gestión de Pods

### Crear y Gestionar Pods
```bash
# Crear un pod simple con nginx
kubectl run mi-pod --image=nginx

# Crear un pod con un comando personalizado
kubectl run mi-pod --image=busybox --command -- sleep 3600

# Crear un pod en un namespace específico
kubectl run mi-pod --image=nginx -n mi-proyecto

# Ver pods
kubectl get pods
kubectl get po  # versión corta

# Ver pods con más información
kubectl get pods -o wide

# Ver pods en todos los namespaces
kubectl get pods --all-namespaces

# Eliminar un pod
kubectl delete pod mi-pod
```

### Desplegar Aplicaciones con YAML
```bash
# Aplicar manifiestos desde archivos
kubectl apply -f mi-deployment.yaml

# Aplicar todos los archivos de un directorio
kubectl apply -f ./manifiestos/

# Aplicar con dry-run (simular sin aplicar)
kubectl apply -f mi-deployment.yaml --dry-run=client

# Crear recursos y mostrar el YAML que se generaría
kubectl create deployment mi-app --image=nginx --dry-run=client -o yaml

# Aplicar desde una URL
kubectl apply -f https://ejemplo.com/manifiesto.yaml
```

## 🔍 Ver Estado de Recursos

### Comandos GET Básicos
```bash
# Ver todos los recursos en el namespace actual
kubectl get all

# Ver recursos específicos
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets
kubectl get ingress
kubectl get persistentvolumes
kubectl get persistentvolumeclaims

# Ver con más detalles
kubectl get pods -o wide
kubectl get services -o wide

# Ver en formato YAML o JSON
kubectl get pod mi-pod -o yaml
kubectl get deployment mi-deployment -o json

# Ver recursos con etiquetas
kubectl get pods --show-labels
kubectl get pods -l app=nginx  # filtrar por etiqueta

# Ordenar por edad
kubectl get pods --sort-by=.metadata.creationTimestamp
```

## 🔬 Inspeccionar Recursos

### Comando DESCRIBE (información detallada)
```bash
# Describir un pod (muy útil para debugging)
kubectl describe pod <nombre-del-pod>

# Describir otros recursos
kubectl describe deployment <nombre>
kubectl describe service <nombre>
kubectl describe ingress <nombre>
kubectl describe node <nombre-nodo>
kubectl describe namespace <nombre>

# Describir por tipo sin especificar nombre
kubectl describe pods  # describe todos los pods
kubectl describe services  # describe todos los services
```

### Obtener Logs
```bash
# Ver logs de un pod
kubectl logs <nombre-del-pod>

# Seguir logs en tiempo real
kubectl logs -f <nombre-del-pod>

# Ver logs de un contenedor específico en un pod multi-container
kubectl logs <pod-name> -c <container-name>

# Ver logs de las últimas N líneas
kubectl logs --tail=50 <nombre-del-pod>

# Ver logs desde hace X tiempo
kubectl logs --since=1h <nombre-del-pod>
kubectl logs --since=2024-01-01T10:00:00Z <nombre-del-pod>

# Ver logs de todos los pods de un deployment
kubectl logs deployment/<nombre-deployment>

# Ver logs anteriores (si el pod se reinició)
kubectl logs <nombre-del-pod> --previous
```

## 🚀 Deployments y ReplicaSets

### Crear Deployments
```bash
# Crear deployment con kubectl
kubectl create deployment mi-app --image=nginx

# Crear deployment con réplicas específicas
kubectl create deployment mi-app --image=nginx --replicas=3

# Crear deployment desde archivo YAML
kubectl apply -f mi-deployment.yaml

# Generar YAML de ejemplo
kubectl create deployment mi-app --image=nginx --dry-run=client -o yaml > mi-deployment.yaml
```

### Gestionar Deployments

### Rolling Updates y Rollbacks
```bash
# Actualizar imagen de un deployment
kubectl set image deployment/mi-app contenedor=nginx:1.20

# Reiniciar deployment (útil tras cambios en ConfigMaps/Secrets)
kubectl rollout restart deployment/mi-app

# Ver estado del rollout
kubectl rollout status deployment/mi-app

# Pausar un rollout
kubectl rollout pause deployment/mi-app

# Reanudar un rollout pausado
kubectl rollout resume deployment/mi-app

# Ver historial de rollouts
kubectl rollout history deployment/mi-app

# Ver detalles de una revisión específica
kubectl rollout history deployment/mi-app --revision=2

# Hacer rollback a la versión anterior
kubectl rollout undo deployment/mi-app

# Hacer rollback a una revisión específica
kubectl rollout undo deployment/mi-app --to-revision=2
```

### Escalar Aplicaciones
```bash
# Escalar deployment manualmente
kubectl scale deployment/mi-app --replicas=5

# Escalar múltiples deployments
kubectl scale deployment mi-app1 mi-app2 --replicas=3

# Autoescalado horizontal (HPA)
kubectl autoscale deployment mi-app --cpu-percent=50 --min=1 --max=10

# Ver el estado del HPA
kubectl get hpa

# Eliminar HPA
kubectl delete hpa mi-app
```

## 🌐 Services y Networking

### Crear Services
```bash
# Crear service ClusterIP (interno)
kubectl expose deployment mi-app --port=80 --target-port=8080

# Crear service NodePort (acceso desde nodos)
kubectl expose deployment mi-app --type=NodePort --port=80

# Crear service LoadBalancer (acceso externo)
kubectl expose deployment mi-app --type=LoadBalancer --port=80

# Crear service desde archivo YAML
kubectl apply -f mi-service.yaml

# Generar YAML de service
kubectl expose deployment mi-app --port=80 --dry-run=client -o yaml > mi-service.yaml
```

### Tipos de Services
```bash
# ClusterIP (por defecto) - solo acceso interno
kubectl create service clusterip mi-service --tcp=80:8080

# NodePort - acceso via puerto en cada nodo
kubectl create service nodeport mi-service --tcp=80:8080

# LoadBalancer - balanceador de carga externo
kubectl create service loadbalancer mi-service --tcp=80:8080

# ExternalName - mapea a nombre DNS externo
kubectl create service externalname mi-db --external-name=database.ejemplo.com
```

### Obtener información de Services
```bash
# Ver services
kubectl get services
kubectl get svc  # versión corta

# Obtener IP externa de LoadBalancer
kubectl get svc mi-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Obtener hostname de LoadBalancer
kubectl get svc mi-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Ver endpoints del service
kubectl get endpoints mi-service
```

### Port Forwarding (acceso local para testing)
```bash
# Port forward a un pod específico
kubectl port-forward pod/<nombre-del-pod> 8080:80

# Port forward a un service (recomendado)
kubectl port-forward service/mi-service 8080:80

# Port forward a deployment
kubectl port-forward deployment/mi-app 8080:80

# Port forward en background
kubectl port-forward service/mi-service 8080:80 &

# Port forward escuchando en todas las interfaces
kubectl port-forward --address 0.0.0.0 service/mi-service 8080:80

# Matar procesos de port-forward
pkill -f "kubectl port-forward"
```

## 🗂️ ConfigMaps y Secrets

### ConfigMaps
```bash
# Crear ConfigMap desde literales
kubectl create configmap mi-config --from-literal=clave1=valor1 --from-literal=clave2=valor2

# Crear ConfigMap desde archivo
kubectl create configmap mi-config --from-file=config.properties

# Crear ConfigMap desde directorio
kubectl create configmap mi-config --from-file=./config-dir/

# Ver contenido de ConfigMap
kubectl get configmap mi-config -o yaml

# Editar ConfigMap
kubectl edit configmap mi-config
```

### Secrets
```bash
# Crear Secret genérico
kubectl create secret generic mi-secret --from-literal=usuario=admin --from-literal=password=secreto

# Crear Secret desde archivos
kubectl create secret generic mi-secret --from-file=ssh-privatekey=~/.ssh/id_rsa

# Crear Secret para Docker registry
kubectl create secret docker-registry mi-registry-secret \
  --docker-server=mi-registry.com \
  --docker-username=usuario \
  --docker-password=password \
  --docker-email=email@ejemplo.com

# Ver secrets (los valores están en base64)
kubectl get secret mi-secret -o yaml

# Decodificar un valor de secret
kubectl get secret mi-secret -o jsonpath='{.data.password}' | base64 --decode
```

## 🛠️ Debugging y Troubleshooting

### Ejecutar Comandos en Pods
```bash
# Ejecutar bash en un pod interactivamente
kubectl exec -it <nombre-del-pod> -- /bin/bash

# Para pods con alpine (usan sh en lugar de bash)
kubectl exec -it <nombre-del-pod> -- /bin/sh

# Ejecutar comando específico sin interactividad
kubectl exec <nombre-del-pod> -- ls -la /app

# Ejecutar en contenedor específico (pod multi-container)
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash

# Copiar archivos desde/hacia un pod
kubectl cp <pod-name>:/ruta/archivo ./archivo-local
kubectl cp ./archivo-local <pod-name>:/ruta/destino

# Ver procesos en ejecución dentro del pod
kubectl exec <pod-name> -- ps aux

# Ver variables de entorno del pod
kubectl exec <pod-name> -- env
```

### Ver Eventos del Cluster
```bash
# Ver eventos del namespace actual
kubectl get events

# Ver eventos de un namespace específico
kubectl get events -n mi-namespace

# Ver eventos de todo el cluster
kubectl get events --all-namespaces

# Ordenar eventos por tiempo
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver eventos en tiempo real
kubectl get events --watch

# Filtrar eventos por tipo
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Normal

# Filtrar eventos por objeto
kubectl get events --field-selector involvedObject.name=mi-pod
```

### Verificar Recursos
```bash
# Ver uso de recursos por pods
kubectl top pods -n hackaton-app

# Ver uso de recursos por nodos
kubectl top nodes

# Ver límites y requests de un deployment
kubectl describe deployment frontend-app -n hackaton-app | grep -A 10 "Limits\|Requests"
```

## 🧹 Limpieza y Eliminación de Recursos

### Eliminar Recursos Específicos
```bash
# Eliminar por nombre
kubectl delete pod mi-pod
kubectl delete service mi-service
kubectl delete deployment mi-deployment

# Eliminar múltiples recursos del mismo tipo
kubectl delete pods pod1 pod2 pod3

# Eliminar usando etiquetas
kubectl delete pods -l app=mi-app
kubectl delete all -l environment=test

# Eliminar desde archivo
kubectl delete -f mi-deployment.yaml

# Eliminar todos los recursos de un tipo
kubectl delete pods --all
kubectl delete services --all
```

### Limpieza Masiva
```bash
# Eliminar todos los recursos en un namespace
kubectl delete all --all -n mi-namespace

# Eliminar namespace completo (elimina todo su contenido)
kubectl delete namespace mi-namespace

# Eliminar recursos que coincidan con un patrón
kubectl get pods | grep "test-" | awk '{print $1}' | xargs kubectl delete pod

# Forzar eliminación de pods en estado Terminating
kubectl delete pod <pod-name> --grace-period=0 --force
```

## 📊 Monitoreo y Métricas

### Uso de Recursos
```bash
# Ver uso de CPU/memoria de nodos (requiere metrics-server)
kubectl top nodes

# Ver uso de recursos de pods
kubectl top pods

# Ver uso de recursos por namespace
kubectl top pods -A

# Ver métricas de un pod específico
kubectl top pod mi-pod

# Ordenar pods por uso de CPU
kubectl top pods --sort-by=cpu

# Ordenar pods por uso de memoria
kubectl top pods --sort-by=memory
```

## � Diagnóstico y Resolución de Problemas

### Flujo de Debugging
```bash
# 1. Ver estado general de recursos
kubectl get all

# 2. Identificar recursos problemáticos
kubectl get pods | grep -v Running

# 3. Describir el recurso problemático
kubectl describe pod <pod-problemático>

# 4. Ver logs para más detalles
kubectl logs <pod-problemático>

# 5. Ver eventos relacionados
kubectl get events --field-selector involvedObject.name=<pod-problemático>

# 6. Si es necesario, reiniciar el pod
kubectl delete pod <pod-problemático>  # Se recrea automáticamente si hay deployment
```

### Problemas Comunes
```bash
# Pod en estado CrashLoopBackOff
kubectl logs <pod-name> --previous  # ver logs antes del crash
kubectl describe pod <pod-name>     # revisar eventos

# Pod en estado Pending
kubectl describe pod <pod-name>     # revisar por qué no se puede programar
kubectl get nodes                   # verificar disponibilidad de nodos

# Problemas de imagen
kubectl describe pod <pod-name>     # revisar eventos de pull de imagen

# Problemas de recursos
kubectl top nodes                   # ver uso de recursos
kubectl describe node <node-name>  # ver recursos disponibles

# Service no accesible
kubectl get endpoints <service-name>  # verificar que hay pods backend
kubectl describe service <service-name>  # revisar configuración
```

## 📚 Comandos de Aprendizaje

### Explorar el Cluster
```bash
# Ver todos los tipos de recursos disponibles
kubectl api-resources

# Ver versiones de API disponibles
kubectl api-versions

# Obtener documentación de un recurso
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers

# Generar ejemplos de YAML
kubectl create deployment ejemplo --image=nginx --dry-run=client -o yaml
kubectl create service nodeport ejemplo --tcp=80:80 --dry-run=client -o yaml

# Ver configuración actual de kubectl
kubectl config view

# Ver contextos disponibles
kubectl config get-contexts

# Cambiar de contexto
kubectl config use-context <nombre-contexto>
```

### Comandos de Información
```bash
# Ver información detallada del cluster
kubectl cluster-info dump

# Ver métricas del servidor de métricas
kubectl get --raw /metrics

# Ver estado de componentes del cluster
kubectl get componentstatuses

# Ver información de almacenamiento
kubectl get storageclass
kubectl get persistentvolumes
kubectl get persistentvolumeclaims
```

---

## 🎯 TL;DR - Comandos Esenciales

```bash
# Ver todo
kubectl get all

# Crear deployment
kubectl create deployment mi-app --image=nginx

# Exponer como service
kubectl expose deployment mi-app --port=80

# Ver logs
kubectl logs deployment/mi-app

# Ejecutar comandos en pod
kubectl exec -it <pod-name> -- /bin/bash

# Port forwarding para acceso local
kubectl port-forward service/mi-app 8080:80

# Aplicar manifiestos
kubectl apply -f mi-archivo.yaml

# Limpiar recursos
kubectl delete deployment,service mi-app
```z

## 📖 Recursos para Aprender Más

- **Documentación Oficial**: https://kubernetes.io/docs/
- **Tutoriales Interactivos**: https://kubernetes.io/docs/tutorials/
- **kubectl Cheat Sheet Oficial**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Playground en Línea**: https://labs.play-with-k8s.com/

¡Feliz aprendizaje de Kubernetes! 🚀