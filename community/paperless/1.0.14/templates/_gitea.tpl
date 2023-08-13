{{- define "gitea.workload" -}}
workload:
  gitea:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.paperlessNetwork.hostNetwork }}
      containers:
        gitea:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.paperlessRunAs.user }}
            runAsGroup: {{ .Values.paperlessRunAs.group }}
          envFrom:
            - secretRef:
                name: gitea-creds
            - configMapRef:
                name: gitea-config
          {{ with .Values.paperlessConfig.additionalEnvs }}
          envList:
            {{ range $env := . }}
            - name: {{ $env.name }}
              value: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            {{ $protocol := "http" }}
            {{ if .Values.paperlessNetwork.certificateID }}
              {{ $protocol = "https" }}
            {{ end }}
            liveness:
              enabled: true
              type: {{ $protocol }}
              path: /api/healthz
              port: {{ .Values.paperlessNetwork.webPort }}
            readiness:
              enabled: true
              type: {{ $protocol }}
              path: /api/healthz
              port: {{ .Values.paperlessNetwork.webPort }}
            startup:
              enabled: true
              type: {{ $protocol }}
              path: /api/healthz
              port: {{ .Values.paperlessNetwork.webPort }}
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "containerName" "01-permissions"
                                                        "UID" .Values.paperlessRunAs.user
                                                        "GID" .Values.paperlessRunAs.group
                                                        "type" "install") | nindent 8 }}
      {{- include "ix.v1.common.app.postgresWait" (dict "name" "postgres-wait"
                                                        "secretName" "postgres-creds") | nindent 8 }}
{{/* Service */}}
service:
  gitea:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: gitea
    ports:
      webui:
        enabled: true
        primary: true
        port: {{ .Values.paperlessNetwork.webPort }}
        nodePort: {{ .Values.paperlessNetwork.webPort }}
        targetSelector: gitea

{{/* Persistence */}}
persistence:
  data:
    enabled: true
    type: {{ .Values.paperlessStorage.data.type }}
    datasetName: {{ .Values.paperlessStorage.data.datasetName | default "" }}
    hostPath: {{ .Values.paperlessStorage.data.hostPath | default "" }}
    targetSelector:
      gitea:
        gitea:
          mountPath: /usr/src/paperless/data
        01-permissions:
          mountPath: /mnt/directories/data
  media:
    enabled: true
    type: {{ .Values.paperlessStorage.media.type }}
    datasetName: {{ .Values.paperlessStorage.media.datasetName | default "" }}
    hostPath: {{ .Values.paperlessStorage.media.hostPath | default "" }}
    targetSelector:
      gitea:
        gitea:
          mountPath: /usr/src/paperless/media
        01-permissions:
          mountPath: /mnt/directories/media
  export:
    enabled: true
    type: {{ .Values.paperlessStorage.export.type }}
    datasetName: {{ .Values.paperlessStorage.export.datasetName | default "" }}
    hostPath: {{ .Values.paperlessStorage.export.hostPath | default "" }}
    targetSelector:
      gitea:
        gitea:
          mountPath: /usr/src/paperless/export
        01-permissions:
          mountPath: /mnt/directories/export
  consume:
    enabled: true
    type: {{ .Values.paperlessStorage.consume.type }}
    datasetName: {{ .Values.paperlessStorage.consume.datasetName | default "" }}
    hostPath: {{ .Values.paperlessStorage.consume.hostPath | default "" }}
    targetSelector:
      gitea:
        gitea:
          mountPath: /usr/src/paperless/consume
        01-permissions:
          mountPath: /mnt/directories/consume
  gitea-temp:
    enabled: true
    type: emptyDir
    targetSelector:
      gitea:
        gitea:
          mountPath: /tmp/gitea
  {{ if .Values.paperlessNetwork.certificateID }}
  cert:
    enabled: true
    type: secret
    objectName: gitea-cert
    defaultMode: "0600"
    items:
      - key: tls.key
        path: private.key
      - key: tls.crt
        path: public.crt
    targetSelector:
      gitea:
        gitea:
          mountPath: /etc/certs/gitea
          readOnly: true
  {{ end }}
{{- end -}}
