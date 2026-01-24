{{- define "snoty.image" -}}
{{/* per default, the image tag is the `appVersion`. however, it can be overriden by the user */}}
  {{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
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

{{- define "snoty.labels" -}}
app.kubernetes.io/name: {{ include "snoty.fullname" .context }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- with .customLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "snoty.labels.match" -}}
app.kubernetes.io/name: {{ include "snoty.fullname" .context }}
app.kubernetes.io/instance: {{ .context.Release.Name }}
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
