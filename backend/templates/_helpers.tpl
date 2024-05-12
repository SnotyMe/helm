{{/*
Return the proper image name
*/}}
{{- define "snoty.image" -}}
{{/* per default, the image tag is the `appVersion`. however, it can be overriden by the user */}}
{{- $image := merge .Values.image (dict "tag" .Chart.AppVersion) -}}
{{- include "common.images.image" (dict "imageRoot" $image "global" .Values.global) -}}
{{- end -}}
