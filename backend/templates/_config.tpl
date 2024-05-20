{{- define "snoty.baseConfig" -}}
    {{- with $.Values.appConfig }}
    environment: {{ .environment }}
    {{- end }}
    {{- with $.Values.ingress }}
    publicHost: {{ ternary "https" "http" .tls }}://{{ .hostname }}{{ .path }}
    {{- end }}
    database:
    # if `appConfig.database` is set, it overrides the config from `postgresql`.
    {{- if and $.Values.postgresql.deploy (not (kindIs "map" $.Values.appConfig.database)) }}
      {{- with $.Values.postgresql }}
      username: {{ .auth.username }}
      password: {{ .auth.password }}
      jdbcUrl: jdbc:postgresql://{{ $.Release.Name }}-postgresql:{{ .primary.service.ports.postgresql | default 5432 }}/{{ .auth.database }}
      {{- end }}
    {{- else }}
      {{- with $.Values.appConfig.database }}
      {{- if kindIs "string" .username }}
      username: {{ .username }}
      {{- end }}
      {{- if kindIs "string" .password }}
      password: {{ .password }}
      {{- end }}
      {{- if kindIs "string" .jdbcUrl }}
      jdbcUrl: {{ .jdbcUrl }}
      {{- end }}
      {{- end }}
    {{- end }}
    authentication:
    {{- if $.Values.keycloak.deploy }}
      {{- with $.Values.keycloak }}
      serverUrl: {{ ternary "https" "http" .ingress.tls }}://{{ .ingress.hostname }}/{{ trimPrefix "/" ($.Values.appConfig.authentication.path | default .ingress.path) }}
      clientId: {{ $.Values.appConfig.authentication.clientId }}
      clientSecret: {{ $.Values.appConfig.authentication.clientSecret }}
      {{- end }}
    {{- else }}
      {{- with $.Values.appConfig.authentication }}
      {{- if kindIs "string" .serverUrl }}
      serverUrl: {{ .serverUrl }}/{{ trimPrefix "/" (.path | default "") }}
      {{- end }}
      {{- if kindIs "string" .clientId }}
      clientId: {{ .clientId }}
      {{- end }}
      {{- if kindIs "string" .clientSecret }}
      clientSecret: {{ .clientSecret }}
      {{- end }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "snoty.config" -}}
    {{- $baseConfig := include "snoty.baseConfig" . | fromYaml }}
    {{- $config := merge .Values.extraAppConfig $baseConfig }}
    {{- $config | toYaml }}
{{- end }}

{{- define "snoty.envLoaders" -}}
{{- with $.Values.appConfig }}
  {{ if kindIs "map" .database }}
  {{- with .database }}
  {{ if kindIs "map" .password }}
  {{- with .password -}}
  - name: database.password
    valueFrom:
      secretKeyRef:
        name: {{ .secretName }}
        key: {{ .secretKey | default "password" }}
  {{- end -}}
  {{- end -}}
  {{ if kindIs "map" .jdbcUrl }}
  {{- with .jdbcUrl -}}
  - name: database.jdbcUrl
    valueFrom:
      secretKeyRef:
        name: {{ .secretName }}
        key: {{ .secretKey | default "jdbcUrl" }}
  {{- end -}}
  {{- end -}}
  {{- end -}}
  {{- end -}}
  {{- with .authentication -}}
  {{ if kindIs "map" .clientId }}
  - name: authentication.clientId
    valueFrom:
      secretKeyRef:
        name: {{ .clientId.secretName }}
        key: {{ .clientId.secretKey | default "clientId" }}
  {{- end -}}
  {{ if kindIs "map" .clientSecret }}
  - name: authentication.clientSecret
    valueFrom:
      secretKeyRef:
        name: {{ .clientSecret.secretName }}
        key: {{ .clientSecret.secretKey | default "clientSecret" }}
  {{- end -}}
  {{- end -}}
{{- end -}}
{{- end -}}
