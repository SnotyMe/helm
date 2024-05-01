{{- define "snoty.baseConfig" -}}
    {{- with $.Values.ingress }}
    publicHost: {{ ternary "https" "http" .tls }}://{{ .hostname }}{{ .path }}
    {{- end }}
    {{- with $.Values.postgresql }}
    {{- if .deploy }}
    database:
      username: {{ .auth.username }}
      password: {{ .auth.password }}
      jdbcUrl: jdbc:postgresql://{{ $.Release.Name }}-postgresql:{{ .primary.service.ports.postgresql | default 5432 }}/{{ .auth.database }}
    {{- end }}
    {{- end }}
    {{- with $.Values.keycloak }}
    {{- if .deploy }}
    authentication:
      serverUrl: {{ ternary "https" "http" .ingress.tls }}://{{ .ingress.hostname }}/{{ trimPrefix "/" ($.Values.appConfig.authentication.path | default .ingress.path) }}
    {{- end }}
    {{- end }}
{{- end }}

{{- define "snoty.config" -}}
    {{- $baseConfig := include "snoty.baseConfig" . | fromYaml }}
    {{- $config := merge .Values.appConfig $baseConfig }}
    {{- $config | toYaml }}
{{- end }}
