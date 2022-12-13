#!/bin/sh

REPO_URL="http://helm.alexstorm.solenopsys.org"
GET_URL="http://get.alexstorm.solenopsys.org" #  "http://127.0.0.1:2283"

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
        *)
            fatal "Unsupported architecture $ARCH"
    esac
}

install_k3s()
{
    echo "Start Install K3S ..."
    curl -sfL $GET_URL/k3s.sh | INSTALL_K3S_VERSION=v1.23.8+k3s1  sh -
}



install_item()
{
   echo "Install Chart ${FILE_NAME} ..."
   kubectl apply -f $GET_URL/$FILE_NAME
}

#patch_item()
#{
#   echo "Merge config ${FILE_NAME} ..."
#   echo <(curl -s http://127.0.0.1:2283/${FILE_NAME} )
#  # curl -sfL http://127.0.0.1:2283/${FILE_NAME} | kubectl \-n kube-system patch configmap coredns  --patch  -
#}

dns_path(){
    kubectl -n kube-system patch configmap coredns --patch '{ "data": {"Corefile": "\n  .:53 {\n  errors\n  health\n  ready\n  kubernetes cluster.local in-addr.arpa ip6.arpa {\n  pods insecure\n  fallthrough in-addr.arpa ip6.arpa\n}\nhosts /etc/coredns/NodeHosts {\n  ttl 60\n  reload 15s\n  10.23.92.23 helm.alexstorm.solenopsys.org\n  10.23.92.23 registry.alexstorm.solenopsys.org\n  fallthrough\n}\nprometheus :9153\nforward . /etc/resolv.conf\ncache 30\nloop\nreload\nloadbalance\n}\nimport /etc/coredns/custom/*.server"}}'
}

config(){
    echo "Start config"
    kubectl create namespace installers
    echo "Add roles"
    FILE_NAME="role-list-pods.yaml"
    install_item
    FILE_NAME="role-update-configmaps.yaml"
    install_item

    echo "Add service account"
    FILE_NAME="sa-hc-infra.yaml"
    install_item

    echo "Add rolesbindings"
    FILE_NAME="rb-hc-infra-update-configmaps.yaml"
    install_item

    FILE_NAME="rb-hc-infra-list-pods.yaml"
    install_item
}



install_chart()
{
echo "Install Chart ${CHART_NAME} ..."
cat <<EOF | kubectl apply -f -
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: ${CHART_NAME}
  namespace: installers
spec:
  set:
    arch: ${ARCH}
  chart: ${CHART_NAME}
  targetNamespace: default
  repo: ${REPO_URL}
  version: ${CHART_VERSION}
EOF
}

install_apps()
{
    CHART_NAME="alexstorm-hcf-hub"
    CHART_VERSION="0.1.8"
    install_chart

    CHART_NAME="alexstorm-hsm-router"
    CHART_VERSION="0.1.24"
    install_chart

    CHART_NAME="alexstorm-front-modules"
    CHART_VERSION="0.1.17"
    install_chart

    CHART_NAME="alexstorm-hsm-installer"
    CHART_VERSION="0.1.9"
    install_chart

    CHART_NAME="alexstorm-helm-lookup"
    CHART_VERSION="0.1.19"
    install_chart
}

install_process(){
 get_arch
 install_k3s
 config
 dns_path
 echo "Waiting system core install ..."
 sleep 30
 echo "Install solenopsys apps ..."
 install_apps
 echo "Wait for the services to start..."
 sleep 10
 watch kubectl get pods
}

install_process

