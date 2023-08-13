{{- define "gitea.configuration" -}}

  {{ if not (hasPrefix "http" .Values.paperlessNetwork.rootURL) }}
    {{ fail "Gitea - Expected [Root URL] to have the following format [http(s)://(sub).domain.tld(:port)] or [http://IP_ADDRESS:port]" }}
  {{ end }}

  {{- $fullname := (include "ix.v1.common.lib.chart.names.fullname" $) -}}

  {{- $dbHost := (printf "%s-postgres" $fullname) -}}

  {{- $dbPass := (randAlphaNum 32) -}}
  {{- with (lookup "v1" "Secret" .Release.Namespace (printf "%s-postgres-creds" $fullname)) -}}
    {{- $dbPass = ((index .data "POSTGRES_PASSWORD") | b64dec) -}}
  {{- end -}}

  {{ $dbURL := (printf "postgres://%s:%s@%s:5432/%s?sslmode=disable" $dbUser $dbPass $dbHost $dbName) }}
secret:
  postgres-creds:
    enabled: true
    data:
      POSTGRES_USER: paperless
      POSTGRES_DB: paperless
      POSTGRES_PASSWORD: paperless
      POSTGRES_HOST: {{ $dbHost }}
      POSTGRES_URL: {{ $dbURL }}

  gitea-creds:
    enabled: true
    data:
      PAPERLESS_DBHOST: {{ $dbHost }}
configmap:
  gitea-config:
    enabled: true
    data:
      PAPERLESS_REDIS: redis://broker:6379
      

{{ with .Values.paperlessNetwork.certificateID }}
scaleCertificate:
  gitea-cert:
    enabled: true
    id: {{ . }}
{{ end }}

{{- end -}}
