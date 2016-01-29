/*
This is somewhat complicated mostly because I'm testing out the capabilities
of jsonnet. It's not really neccessary to understand this.
 */
{
    local functional = import "lib/functional.jsonnet",
    local kube = self,

    v1:: {
        local v1 = self,

        ApiVersion:: { "apiVersion": "v1" },

        List(items):: v1.ApiVersion + {
            kind: "List",
            items: items,
        },
    },

    extensions:: {
        v1beta1:: {
            ApiVersion:: { "apiVersion": "extensions/v1beta1" },
        },

        DaemonSet:: kube.extensions.v1beta1.ApiVersion {
            kind: "DaemonSet"
        },

        Deployment:: kube.extensions.v1beta1.ApiVersion {
            kind: "Deployment"
        },
    },

    VolumeMounts(tab)::
        [{name: k, mountPath: tab[k], readonly: false} for k in std.objectFields(tab)],

    HostVolumes(tab)::
        [{name: k, hostPath: {path: tab[k]}} for k in std.objectFields(tab)],

    addLabels(labels)::
        function(obj)
            std.mergePatch(obj, { metadata: { labels: labels } } ),

    PodSpec(config)::
        local pod = config.pod;
        {
            hostNetwork: pod.hostNetwork,
            hostPID: pod.hostPID,
            containers:[{
                name: config.name,
                command: pod.command,
                image: "%s/%s:%s" % [ pod.repository, pod.image, pod.tag ],
                securityContext: {
                    privileged: pod.privileged,
                },
                livenessProbe:
                    if pod.httpLiveness then
                        {
                            httpGet: {
                                path: "/healthz",
                                port: pod.port,
                            },
                            initialDelaySeconds: 15,
                            timeoutSeconds: 15,
                        }
                    else
                        null,
                resources: {
                    requests: {
                         cpu: pod.resourceRequests.cpu,
                    },
                },
                volumeMounts: [{
                    name: std.join("", std.split(path, "/")),
                    mountPath: path,
                    readOnly: true,
                } for path in pod.hostVolumes ] +
                [{
                    name: name,
                    mountPath: "/srv/kubernetes",
                    readOnly: true,
                } for name in pod.secrets ],
            }],
            volumes: [{
                name: std.join("", std.split(path, "/")),
                hostPath: {path: path},
            } for path in pod.hostVolumes ] +
            [{
                name: name,
                secret: {secretName: name},
            } for name in pod.secrets ],
        },


    PodController(type, config)::
        local template =
            if type == "Deployment" then
                kube.extensions.Deployment
            else if type == "DaemonSet" then
                kube.extensions.DaemonSet
            else
                error "unkown pod controller type";
        local labels = config.labels {
            tier: config.tier,
        };
        local addLabels = kube.addLabels(labels);
        addLabels(template + {
            metadata: {
                name: config.name,
                namespace: config.namespace,
            },
            spec: {
                template: addLabels({
                    metadata: {
                        labels: {
                            version: config.pod.tag,
                        },
                    },
                    spec: kube.PodSpec(config),
                }),
            }
        }),

    Service(config):: kube.v1.ApiVersion + {
        local labels = config.labels {
            tier: config.tier,
        },
        kind: "Service",
        metadata: {
            name: config.name,
            namespace: config.namespace,
            labels: labels,
        },
        spec: {
            selector: labels,
            ports: [{
                port: config.pod.port,
                targetPort: config.pod.port,
            }],
        },
    },

    Deployment(config)::
        std.mergePatch(kube.PodController("Deployment", config), {
            spec: {
                selector:  config.labels {
                    tier: config.tier,
                },
                replicas: config.pod.replicas,
            }
        }),

    DaemonSet(config)::
        kube.PodController("DaemonSet", config) {
            spec+: {
                template+: {
                    spec+: {
                        nodeSelector: {
                            minion: "true",
                        },
                    },
                },
            },
        },

    DefaultConfig(config)::
        std.mergePatch({
            pod: {
                replicas: 3,
                repository: "gcr.io/mikedanese-k8s",
                image: config.name,
                resourceRequests: {
                    cpu: "0.1",
                },
                port: 80,
                privileged: false,
                httpLiveness: true,
                hostNetwork: false,
                hostPID: false,
                hostVolumes: [],
                secrets: [],
            }
        }, config),
}
