{{/* Common labels for AduaNext umbrella chart resources. */}}
{{- define "aduanext.labels" -}}
app.kubernetes.io/name: aduanext
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "aduanext.serverSelectorLabels" -}}
app.kubernetes.io/name: aduanext-server
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "aduanext.webSelectorLabels" -}}
app.kubernetes.io/name: aduanext-web
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
