### 현재 구조 

blockchain-gitops
└─ docker-compose/ <- 안씀
└─ jenkins/ 
│   ├─ jenkins-ngrok-ingress.yaml
│   └─ jenkins-ui-ingress.yaml
└─ k8s/
│    └─ monitoring-ingress.yaml
│    └─ monitoring/
│        ├─ observer/
│        │   ├─ deployment.yaml
│        │   ├─ service.yaml
│        │   ├─ configmap.yaml
│        │   └─ servicemonitor.yaml
│        ├─ bitcoind/
│        │   ├─ statefulset.yaml
│        │   ├─ service.yaml
│        │   ├─ networkpolicy.yaml
│        │   └─ secret.yaml
│        ├─ prometheus/
│        │   ├─ deployment.yaml
│        │   ├─ prometheus-rule.yaml
│        │   ├─ service.yaml
│        │   └─ configmap.yaml
│        ├─ alertmanager/
│        │   ├─ deployment.yaml
│        │   ├─ service.yaml
│        │   └─ configmap.yaml
│        └─ grafana/
│            ├─ pvc.yaml
│            ├─ deployment.yaml
│            └─ service.yaml
└─ Jenkinsfile


### operator(개편중) 구조
blockchain-gitops
├─ apps/
│   └─ observer/
│     ├─ cmd/
│     │  └─ observer/
│     │     └─ main.go                 
│     ├─ internal/
│     │  ├─ chain/
│     │  │  ├─ bitcoin_rpc.go          # CheckBitcoinRPC (RPC만)
│     │  │  └─ external_checks.go      # CheckExternalBitcoinAPI 
│     │  ├─ config/
│     │  │  └─ config.go
│     │  ├─ metrics/
│     │  │  └─ prometheus.go           # ExternalBlockHeight, BitcoinPriceUSD 등
│     │  ├─ external/
│     │  │  └─ blockstream.go          # 외부 블록높이 fetch 
│     │  └─ price/
│     │     └─ coingecko.go            # 시세 fetch (USD + WON)
│     ├─ Dockerfile
│     ├─ go.mod
│     └─ go.sum
|    
├─ infra/
|   ├─ jenkins/
|   |   ├─ ingress-ui.yaml
|   |   └─ ingress-ngrok.yaml
|   |   
|   └─ k8s/
|       ├─kustomization.yaml                 
|       ├─namespaces/
|       |  ├─monitoring.yaml
|       |  ├─kustomization.yaml
|       |  └─jenkins.yaml
|       |
|       ├─apps/
|       |  ├─ observer/
|       |  |    ├─ deployment.yaml
|       |  |    ├─ service.yaml
|       |  |    ├─ configmap.yaml                 # 앱 env
|       |  |    ├─ servicemonitor.yaml            # 스크랩(Operator 방식)
|       |  |    └─ kustomization.yaml
|       |  └─ bitcoind/
|       |       ├─ statefulset.yaml
|       |       ├─ service.yaml
|       |       ├─ secret.yaml
|       |       ├─ networkpolicy.yaml
|       |       └─ kustomization.yaml
|       |
|       ├─ monitoring/                              # “정책/대시보드/공용”
|       |       ├─ rules/
|       |       |    ├─ observer-rules.yaml         # PrometheusRule (RPC down/latency)
|       |       |    └─ kustomization.yaml
|       |       ├─ dashboards/
|       |       |    ├─ observer-dashboard.json
|       |       |    └─ kustomization.yaml
|       |       └─ kustomization.yaml
|       |        
|       └─ ingress/
|              ├─ monitoring-ingress.yaml
|              └─ kustomization.yaml
|   
├─legacy/ # 필요없어진 파일들 모음 
|   ├─ docker-compose/
|   └─ monitoring/
├─ README.md
└─ Jenkinsfile

apps/ = 실제 서비스(관측 대상) 
monitoring/ = “알람/대시보드/정책”
ingress/ = 외부 노출
kustomization.yaml 로 apply 한 방