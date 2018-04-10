# SonarQube with Postgres Database on Kubernetes for GoLang Advanced Settings
###### Documentation By: Dennis Christilaw (https://github.com/Talderon)

## Purpose
The purpose of this document is to address some common questions and issues that you can face when getting this all set up with more complex environment variables and functions.

Such as (but no limited too):

1. Using an NFS Share for the Database Files
2. Using an NFS Share for SonarQube Plugin Storage
3. Ingress with DNS entry
4. Creating a PersistantVolume with NFS Share
5. Creating a PersistantVolumeClaim with NFS PV

More will be added as they are needed, discovered or asked for.

## Creating a PV with NFS

```
ApiVersion: v1
kind: PersistentVolume
metadata:
  name: sqpv-devops
  annotations:
    volume.beta.kubernetes.io/mount-options: "nfsvers=3"
spec:
  capacity:
    storage: 500Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: nfs.example.com
    path: /mnt/Tier3/kube-store/devops/sonarqube
```

What you see above in a simple manifest file to create a PV on an NFS Share.

* The Annotation is really important and you will need to get this information from the NSF Share Admin
* Access Mode - ReadWriteMany - This is set this way as in the future there is a plan to have a Postgres Cluster
  * Important! A volume can only be mounted using one access mode at a time, even if it supports many.
  * The access modes are:
    * ReadWriteOnce – the volume can be mounted as read-write by a single node
    * ReadOnlyMany – the volume can be mounted read-only by many nodes
    * ReadWriteMany – the volume can be mounted as read-write by many nodes
* Reclamation Policy:
  * Current reclaim policies are:
    * Retain – manual reclamation
    * Recycle – basic scrub (rm -rf /thevolume/*)
    * Delete – associated storage asset such as AWS EBS, GCE PD, Azure Disk, or OpenStack Cinder volume is deleted
    * Currently, only NFS and HostPath support recycling. AWS EBS, GCE PD, Azure Disk, and Cinder volumes support deletion.
* nfs: Server and Share Path

These are the basics needed.