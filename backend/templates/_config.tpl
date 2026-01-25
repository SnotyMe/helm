{{- define "snoty.baseConfig" }}
{{- with $.Values.appConfig }}
environment: {{ .environment }}
{{- with $.Values.ingress }}
publicHost: {{ (or .tls.enabled (not (empty .tls.extraHosts))) | ternary "https" "http" }}://{{ .hostname }}{{ trimSuffix "/" .path }}
{{- end }}
corsHosts:
{{ range .corsHosts }}
  - {{ . | quote }}
{{ end }}
featureFlags:
  {{- toYaml .featureFlags | nindent 2 -}}
  {{ if and .featureFlags.flags (ne .featureFlags.type "InMemory") -}}
    {{ fail "Error: custom feature flag values are only supported when using the InMemory provider" }}
  {{ end }}
{{ with .database -}}
database:
  {{- if eq "mongodb" .adapter }}
  adapter: mongodb
  mongodb:
    connection:
    {{- with .mongodb.connection }}
      {{- if eq "ConnectionString" .type}}
      type: ConnectionString
      {{- if kindIs "string" .connectionString }}
      connectionString: {{ .connectionString }}
      {{ end -}}
      {{- else if eq "Split" .type }}
      type: Split
      srv: {{ .srv }}
      host: {{ .host }}
      port: {{ .port }}
      database: {{ .database }}
      {{- end }}
    {{ end -}}
  {{- else if eq "sql" .adapter }}
  adapter: sql
  sql:
  {{- with .sql }}
    {{- if kindIs "string" .jdbcUrl }}
    jdbcUrl: {{ .jdbcUrl }}
    {{- end }}
    {{- if kindIs "string" .username }}
    username: {{ .username }}
    {{- end }}
    {{- if kindIs "string" .password }}
    password: {{ .password }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- with .authentication }}
authentication:
  {{- if eq "keycloak" .adapter }}
  adapter: keycloak
  keycloak:
  {{- with .keycloak }}
    baseUrl: {{ .baseUrl }}
    realm: {{ .realm }}
    issuerUrl: '{{ .issuerUrl | default (printf "%s/realms/%s" .baseUrl .realm) }}'
    {{- if kindIs "string" .clientId }}
    clientId: {{ .clientId }}
    {{- end }}
    {{- if kindIs "string" .clientSecret }}
    clientSecret: {{ .clientSecret }}
    {{- end }}
    {{- if kindIs "map" .roleMappings }}
    roleMappings:
      {{ .roleMappings }}
    {{- end }}
  {{- end }}
  {{- else if eq "oidc" .adapter }}
  adapter: oidc
  oidc:
  {{- with .oidc }}
    issuerUrl: {{ .issuerUrl }}
    {{- $oidcUrl := .oidcUrl | default .issuerUrl -}}
    oidcUrl: {{ $oidcUrl }}
    authUrl: {{ .authUrl | default (printf "%s/auth" $oidcUrl) }}
    tokenUrl: {{ .tokenUrl | default (printf "%s/token" $oidcUrl) }}
    certUrl: {{ .certUrl | default (printf "%s/certs" $oidcUrl) }}
    userInfoUrl: {{ .userInfoUrl | default (printf "%s/userinfo" $oidcUrl) }}
    {{- if kindIs "string" .clientId }}
    clientId: {{ .clientId }}
    {{- end }}
    {{- if kindIs "string" .clientSecret }}
    clientSecret: {{ .clientSecret }}
    {{- end }}
    {{- if .rolesClaim }}
    rolesClaim: {{ .rolesClaim }}
    {{- end }}
    {{- if kindIs "map" .roleMappings }}
    roleMappings:
      {{ .roleMappings }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "snoty.config" -}}
{{- $baseConfig := include "snoty.baseConfig" . | fromYaml -}}
{{- $config := merge .Values.extraAppConfig $baseConfig -}}
{{- $config | toYaml -}}
{{- end -}}

{{- define "snoty.envLoaders" }}
{{- $cfg := .Values.appConfig }}

{{- if $cfg.jvmDebug.enabled }}
- name: JAVA_TOOL_OPTIONS
  value: '-agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend={{ $cfg.jvmDebug.suspend | ternary "y" "n" }}'
{{- end }}

{{- with $cfg.authentication.keycloak }}

{{- if kindIs "map" .clientId }}
{{ include "snoty.secretEnv" (dict "name" "authentication.keycloak.clientId" "secret" .clientId "defaultKey" "clientId") }}
{{- end }}

{{- if kindIs "map" .clientSecret }}
{{ include "snoty.secretEnv" (dict "name" "authentication.keycloak.clientSecret" "secret" .clientSecret "defaultKey" "clientSecret") }}
{{- end }}

{{- end }}

{{- with $cfg.authentication.oidc }}

{{- if kindIs "map" .clientId }}
{{ include "snoty.secretEnv" (dict "name" "authentication.oidc.clientId" "secret" .clientId "defaultKey" "clientId") }}
{{- end }}

{{- if kindIs "map" .clientSecret }}
{{ include "snoty.secretEnv" (dict "name" "authentication.oidc.clientSecret" "secret" .clientSecret "defaultKey" "clientSecret") }}
{{- end }}

{{- end }}

{{- with $cfg.database.mongodb }}
{{- if and (kindIs "map" .connection) (eq .connection.type "ConnectionString") (kindIs "map" .connection.connectionString) }}
{{ include "snoty.secretEnv" (dict "name" "database.mongodb.connection.connectionString" "secret" .connection.connectionString "defaultKey" "connectionString") }}
{{- end }}
{{- end }}

{{- with $cfg.database.sql }}

{{- if kindIs "map" .jdbcUrl }}
{{ include "snoty.secretEnv" (dict "name" "database.sql.jdbcUrl" "secret" .jdbcUrl "defaultKey" "jdbcUrl") }}
{{- end }}

{{- if kindIs "map" .username }}
{{ include "snoty.secretEnv" (dict "name" "database.sql.username" "secret" .username "defaultKey" "username") }}
{{- end }}

{{- if kindIs "map" .password }}
{{ include "snoty.secretEnv" (dict "name" "database.sql.password" "secret" .password "defaultKey" "password") }}
{{- end }}

{{- end }}

{{- end -}}

{{- define "snoty.secretEnv" -}}
- name: {{ .name }}
  valueFrom:
    secretKeyRef:
      name: {{ .secret.secretName }}
      key: {{ default .defaultKey .secret.secretKey }}
{{- end -}}
