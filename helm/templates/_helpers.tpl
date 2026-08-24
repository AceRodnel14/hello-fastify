{{- define "hello-fastify.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "hello-fastify.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hello-fastify.labels" -}}
app.kubernetes.io/name: {{ include "hello-fastify.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "hello-fastify.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hello-fastify.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hello-fastify.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "hello-fastify.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
