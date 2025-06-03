{{- define "snoty.baseConfig" -}}
    {{- with $.Values.appConfig }}
    environment: {{ .environment }}
    corsHosts:
      {{ range .corsHosts }}
        - {{ . | quote }}
      {{ end }}
    featureFlags:
      {{- toYaml .featureFlags | nindent 12 -}}
      {{- if and .featureFlags.flags (ne .featureFlags.type "InMemory") -}}
        {{- fail "Error: custom feature flag values are only supported when using the InMemory provider" -}}
      {{- end -}}
    {{- end }}
    {{- with $.Values.ingress }}
    publicHost: {{ (or .tls.enabled (not (empty .tls.extraHosts))) | ternary "https" "http" }}://{{ .hostname }}{{ trimSuffix "/" .path }}
    {{- end }}
    # if `appConfig.mongodb` is set, it overrides the config from `mongodb`.
    {{- if and $.Values.mongodb.deploy (not (kindIs "map" $.Values.appConfig.mongodb)) }}
    database:
      type: mongodb
    {{- with $.Values.mongodb }}
    {{- if .auth.existingSecret }}
    mongodb:
      connection:
        type: Split
        srv: {{ eq .architecture "replicaset" }}
        host: {{ .service.nameOverride }}.{{ $.Release.Namespace }}.svc.{{ $.Values.clusterDomain }}
        port: {{ .service.ports.mongodb }}
        database: {{ index .auth.databases 0 }}
        additionalOptions: tls={{ .tls.enabled }}&ssl={{ .tls.enabled }}
      authentication:
        username: {{ index .auth.usernames 0 }}
        authDatabase: {{ index .auth.databases 0 }}
        # password is loaded from existingSecret
    {{- else }}
      connection:
        # does not support architecture=replicaset, prefer using externalSecret
        type: ConnectionString
        connectionString: mongodb://{{ index .auth.usernames 0 }}:{{ index .auth.passwords 0 }}@{{ $.Release.Name }}-mongodb/{{ index .auth.databases 0 }}
    {{- end }}
    {{- end }}
    {{- else }}
      {{- with $.Values.appConfig.mongodb }}
      {{- if kindIs "string" .connectionString }}
      connectionString: {{ .connectionString }}
      {{- end }}
      {{- end }}
    {{- end }}
    authentication:
    {{- if $.Values.keycloak.deploy }}
      {{- with $.Values.keycloak }}
      serverUrl: {{ ternary "https" "http" .ingress.tls }}://{{ .ingress.hostname }}/{{ trimPrefix "/" (($.Values.appConfig.authentication).path | default .ingress.path) }}
      clientId: {{ $.Values.appConfig.authentication.clientId }}
      clientSecret: {{ $.Values.appConfig.authentication.clientSecret }}
      {{- end }}
    {{- else }}
      {{- with $.Values.appConfig.authentication }}
      {{- if kindIs "string" .serverUrl }}
      serverUrl: {{ .serverUrl }}/{{ trimPrefix "/" (.path | default "") }}
      {{- end }}
      {{- if kindIs "string" .issuerUrl }}
      issuerUrl: {{ .issuerUrl }}{{ trimSuffix "/" (.path | default "") }}
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
- name: JAVA_TOOL_OPTIONS
  value: >
    {{ if .Values.appConfig.jvmDebug.enabled -}}
    '-agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend={{ .Values.appConfig.jvmDebug.suspend | ternary "y" "n" }}'
    {{ end }}

{{ if and (.Values.mongodb.deploy) (kindIs "map" .Values.mongodb.auth) }}
{{- with .Values.mongodb.auth -}}
{{- if .existingSecret -}}
- name: mongodb.authentication.password
  valueFrom:
    secretKeyRef:
      name: {{ .existingSecret }}
      key: {{ .secretKey | default "mongodb-passwords" }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- with $.Values.appConfig -}}
{{- with .authentication -}}
{{- if kindIs "map" .clientId }}
- name: authentication.clientId
  valueFrom:
    secretKeyRef:
      name: {{ .clientId.secretName }}
      key: {{ .clientId.secretKey | default "clientId" }}
{{- end -}}
{{- if kindIs "map" .clientSecret }}
- name: authentication.clientSecret
  valueFrom:
    secretKeyRef:
      name: {{ .clientSecret.secretName }}
      key: {{ .clientSecret.secretKey | default "clientSecret" }}
{{- end -}}
{{- end -}}
{{- if kindIs "map" .sql }}
- name: database.type
  value: sql
{{- with .sql -}}
{{- if kindIs "map" .username }}
- name: sql.username
  valueFrom:
    secretKeyRef:
      name: {{ .username.secretName }}
      key: {{ .username.secretKey | default "username" }}
{{- end -}}
{{- if kindIs "map" .password }}
- name: sql.password
  valueFrom:
    secretKeyRef:
      name: {{ .password.secretName }}
      key: {{ .password.secretKey | default "password" }}
{{- end -}}
{{- if kindIs "map" .jdbcUrl }}
- name: sql.jdbcUrl
  valueFrom:
    secretKeyRef:
      name: {{ .jdbcUrl.secretName }}
      key: {{ .jdbcUrl.secretKey | default "jdbcUrl" }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
