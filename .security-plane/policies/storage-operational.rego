package main

# Policy: A StorageClass must not claim to be the cluster default
# platform/ manifests describe additional storage options; the cluster's
# own default (e.g. local-path on k3s, a cloud provisioner on managed
# clusters) should decide what "default" means, not a platform manifest.
# Confirmed live (mac-mini-k3s, #2018): marking azure-disk-premium default
# here created two "(default)" StorageClasses at once, and a PVC without
# an explicit storageClassName silently bound to whichever one Kubernetes
# picked - in that case an Azure CSI class with no working driver on that
# cluster, leaving the PVC stuck Pending.
deny[msg] {
    input.kind == "StorageClass"
    input.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true"

    msg := sprintf("StorageClass '%s' must not set storageclass.kubernetes.io/is-default-class: \"true\" - platform manifests should not claim the cluster default", [input.metadata.name])
}
