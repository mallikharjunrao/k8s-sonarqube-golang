# SonarQube with Postgres Database on Kubernetes for GoLang Advanced Settings
###### Documentation By: Dennis Christilaw (https://github.com/Talderon)

## Table of Contents (MarkDown Files)

* [SonarQube Setup](../README.md)
* [Local Environment Setup](../golang-sonar-scanner.md)
* [Advanced Configurations](README.md)

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

```yaml
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

## Creating a PV-Claim with NFS

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sqpv-devops
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Gi
```

Just make sure everything matches what is in the PV file

* Name
* AccessMode
* Storage

## Postgres Deployment with NFS

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: sq-db-devops
spec:
  replicas: 1
  template:
    metadata:
      name: sq-db-devops
      labels:
        name: sq-db-devops
    spec:
      containers:
        - image: postgres:latest
          name: sq-db-devops
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-pwd-devops
                  key: password
            - name: POSTGRES_USER
              value: sonar
          ports:
            - containerPort: 5432
              name: postgresport
          volumeMounts:
            # This name must match the volumes.name below.
            - name: sqdb-data-devops
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: sqdb-data-devops
          persistentVolumeClaim:
            claimName: sqpv-claim-devops
```

From here, everything below VolumeMounts is where you will put the information for your PV-Claim.

## SonarQube Deployment with NFS for Plugins Directory

### Coming soon. I am still finalizing this Manifest File for consumption

SonarQube Server Mount Point: /opt/sonarqube/extensions/plugins/

## SonarQube Ingress with DNS name

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: sq-ingress-devops
  namespace: devops-staging
  labels:
    app: SonarQube-devops
  annotations:
    kubernetes.io/ingress.class: tectonic
spec:
  rules:
  - host: sonarqube.devops.kube.example.com
    http:
      paths:
      - backend:
          serviceName: sq-svc-devops
          servicePort: 80
        path: /sonar
status:
  loadBalancer:
    ingress:
      - ip: 192.168.180.53
      - ip: 192.168.180.56
      - ip: 192.168.180.57
      - ip: 192.168.22.215
      - ip: 192.168.23.55
```

```yaml
  annotations:
    kubernetes.io/ingress.class: tectonic
```

This is only needed if your cluster management environment requires it (again, k8s Admins). In the case of this example, I am using Tectonic.

For this Ingress, I have chosen the DNS Entry: sonarqube.devops.kube.example.com - Be sure to speak with your k8s admin to make sure you have the access to create these.

```yaml
      - backend:
          serviceName: sq-svc-devops
          servicePort: 80
        path: /sonar
```

This section here is VERY important. During the deployment, you should have create a service for both the Database and SonarQube Web Server. Your sonar-service defaults to port 80 and will map to port 9000 for the web app. The NodePort is NOT USED in this instance.

When you attempt to access the service, you will use: http://sonarqube.devops.kube.example.com (no port numbers or anything else is needed). The Ingress will handle all of the port translations for you.

```yaml
status:
  loadBalancer:
    ingress:
      - ip: 192.168.180.53
      - ip: 192.168.180.56
      - ip: 192.168.180.57
      - ip: 192.168.22.215
      - ip: 192.168.23.55
```

You will need to get this informaiton from the admins of your k8s environment.