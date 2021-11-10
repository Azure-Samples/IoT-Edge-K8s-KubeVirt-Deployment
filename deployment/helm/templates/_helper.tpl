{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "aziotedgevm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aziotedgevm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "aziotedgevm.labels" -}}
{{/*helm.sh/chart: {{ include "aziotedgevm.chart" . }}*/}}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Create the cloud-init config for vm.
*/}}
{{- define "aziotedgevm.cloudinit" -}}
#cloud-config
hostname: iotedgevm
ssh_authorized_keys:
  - {{ .Values.publicSshKey }}
apt:
  sources:
    microsoft-prod.list:
      source: "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/ubuntu/18.04/multiarch/prod bionic main"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1.4.7 (GNU/Linux)

        mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT
        LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV
        7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag
        OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j
        H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr
        M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs
        ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC
        AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH
        /32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe
        MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy
        7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV
        KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ
        XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+
        NdCFTW7wY0Fb1fWJ+/KTsC4=
        =J6gs
        -----END PGP PUBLIC KEY BLOCK-----

bootcmd:
# mount the Secret
  - "mkdir /mnt/app-secret"
  - "mount /dev/$(lsblk --nodeps -no name,serial | grep D23YZ9W6WA5DJ487 | cut -f1 -d' ') /mnt/app-secret"

# Once VM is started following command will install Moby Engine, IoT Edge and configure config.toml content from K8s secret.
# There's a possibility to achieve the below package deployment via packages cloud-init construct instead but they don't run in order.
runcmd:
  - sudo apt-get update
  - sudo apt-get install -y moby-engine
  - sudo apt-get update
  - sudo apt-get install -y aziot-edge
  - sudo cp /mnt/app-secret/userdata /etc/aziot/config.toml
  {{- if .Values.rootCA }}
  - sudo cp /mnt/app-secret/rootca /usr/local/share/ca-certificates/{{ .Values.rootCAName }}.crt
  - sudo update-ca-certificates
  - sudo systemctl restart docker
  - sudo mkdir -p /etc/aziot/certificates
  - sudo cp /mnt/app-secret/rootca /etc/aziot/certificates/{{ .Values.rootCAName }}
  {{- end }}
  {{- if .Values.deviceCACert }}
  - sudo cp /mnt/app-secret/devicecert /etc/aziot/certificates/{{ .Values.deviceCACertName }}
  {{- end }}
  {{- if .Values.deviceCAKey }}
  - sudo cp /mnt/app-secret/devicekey /etc/aziot/certificates/{{ .Values.deviceCAKeyName }}
  {{- end }}
  - sudo iotedge config apply
{{- end -}}
