# Развертывание и автоматизация веб-приложения в Kubernetes с CI/CD

## 1. Описание проекта

Цель проекта — развернуть веб-приложение на Next.js в Kubernetes-кластере с полной автоматизацией CI/CD и системой мониторинга.

## 2. Стек технологий

- **Контейнеризация**: Docker
- **Оркестрация**: Kubernetes (Minikube)
- **CI/CD**: GitHub Actions
- **Мониторинг**: Prometheus + Grafana + Loki + Promtail

---

## 3. Kubernetes-манифесты

### `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextjs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nextjs
  template:
    metadata:
      labels:
        app: nextjs
    spec:
      containers:
      - name: nextjs
        image: denisvorop/nextjs-k8s-demo:latest
        ports:
        - containerPort: 3000
```

### `service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nextjs-service
spec:
  selector:
    app: nextjs
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: NodePort
```

---

## 4. GitHub Actions workflow

### `.github/workflows/deploy.yaml`
```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - master
  pull_request:
    branches:
      - master

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Cache Docker layers
        uses: actions/cache@v2
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-

      - name: Build Docker image
        run: |
          docker build -t my-app:${{ github.sha }} .

      - name: Log in to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push Docker image
        run: |
          docker push my-app:${{ github.sha }}

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Kubernetes
        uses: azure/setup-kubectl@v1
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}

      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
          kubectl set image deployment/my-app my-app=my-app:${{ github.sha }}
```

---

## 5. Секрет KUBECONFIG

### Пример содержимого `KUBECONFIG` (Minikube):
```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /Users/user/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Tue, 08 Apr 2025 17:29:23 MSK
        provider: minikube.sigs.k8s.io
        version: v1.35.0
      name: cluster_info
    server: https://127.0.0.1:53953
  name: minikube
contexts:
- context:
    cluster: minikube
    extensions:
    - extension:
        last-update: Tue, 08 Apr 2025 17:29:23 MSK
        provider: minikube.sigs.k8s.io
        version: v1.35.0
      name: context_info
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /Users/user/.minikube/profiles/minikube/client.crt
    client-key: /Users/user/.minikube/profiles/minikube/client.key
```

⚠️ Необходимо сохранить содержимое этого файла как GitHub Secret с именем `KUBECONFIG`.

---

## 6. Мониторинг и визуализация

### Установленные компоненты:
- Prometheus
- Grafana
- Loki
- Promtail

### Метрики:
- Нагрузка CPU и памяти
- Количество запросов к приложению
- Логи от приложения через Loki

### Визуализация в Grafana:
- Источник данных Prometheus: `http://prometheus-server.monitoring.svc.cluster.local`
- Источник данных Loki: `http://loki.monitoring.svc.cluster.local:3100`

### Дашборд с тремя графиками:
- **HTTP-запросы:**
  ```promql
  rate(http_requests_total[5m])
  ```
- **Нагрузка на CPU:**
  ```promql
  100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
  ```
- **Использование памяти:**
  ```promql
  100 - ((node_memory_MemAvailable_bytes{job="node"} / node_memory_MemTotal_bytes{job="node"}) * 100)
  ```

---

## 7. Нагрузочное тестирование

Для симуляции запросов и генерации нагрузки можно использовать:

```bash
watch -n 0.5 curl http://localhost:<NodePort>
```

Либо утилиту `hey`:
```bash
hey -z 60s -q 10 http://localhost:<NodePort>
```
