local k8s = import "lib/kube.jsonnet";
local env = import "env.json";

local config = k8s.DefaultConfig({
  name: "kube-controller-manager",
  namespace: "kube-system",
  tier: "control-plane",
  labels : {
    component: "controller-manager",
  },
  pod: {
    command: [
        "/usr/local/bin/kube-controller-manager",
        "--address=0.0.0.0",
        "--cluster-name=k-1",
        "--cluster-cidr=10.244.0.0/16",
        "--allocate-node-cidrs=true",
        "--cloud-provider=gce",
        "--service-account-private-key-file=/srv/kubernetes/server-key",
        "--root-ca-file=/srv/kubernetes/root-ca-file",
        "--leader-elect",
        "--v=2",
    ],
    image: "kube-controller-manager",
    tag: env.kubeControllerManagerTag,
    port: 10252,
    hostVolumes: [
        "/etc/ssl",
        "/usr/share/ssl",
        "/var/ssl",
        "/usr/ssl",
        "/usr/lib/ssl",
        "/usr/local/openssl",
        "/etc/openssl",
        "/etc/pki/tls"
    ],
    secrets: [
        "cm-secrets",
    ],
  }
});

{
    "controller-manager.svc.json": k8s.Service(config),
    "controller-manager.deployment.json": k8s.Deployment(config),
}
