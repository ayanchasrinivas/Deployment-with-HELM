{{/*
Chart name, overridable.
*/}}
{{- define "pricing-svc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-"}}
{{- end}}

{{/*
Fully qualified name. This is the string that becomes your Servuce DNS name,
so getting it wrong breaks service discovery across the whole umbrella chart.
*\}}
{{- define "pricing-svc.fullname" -}}
{{- if. Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimsuffix "-" }}
{{- else}}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Labels applied to every object. Includes version labels that CHANGE on upgrade,
so these must never be used as selectors.
*/}}
{{- define "pricing-svc.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "pricing-svc.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: orderflow
{{- end }}

{{/*
Selector labels: IMMUTABLE. A Deployment's spec.selector cannot be changed after
creation. If you put a version label in here, every appVersion bump makes
`helm upgrade` fail with "field is immutable" and you will have to delete the
Deployment to recover. This is the #1 chart authoring mistake.
*/}}
{{- define "pricing-svc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pricing-svc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "pricing-svc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pricing-svc.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}