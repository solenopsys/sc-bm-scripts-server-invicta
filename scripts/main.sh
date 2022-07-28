#!/bin/sh

REPO_URL=https://helm.alexstorm.solenopsys.org


get_arch() {
    CUR_ARCH=$(uname -m)
    case $CUR_ARCH in
        amd64)
            ARCH=amd64
            SUFFIX=
            ;;
        x86_64)
            ARCH=amd64
            SUFFIX=
            ;;
        arm64)
            ARCH=arm64
            SUFFIX=-${ARCH}
            ;;
        aarch64)
            ARCH=arm64
            SUFFIX=-${ARCH}
            ;;
        arm*)
            ARCH=arm
            SUFFIX=-${ARCH}hf
            ;;
        *)
            fatal "Unsupported architecture $ARCH"
    esac
}


install_k3s()
{
  echo "Start Install K3S ..."
  curl -sfL https://get.k3s.io | sh -
}

install_chart()
{
   echo "Install Chart ${CHART_NAME} ..."
cat <<EOF | kubectl apply -f -
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ${CHART_NAME}
  namespace: kube-system
spec:
  set:
    arch: ${ARCH}
  chart: ${CHART_NAME}
  targetNamespace: default
  repo: ${REPO_URL}
  version: ${CHART_VERSION}
EOF
}

get_arch
#install_k3s
CHART_NAME="hs-router"
CHART_VERSION="0.1.3"
install_chart

echo "Admin access by url ${CHART_NAME} ..."