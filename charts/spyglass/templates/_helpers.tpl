{{/*
Common labels applied to every object.
*/}}
{{- define "spyglass.labels" -}}
app.kubernetes.io/name: spyglass
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app: spyglass
{{- end -}}

{{/*
Pod selector labels (stable across upgrades — never include version here).
*/}}
{{- define "spyglass.selectorLabels" -}}
app: spyglass
{{- end -}}

{{/*
Fully-qualified image reference. image.tag defaults to the chart appVersion so
the deployed version is pinned (never floats to :latest).
*/}}
{{- define "spyglass.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}

{{/*
Name of the chart-managed Secret that holds AUTH_TOKEN and/or LICENSE_KEY.
*/}}
{{- define "spyglass.secretName" -}}
spyglass-secrets
{{- end -}}
