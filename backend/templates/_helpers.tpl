{{/*
Return the proper image name
*/}}
{{- define "snoty.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) -}}
{{- end -}}
