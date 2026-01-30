{{- define "snoty.version" -}}
{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{- define "snoty.image" -}}
{{/* per default, the image tag is the `appVersion`. however, it can be overriden by the user */}}
  {{- $tag := include "snoty.version" . -}}
  {{- $digestSuffix := "" -}}
  {{- if and .Values.image.digest (ne .Values.image.digest "") -}}
    {{- $digestSuffix = printf "@%s" .Values.image.digest -}}
  {{- end -}}
  {{ printf "%s/%s:%s%s" .Values.image.registry .Values.image.repository $tag $digestSuffix }}
{{- end }}

{{- define "snoty.fullname" }}
  {{- if .Values.fullnameOverride }}
      {{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- $releaseName := lower .Release.Name }}

    {{- if contains $name $releaseName }}
      {{- $releaseName | trunc 63 | trimSuffix "-" -}}
    {{- else }}
      {{- printf "%s-%s" $releaseName $name | trunc 63 | trimSuffix "-" -}}
    {{- end }}
  {{- end }}
{{- end }}

{{/* TODO: incorporate `snoty-` into chart name */}}
{{- define "snoty.labels.match" -}}
app.kubernetes.io/name: snoty-{{ .context.Chart.Name }}
app.kubernetes.io/instance: {{ include "snoty.fullname" .context }}
{{- with .customLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "snoty.labels" -}}
{{ include "snoty.labels.match" (dict "customLabels" .customLabels "context" .context) }}
app.kubernetes.io/version: {{ include "snoty.version" .context }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .context.Chart.Name .context.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- with .customLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "snoty.tpl" }}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
    {{- tpl $value .context }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end }}
