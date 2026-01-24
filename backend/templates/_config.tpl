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
    {{ toYaml .featureFlags | nindent 12 }}
    {{ if and .featureFlags.flags (ne .featureFlags.type "InMemory") -}}
      {{ fail "Error: custom feature flag values are only supported when using the InMemory provider" }}
    {{ end -}}
  {{- end }}

  {{ with .database -}}
  database:
    {{- if eq "mongodb" .type }}
    type: mongodb
    mongodb:
      connection:
      {{- with .mongodb.connection }}
        {{- if eq "ConnectionString" .type}}
        type: ConnectionString
        {{- if kindOf "string" .connectionString }}
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
    {{- else if eq "sql" .type }}
    type: sql
    sql:
    {{- with .sql }}
      {{- if kindOf "string" .jdbcUrl }}
      jdbcUrl: {{ .jdbcUrl }}
      {{- end }}
      {{- if kindOf "string" .username }}
      username: {{ .username }}
      {{- end }}
      {{- if kindOf "string" .password }}
      password: {{ .password }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- with .authentication }}
  authentication:
    {{- if eq "keycloak" .type }}
    type: keycloak
    keycloak:
    {{- with .keycloak }}
      baseUrl: {{ .baseUrl }}
      realm: {{ .realm }}
      clientId: {{ .clientId }}
      {{- if kindOf "string" .clientSecret }}
      clientSecret: {{ .clientSecret }}
      {{- end }}
      roleMappings:
        {{ .roleMappings }}
    {{- end }}
    {{- else if eq "oidc" .type }}
    type: oidc
    oidc:
    {{- with .oidc }}
      issuerUrl: {{ .issuerUrl }}
      {{- $oidcUrl := .oidcUrl | default .issuerUrl -}}
      oidcUrl: {{ $oidcUrl }}
      authUrl: {{ .authUrl | default (printf "%s/auth" $oidcUrl) }}
      tokenUrl: {{ .tokenUrl | default (printf "%s/token" $oidcUrl) }}
      certUrl: {{ .certUrl | default (printf "%s/certs" $oidcUrl) }}
      userInfoUrl: {{ .userInfoUrl | default (printf "%s/userinfo" $oidcUrl) }}
      clientId: {{ .clientId }}
      {{- if kindOf "string" .clientSecret }}
      clientSecret: {{ .clientSecret }}
      {{- end }}
      {{- if .rolesClaim }}
      rolesClaim: {{ .rolesClaim }}
      {{- end }}
      roleMappings:
        {{ .roleMappings }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "snoty.config" }}
  # TODO: add fromYaml
  {{- $baseConfig := include "snoty.baseConfig" . }}
{{/*
  {{- $config := merge .Values.extraAppConfig $baseConfig }}
*/}}
  # TODO: add toYaml
  {{ $baseConfig }}
  {{ .Values.extraAppConfig }}
{{- end }}

{{- define "snoty.envLoaders" }}
  - name: JAVA_TOOL_OPTIONS
    value:
      {{- if .Values.appConfig.jvmDebug.enabled -}}
      '-agentlib:jdwp=transport=dt_socket,server=y,address=8000,suspend={{ .Values.appConfig.jvmDebug.suspend | ternary "y" "n" }}'
      {{- end }}

  {{ with $.Values.appConfig -}}
    {{- with .authentication -}}
      {{- if kindIs "map" .clientId -}}
      - name: authentication.clientId
        valueFrom:
          secretKeyRef:
            name: {{ .clientId.secretName }}
            key: {{ .clientId.secretKey | default "clientId" }}
      {{- end -}}
      {{- if kindIs "map" .clientSecret -}}
      - name: authentication.clientSecret
        valueFrom:
          secretKeyRef:
            name: {{ .clientSecret.secretName }}
            key: {{ .clientSecret.secretKey | default "clientSecret" }}
      {{- end -}}
    {{- end -}}

    {{ with .database -}}
      {{- if kindIs "map" .mongodb -}}
      {{- with .mongodb -}}
        {{- if kindIs "map" .connection -}}
        {{ with .connection -}}
          {{- if eq "ConnectionString" .type -}}
            {{- if kindIs "map" .connectionString -}}
            - name: database.mongodb.connection.connectionString
              valueFrom:
                secretKeyRef:
                  name: {{ .connectionString.secretName }}
                  key: {{ .connectionString.secretKey | default "connectionString" }}
            {{- end -}}
          {{- end -}}
        {{- end -}}
        {{- end -}}
      {{- end -}}
      {{- end -}}

      {{- if kindIs "map" .sql -}}
      {{- with .sql -}}
        {{- if kindIs "map" .jdbcUrl }}
        - name: database.sql.jdbcUrl
          valueFrom:
            secretKeyRef:
              name: {{ .jdbcUrl.secretName }}
              key: {{ .jdbcUrl.secretKey | default "jdbcUrl" }}
        {{ end -}}
        {{- if kindIs "map" .username }}
        - name: database.sql.username
          valueFrom:
            secretKeyRef:
              name: {{ .username.secretName }}
              key: {{ .username.secretKey | default "username" }}
        {{ end -}}
        {{- if kindIs "map" .password }}
        - name: database.sql.password
          valueFrom:
            secretKeyRef:
              name: {{ .password.secretName }}
              key: {{ .password.secretKey | default "password" }}
        {{ end -}}
      {{ end -}}
      {{ end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
