### 현재 구조 

blockchain-gitops
└─ docker-compose/
    └─ observer/
└─k8s/
    ├─ observer/
    │   ├─ deployment.yaml
    │   ├─ service.yaml
    │   └─ configmap.yaml
    ├─ bitcoind/
    │   ├─ statefulset.yaml
    │   ├─ service.yaml
    │   └─ secret.yaml
    ├─ prometheus/
    │   ├─ deployment.yaml
    │   ├─ service.yaml
    │   └─ configmap.yaml
    ├─ alertmanager/
    │   ├─ deployment.yaml
    │   ├─ service.yaml
    │   └─ configmap.yaml
    └─ grafana/
        ├─ deployment.yaml
        └─ service.yaml