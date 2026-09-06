{{/*
Chart name, overridable.
*/}}
{{- define "order-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified name. This is the string that becomes your Service DNS name,
so getting it wrong breaks service discovery across the whole umbrella chart.
*/}}
{{- define "order-api.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
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
{{- define "order-api.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "order-api.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: orderflow
{{- end }}

{{/*
Selector labels: IMMUTABLE. A Deployment's spec.selector cannot be changed after
creation. Never add version or other mutable fields here.
*/}}
{{- define "order-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "order-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "order-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "order-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the pricing service URL.
Precedence: explicit .Values.pricing.url > umbrella-installed sibling service.
Note the use of .Release.Name — under the umbrella chart, the sibling service is
named "<release>-pricing-svc", not just "pricing-svc".
*/}}
{{- define "order-api.pricingUrl" -}}
{{- if .Values.pricing.url -}}
{{- .Values.pricing.url -}}
{{- else -}}
{{- printf "http://%s-%s.%s.svc.cluster.local:%v" .Release.Name .Values.pricing.serviceName .Release.Namespace (.Values.pricing.port | int) -}}
{{- end -}}
{{- end }}