{{/*
Expand the name of the chart.
*/}}
{{- define "universal-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "universal-chart.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "universal-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "universal-chart.labels" -}}
helm.sh/chart-version: {{ include "universal-chart.chart" . }}
{{ include "universal-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: abc #TODO: update value here
{{- end }}

{{/*
Selector labels
*/}}
{{- define "universal-chart.selectorLabels" -}}
app.kubernetes.io/app-name: {{ .Values.applicationName }}
app.kubernetes.io/bu-name: {{ .Values.buName }}
app.kubernetes.io/team-name: {{ .Values.teamName }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "universal-chart.serviceAccountName" -}}
sa-{{ .Values.teamName }} # Share sa between app in the same team
{{- end }}
