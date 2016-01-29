local k8s = import "lib/kube.jsonnet";
local env = import "env.json";

local config = k8s.DefaultConfig({
  name: "kubelet-%s" % env.kubeletTag,
  namespace: "kube-system",
  tier:"node",
  labels : {
    component: "kubelet",
  },
  pod: {
    command: [
        "nsenter",
        "--target=1",
        "--mount",
        "--wd=.",
        "--",
        "./kubelet",
        "--api-servers=https://k-1-master",
        "--enable-debugging-handlers=true",
        "--cloud-provider=gce",
        "--config=/etc/kubernetes/manifests",
        "--allow-privileged=True",
        "--v=2",
        "--cluster-dns=10.0.0.10",
        "--cluster-domain=cluster.local",
        "--cgroup-root=/",
        "--system-container=/system"
    ],
    image: "kubelet",
    tag: env.kubeletTag,
    privileged: true,
    httpLiveness: false,
    hostPID: true,
    hostNetwork: true,
    port: 10250,
  }
});

{
    "kubelet.ds.json": k8s.DaemonSet(config),
}
