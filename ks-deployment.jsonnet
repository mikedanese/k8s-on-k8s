local k8s = import "lib/kube.jsonnet";
local env = import "env.json";

local config = k8s.DefaultConfig({
  name: "kube-scheduler",
  namespace: "kube-system",
  tier: "control-plane",
  labels : {
    component: "scheduler",
  },
  pod: {
    command: [
        "/usr/local/bin/kube-scheduler",
        "--address=0.0.0.0",
        "--v=2",
        "--leader-elect"
    ],
    image: "kube-scheduler",
    tag: env.kubeSchedulerTag,
    port: 10251,
  }
});

{
    "scheduler.svc.json": k8s.Service(config),
    "scheduler.deployment.json": k8s.Deployment(config),
}
