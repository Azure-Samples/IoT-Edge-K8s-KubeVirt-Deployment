# KVEdge

This repo demonstrates a deployment of IoT Edge in Kubernetes (K8s) using [KubeVirt](http://kubevirt.io/) which an open source CNCF project.

## Prerequisites

[KubeVirt](https://kubevirt.io/user-guide/operations/installation/) and its [CDI (Containezed Data Importer)](https://github.com/kubevirt/containerized-data-importer) add-on must be installed on the K8s cluster. CDI is required to mount the data volume which includes VM disk (e.g. Ubuntu VM disk)

## Deploying IoT Edge VM

IoT Edge VM can be deployed to the K8s cluster which has KubeVirt infrastructure/services deployed on it as a prerequisite.

### Local Helm Deployment

Use this deployment option if you've cloned this repo locally and trying it out.

1. Clone repo locally on your Linux or WSL machine.
2. Change working directory to kvedge/deployment/helm
3. Run `helm install aziot-edge-kubevirt . --set publicSshKey=<insert your public ssh key to access VM>`

Following artifacts are created in K8s cluster when the above helm chart is deployed:

1. KubeVirt data volume which contains a vm disk with ubuntu 18.04 LTS installed on it.
2. KubeVirt VM instance which makes use of the above data volume.
3. K8s service with external load balancer and public IP to access the VM from remote clients with private ssh key.
4. K8s secret containing cloud-init [startup config](https://kubevirt.io/user-guide/virtual_machines/startup_scripts/#startup-scripts) to configure public SSH key on the VM.

## IoT Edge Aspect

1. EdgeHub Persistence: IoT Edge's EdgeHub messaging component saves messages on a disk, if this disk is ephemeral, messages will be lost if VM is restarted. Data Volume in KubeVirt allows you to persiste this data on a PVC under the hoods, preventing data loss for messages. [Review Needed]
2. 

## Azure Arc

Azure Arc allows you to manage K8s cluster via Azure management plane, there are two ways by which you can deploy workloads to Arc managed K8s cluster:

1. [GitOps](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-connected-cluster): allows you to deploy workloads in automated CI/CD manner.
2. [Cluster Connect](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/cluster-connect): Gives you access to the API Server of K8s, enabling you to run standard Kubectl/Helm commands from client terminal.

[Enabling Arc support for K8s](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/overview) is optional and it does not impact how IoT Edge runtime is hosted in a KubeVirt VM.

## Commercial Support

KubeVirt is commercially supported on RedHat/OpenShift platform if this is a requirement. As IoT Edge runs on a VM with supported OS e.g. Ubuntu 18.0 LTS, in theory, this solution should also be a supported by IoT Edge team at Microsoft.

TODO:
1. Create Ubuntu img with IoT Edge deployed on it.
2. Attach img to disk in Kubevirt container image.
3. Create Helm chart to:
    1. Create secret/configmap to store edge device conn string + potentially ssh public key of user if required.
    2. Deploy VM with prebuilt docker image container from top level step 1.
4. Optionally, create arc connected K8s and deploy KV/Edge VM remotely.
5. CDI plugin is probably not required if you are using precreated image based on kubevirt.