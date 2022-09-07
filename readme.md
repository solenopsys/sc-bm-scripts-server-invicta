ssh  -R 2283:127.0.0.1:83 alexstorm@192.168.88.28
ssh  -R 2283:127.0.0.1:83 alexstorm@192.168.88.29
ssh  -R 2283:127.0.0.1:83 alexstorm@192.168.88.30


curl -sfL http://127.0.0.1:2283/main.sh | sh -


kubectl -n kube-system rollout restart deployment coredns


/usr/local/bin/k3s-uninstall.sh