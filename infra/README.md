To collect logs from applications in a Kubernetes (k8s) cluster using Fluentd and send them to a Kubernetes volume, you can follow a structured approach. Fluentd is typically used to forward logs to destinations like Elasticsearch, but with some configuration, it can be used to store logs on a Kubernetes volume instead.

### Prerequisites

1. **Kubernetes Cluster:** Ensure you have a Kubernetes cluster up and running.
2. **Fluentd:** Install Fluentd as a DaemonSet in your Kubernetes cluster to collect logs from all nodes.

### Steps to Collect Logs and Store Them on a Kubernetes Volume

1. **Create a PersistentVolume (PV) and PersistentVolumeClaim (PVC):**
   - First, create a PersistentVolume to provide storage, and a PersistentVolumeClaim that Fluentd will use to write logs.

   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: fluentd-pv
   spec:
     capacity:
       storage: 10Gi
     accessModes:
       - ReadWriteOnce
     persistentVolumeReclaimPolicy: Retain
     storageClassName: manual
     hostPath:
       path: "/mnt/fluentd"
   ---
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: fluentd-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 10Gi
     storageClassName: manual
   ```

   - Apply this configuration to your Kubernetes cluster:

   ```bash
   kubectl apply -f pv-pvc.yaml
   ```

2. **Deploy Fluentd as a DaemonSet:**
   - Create a Fluentd DaemonSet that mounts the PVC to store logs. Below is an example configuration.

   ```yaml
   apiVersion: apps/v1
   kind: DaemonSet
   metadata:
     name: fluentd
     labels:
       k8s-app: fluentd-logging
   spec:
     selector:
       matchLabels:
         name: fluentd
     template:
       metadata:
         labels:
           name: fluentd
       spec:
         containers:
         - name: fluentd
           image: fluent/fluentd:v1.12-debian-1
           env:
             - name: FLUENTD_ARGS
               value: "--no-supervisor -q"
           volumeMounts:
             - name: config-volume
               mountPath: /fluentd/etc
             - name: log-volume
               mountPath: /fluentd/log
             - name: storage-volume
               mountPath: /fluentd/data
         volumes:
           - name: config-volume
             configMap:
               name: fluentd-config
           - name: log-volume
             emptyDir: {}
           - name: storage-volume
             persistentVolumeClaim:
               claimName: fluentd-pvc
   ```

   - This DaemonSet mounts the `fluentd-pvc` to `/fluentd/data`, where logs will be stored.

3. **Configure Fluentd to Write Logs to the Mounted Volume:**
   - You need to create a ConfigMap that contains the Fluentd configuration. This configuration will specify that logs should be written to the mounted volume.

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: fluentd-config
   data:
     fluent.conf: |
       <source>
         @type tail
         path /var/log/containers/*.log
         pos_file /fluentd/log/fluentd.pos
         tag kube.*
         <parse>
           @type json
         </parse>
       </source>

       <match kube.**>
         @type file
         path /fluentd/data/k8s_logs
         <buffer>
           @type file
           path /fluentd/data/buffer
           flush_interval 10s
           flush_at_shutdown true
         </buffer>
       </match>
   ```

   - Apply the ConfigMap to your cluster:

   ```bash
   kubectl apply -f fluentd-configmap.yaml
   ```

4. **Deploy the Fluentd DaemonSet:**

   - Apply the DaemonSet configuration:

   ```bash
   kubectl apply -f fluentd-daemonset.yaml
   ```

5. **Verify the Setup:**
   - Ensure that the Fluentd DaemonSet is running on all nodes:

   ```bash
   kubectl get daemonsets -n kube-system
   ```

   - Check the logs directory in the mounted volume to verify that logs are being collected and stored:

   ```bash
   kubectl exec -it <fluentd-pod-name> -- ls /fluentd/data/k8s_logs
   ```

### Summary

This setup ensures that logs from all applications running in your Kubernetes cluster are collected by Fluentd and stored on a PersistentVolume. By leveraging Kubernetes volumes, you can manage and retain logs in a more controlled and accessible manner, similar to how logs would be sent to Elasticsearch, but stored locally or on network-attached storage.