{{/*
Ensures that grpc.host is configured when iamDataAccessService is enabled
*/}}
{{- define "gitlab.checkConfig.iamDataAccessService.grpc.host" -}}
  {{- with .Values.global.appConfig.iamDataAccessService -}}
    {{- if .enabled -}}
      {{- if not (dig "grpc" "host" "" .) }}
iamDataAccessService:
    grpc.host is required when iamDataAccessService is enabled. Please set `global.appConfig.iamDataAccessService.grpc.host`.
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.iamDataAccessService.grpc.host */}}

{{/*
Ensures that grpc.port is configured when iamDataAccessService is enabled
*/}}
{{- define "gitlab.checkConfig.iamDataAccessService.grpc.port" -}}
  {{- with .Values.global.appConfig.iamDataAccessService -}}
    {{- if .enabled -}}
      {{- if not (dig "grpc" "port" 0 .) }}
iamDataAccessService:
    grpc.port is required when iamDataAccessService is enabled. Please set `global.appConfig.iamDataAccessService.grpc.port`.
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.iamDataAccessService.grpc.port */}}
