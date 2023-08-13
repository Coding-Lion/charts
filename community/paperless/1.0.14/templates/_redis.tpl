{{- define "redis.workload" -}}
workload:
  broker:
    enabled: true
    type: Deployment
    podSpec:
      containers:
        broker:
          enabled: true
          primary: true
          image: docker.io/library/redis:7