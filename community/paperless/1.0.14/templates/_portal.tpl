{{- define "gitea.portal" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: portal
data:
  path: /
  port: {{ .Values.paperlessNetwork.webPort | quote }}
  {{ if or (hasPrefix "https://" .Values.paperlessNetwork.rootURL) .Values.paperlessNetwork.certificateID }}
  protocol: https
  {{ else }}
  protocol: http
  {{ end }}
  {{- $host := "$node_ip" -}}
  {{ with .Values.paperlessNetwork.rootURL }} {{/* Trim protocol and trailing slash */}}
    {{ $host = (. | trimPrefix "https://" | trimPrefix "http://" | trimSuffix "/") }}
    {{ $host = mustRegexReplaceAll "(.*):[0-9]+" $host "${1}" }}
  {{ end }}
  host: {{ $host }}
{{- end -}}
