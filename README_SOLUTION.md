# Web-App-DevOps-Project

For an introduction to the Web App DevOps Project and initial starter instructions see the README_TASK file, in this directory.
The Web App (app.py, static/script.js, static/style.css, and templates/orders.html) was provided by AiCore. Project objective, is to deploy the Web App.
A deployment path was mapped in stages: GitHub version control, Docker containerisation, Terraform IaC, Kubernetes container orchestration, Azure CI/CD pipelines,  YAML configuration files.
We will consider each stage in detail.

## Table of Content:
 - [GitHub version control](#github-version-control)
 - [Docker containerisation](#docker-containerisation)
 - [Terraform IaC](#terraform-iac)
 - [Kubernetes container orchestration](#kubernetes-container-orchestration)
 - [Azure CI/CD pipelines](#azure-cicd-pipelines)
 - [AKS Cluster Monitoring](#aks-cluster-monitoring)
 - [Secret Management](#secret-management)
 - [Troubleshooting](#troubleshooting)
 - [Contributors](#contributors)
 - [License](#license)

## GitHub version control <a name="github-version-control"></a>
The application files can be found on the [GitHub repository](https://github.com/maya-a-iuga/Web-App-DevOps-Project).
The repository was forked, and then cloned to a local repository. The repository was branched to add features and pushed back to the remote repository and merged to main. Main was subsequently pulled, and branched again, as features and files were added. 
At one point, it was decided to remove a new feature To do this, the main was pulled and branched again. The new branch was rolled back, pushed to the remote repository and remerged into main.
Through this regiem of continuous incremental updates, a working copy of the code was maintained at all times, and merge conflicts were avoided.

### Key Commands
<pre>
 - git clone ~URI-of-repository~
 - git checkout -b ~name-of-new-branch~
 - git branch
 - git add . or git add ~name-of-file(s)-to-be-added~
 - git commit -m "text of meaning full comment"
 - git push -u origin ~name-of-branch~
 - git pull  </pre>

### Containerisation
A docker file was added to the repository, to define the image build and the container run.
___
## Docker containerisation <a name="docker-containerisation"></a>
The Dockerfile contains all commands (in sequence), needed to build a given image into a container. It also specifies how the application, described by the image, will start.
Dockerfiles adheres to a specific format and instruction set. See: [Dockerfile reference](https://docs.docker.com/engine/reference/builder/).

### Dockerfile:
<pre>
FROM python:3.8-slim

# Step 2 - Set the working directory in the container
WORKDIR /app

# Step 3 Copy the application files in the container
COPY . .

# Install system dependencies and ODBC driver
RUN apt-get update && apt-get install -y \
    unixodbc unixodbc-dev odbcinst odbcinst1debian2 libpq-dev gcc && \
    apt-get install -y gnupg && \
    apt-get install -y wget && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    wget -qO- https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get purge -y --auto-remove wget && \  
    apt-get clean

# Install pip and setuptools
RUN pip install --upgrade pip setuptools

# Step 4 - Install Python packages specified in requirements.txt
# RUN pip install -r requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Step 5 - Expose port 
EXPOSE 5000

# Step 6 - Define Startup Command
# ENTRYPOINT ["python", "app.py"]
CMD ["python", "app.py"]
# CMD ["flask", "run"]
</pre>

### Build:

docker build -t ~image-name~ .

docker images

### Run:

docker run -d -p 30030:5000 ~image-name~

### Manage:

docker ps
docker ps -a
docker rm ~container-id~

docker images -a

docker rmi ~image-id~
___

## Terraform IaC <a name="terraform-iac"></a>
We need a virtual infrastructure, on which to deploy our application. Terraform is employed to create and manage that infrastructure (as code). 

Terraform employes modular configuration files to enhance readability and promote code reuse. The structure of our files is shown below:

Web-App-DevOps-TerraformFile <br>
├── main.tf <br>
├── variables.tf <br>
├── networking-module/ <br>
&emsp;&emsp;├── main.tf <br>
&emsp;&emsp;├── variables.tf <br>
&emsp;&emsp;└── outputs.tf <br>
├── aks-cluster-module/ <br>
&emsp;&emsp;├── main.tf <br>
&emsp;&emsp;├── variables.tf <br>
&emsp;&emsp;└── outputs.tf <br>
└── .gitignore <br>

NOTE: The gitignore file (.gitignore) is not part of the Terraform configuration file structure. However, it is of critical importance, at this point. So, is included for completeness.

### Ititialise the Terraform workspace
Having created a preliminary file structure, the next action is to run [terraform init](https://developer.hashicorp.com/terraform/cli/commands/init). The terraform init command sets up the backend, downloads the necessary provider plugins, and initializes the state of the Terraform configuration. In doing so, it initialises a Terraform working directory (.terraform), and a number of working files. Some of the files in this directory are large, and cannot be pushed to the GitHub repository. The Terraform working directory/files should be included in the .gitignore file before attempting to push configuration files to GitHub. Include in .gitignore: *.terraform/ , *.terraform, *.tfstate

### Modules
The networking-module and the aks-cluster-module describe generic attributes of those resources. The parameters specified as input variables specify our specific instance.

#### The networking module

The networking-module declares networking resources to be provisioned for the AKS cluster.

| Resource  | Resource Type | Instance Identifier |
| ------------- | ------------- | -------------|
| Resource group  | "azurerm_resource_group"  |  "networking" |
| Virtual network  | "azurerm_virtual_network" | "aks_vnet" |
| Subnet | "azurerm_subnet" | "control_plane_subnet" |
| Subnet | "azurerm_subnet" | "worker_node_subnet" |
| NSG | "azurerm_network_security_group" | "aks_nsg" |
| NGS rule | "azurerm_network_security_rule" | "kube_apiserver" |
| NGS rule | "azurerm_network_security_rule" | "ssh" |


#### Defined inputs:

"resource_group_name"  Azure Resource Group where the networking resources will be deployed in.

"location"  Azure region where the networking resources will be deployed to.

"vnet_address_space"  The address space for the Virtual Network (VNet).

#### The aks cluster module

The aks-cluster-module declares the AKS cluster resource “azurerm_kubernetes_cluster", with the identifier "aks_cluster".
Within this resource we declare the parameters (passed in as input variables):

| Variable Name  | Function/Description |
| ------------- | ------------- |
| "aks_cluster_name" | Variable that represents the name of the AKS cluster |
| "cluster_location" | Azure region where the AKS cluster will be deployed |
| "dns_prefix" | DNS prefix of the AKS cluster |
| "kubernetes_version" | Kubernetes version used by the AKS cluster |
| "service_principal_client_id" | Service principle appId |
| "service_principal_secret" | Service principle password |

The service principle allows secure connection to the cluster.
These variables are taken as output from the networking-module, when it is instantiated:

| Variable Name  | Function/Description |
| ------------- | ------------- |
| "resource_group_name" | AZ Resource Group where resource will be deployed |
| "vnet_id" | Vnet on which to run the AKS cluster |
| "control_plane_subnet_id" | Subnet for the control plane |
| "worker_node_subnet_id" | Subnet for the worker nodes |
| "aks_nsg_id" | NSG for the AKS cluster Vnet |

The main.tf file (at the root of the Terraform-Project directory):
 1.	Specifies the required provider interface.
 2.	Specifies credential to identify the target subscription and communicate with Azure Resource Manager (azurerm), across the interface.
 3.	Instantiates the networking resource.
 4.	Instantiates the aks-cluster resources.

The main.tf file accepts arguments (as input variables) directly, from variables files, and output files as appropriate.

### Hiding access credentials
To hide sensative access credentials (like the provider client id and client secret), we have employed system (Windows 10) [environmental variables](https://developer.hashicorp.com/terraform/cli/config/environment-variables). This is one technique available to [manage secrets in Terraform](https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-1d586955ace1).

Our development environment is running on Windows 10. So, [Windows environmental variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.4) were declared as TF_VAR_variablename (i.e., TF_VAR_client_id). 

Variables for the sensative access credentials are declared and used as normal. They are declared 'sensative', with no default value. Terraform aquires the environmental key:value objects from the underlying OS. 


### terraform apply
These Terraform CLI commands are used to deploy and manage our [IaC:](https://developer.hashicorp.com/terraform/cli/commands)
 - terraform plan:&ensp;Displays a list of resources that will be created, updated or deleted when the configuration is applied.
 - terraform apply:&ensp;Applies the changes to the infrastructure described in the Terraform configuration file. It creates, updates, or deletes resources based on the configuration changes.
 - terraform destroy:&ensp;Destroys all the resources created by the Terraform configuration. It removes all traces of the infrastructure created by the Terraform configuration.

 Having applied the IaC, use the [Kubernetes CLI](https://kubernetes.io/docs/reference/kubectl/) (kubectl) to review the deployment.


## Kubernetes container orchestration <a name="kubernetes-container-orchestration"></a>
With IaC in place we can now deploy our service (application). This is done through an application manifest file (application-manifest.yaml).

### Application manifest
<pre>
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app-deployment
  labels:
    app: myflaskapp
spec:                    # spec: Desired state of deployment
  replicas: 2            # Support two containers
  selector:
    matchLabels:
      app: flask-app     # Identify containers by tags: app: flask-app
  template:              # Template for creating containers
    metadata:
      labels:
        app: flask-app   # Tag containers with app: flask-app
    spec:                # spec: Desired state of container
      containers:
      - name: flask-app
        image: paulmayer2731/web-app-devops-project:latest       # Container iage from Docker Hub repo
# One or more containers do not have resource limits - this could starve other processes
        resources:
          limits:        # Resource no to exceed
            memory: 512Mi
            cpu: "1"
          requests:      # Minimum resource request
            memory: 256Mi
            cpu: "0.2"
# Resource limits applied to remove linting warning
        ports:
        - containerPort: 5000  # Application within container exposed on tis port
  strategy:
    type: RollingUpdate        # Rolling update maintains service during update.
    rollingUpdate:             # Thus, reducing down-time for stateless applications.
      maxSurge: 1              # Max one additional container during deployment update
      maxUnavailable: 1        # Max one terminating container during deployment update
---
# Network service to allow inter cluster communication by directing traffic to pods
apiVersion: v1
kind: Service
metadata:
  name: flask-app-service
spec:
  selector:
    app: flask-app          # Maintaining seamless communication within the AKS cluster
  ports:                    # That is, all pods tagged flask-app.
    - protocol: TCP
      port: 80              # flask-app-service:80 is directed to container:5000
      targetPort: 5000      # Port on which application is running inside the container
  type: LoadBalancer        # ClusterIP  # Internal service within the AKS cluster
  </pre>

### Deploy App
<pre>
Deploy with:
  $ kubectl apply -f application-manifest.yaml
Check deployment with:
  $ kubectl get namespaces
  $ kubectl get deployments -n ~namespace-name~
  $ kubectl get services -n ~namespace-name~
  $ kubectl get pods-n ~namespace-name~<br>
Port forward to check service via web browser:
  $ kubectl port-forward deployment/flask-app-deployment 8086:5000
Brows to http://localhost:8086  http://127.0.0.1:8086
Test service: review order list, add new order.
</pre>

### Inside the pod
<pre>
Access the pod to use bash and curl:
$ kubectl exec -it <pod-name> -n <namespace> -- bash
/app# apt-get update && apt-get install -y curl
/app# curl localhost:5000

Exit pod, exit terminal:
/app# exit
$ exit
</pre>

### External access:
Three service type options offer different levels of access:
 - Cluster IP: Exposes the service on an internal IP in the cluster (default service).
 - NodePort: Superset of ClusterIP. Exposes the service on the same port of each selected node in the cluster. 
 - LoadBalancer: Superset of NodePort.  Creates an external load balancer in the current cloud and assigns an external IP to the service.</a><br>
 To simplify deployment testing, we have implemented LoadBalancer as the service type.<br>

 To allow global, limitless access, we could provision:
 - Globaly unique domain names, for use on the internet.
 - An Azure application-gateway. The app gateway configures as a Web Application Firewall.
 - An ingress controller (resource defined in .yaml file, to anchor domain names).
 - A modified NSG to allow ingress from a range of authorised users.


## Azure CI/CD pipelines <a name="azure-cicd-pipelines"></a>
Azure DevOps was employed to facilitate continuous integration (CI) of code and continuous deployment (CD) of service. Thus, a CI/CD pipeline was created. 

### CI (Build)
The pipeline would:
 - Automatically pull updated code from GitHub.
 - Build a new container image, according to the Dockerfile.
 - Push the new image to DockerHub.

 On initial set up, the build pipeline was authenticated to GitHub. Thus, allowing the pipeline to pull code from the remote repository. A service connection was made to DockerHub, enabling push and pull of images.

### CD (Deploy)
The pipeline would:
 - Automatically pull the new image from DockerHub.
 - Deploy the image to the AKS IaC, per the application manifest file (application-manifest.yaml).
</a><br>

The DockerHub service connection allowed the pipeline to pull the new container image from the container registry. A service connection was also created to AKS, allowing service deployment.

The Build (CI) and Deploy (CD) were integrated into a single CI/CD pipeline, described in a YAML file (azure-pipelines.yaml).<br>
To simplify testing, I added a task to the end of the YAML file. The task would display the external IP address of the deployed service.


### CI/CD YAML file
YAML file describing the CI/CD pipeline:
<pre>
# CI/CD Pipeline
# Author: pmayer.devopseng@gmail.com
# Build, Deploy, Display Ex. IP
# Format: see https://aka.ms/yaml

trigger:
- none  # switch to main for submission

pool:
  vmImage: ubuntu-latest
  parallel: 1

steps:
- task: Docker@2
  displayName: 'Build'
  inputs:
    containerRegistry: 'DevOpsEng-DockerHub'
    repository: 'paulmayer2731 / web-app-devops-project'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
    tags: 'latest'

- task: KubernetesManifest@1
  displayName: 'Deploy'
  inputs:
    action: 'deploy'
    connectionType: 'azureResourceManager'
    azureSubscriptionConnection: 'Paul Mayer DevOps(3542213f-7e7a-4dad-aea4-fe30482ed0f3)'
    azureResourceGroup: 'networking-resource-group'
    kubernetesCluster: 'terraform-aks-cluster'
    namespace: 'default'
    manifests: 'application-manifest.yaml'

- task: Kubernetes@1
  displayName: 'Kubernetes Login'
  inputs:
    connectionType: 'Kubernetes Service Connection'
    kubernetesServiceEndpoint: 'terraform-aks-cluster-sp'
    command:  login
- script: |
    kubectl describe services flask-app-service | grep 'LoadBalancer Ingress'
  displayName: LoadBalancer Ingress IP
</pre>

### Desployment tests
 1. Kubectl can be used to check the ASK deployment, in the usual way:
    - $ kubectl get namespaces
    - $ kubectl get deployments -n ~namespace-name~
    - $ kubectl get services -n ~namespace-name~
    - $ kubectl get pods-n ~namespace-name~<br>
 2. Brows to the service and test application functionality. With the LoadBalancer exposing an external IP address, and that address displayed during CI/CD pipeline run, we can imediately brows to the application and run functional tests.


 ## AKS Cluster Monitoring <a name="aks-cluster-monitoring"></a>
 For DevOps, monitoring is a critical practice. It involves continuous tracking, assessment, and management of resources to ensure their performance and availability. Through monitoring we can maintain resiliant, robust infrastructures and applications, we can prevent downtime, and optimize resource usage.

 ### Container Insights
 Within Azure, we enabled [Container Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview) for our AKS cluster (terraform-aks-cluster). To accommodate Container Insights, Azure ctreated a Log Analytics Workspace (defaultworkspace-3542213f-7e7a-4dad-aea4-fe30482ed0f3-suk). Within the cluster, Container Insights created a logging workload (ama-logs-rs), as the [Azure Monitor Agent](https://learn.microsoft.com/en-us/azure/azure-monitor/agents/agents-overview).

### Metrics
Container Insights made data available to the Metrics explorer. Using Metrics, four charts were created and pinned to a private dashboard (Web-App-Dash). The new charts displayed a recent history of: average CPU usage, disck usage (%), average pod count (ready state), bytes read and written (p/s).

### Web-App-Dash

![Web-App-Dash](https://github.com/HardToFindAUniqueUserName/Web-App-DevOps-Project/blob/main/Resources/DashBoard.GIF)


### Log Analytics - Queries
Within the AKS Cluster Logs, five custome [queries](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query) were created and saved.

THe saved queries are:
 - Average Nodes CPU Usage Percentage per Minute: Capture data on node-level usage at a granular level, with logs recorded per minute.
 - Average Nodes Memory Usage Percentage per Minute:  Tracking memory usage at node level allows us to detect memory-related performance concerns and efficiently allocate resources.
 - Pods Counts with Phase: Provides information on the count of pods in different phases (i.e., Pending, Running, or Terminating), offering insights into pod lifecycle management
 - Find a value in Container Logs Table ('warning'): By search for 'warning' values in container logs, we proactively detect issues or errors within our containers, allowing for prompt troubleshooting and issues resolution.
 - Monitoring Kubernetes Events: Monitoring Kubernetes events (i.e., pod scheduling, scaling, errors), helps to track overall health and stability of the cluster.


### Alerts
A new alert rule was created (Disk Usage Percentage), and two predefines alert rules (CPU Usage Percentage, Memory Working Set Percentage) were modified, to offer critical alerts for the AKS cluster.

 - CPU Usage Percentage: Monitors CPU usage and triggers an alert when it exceeds a specified threshold.
 - Memory Working Set Percentage: Monitors memory usage and sends alerts when it crosses a predefined threshold.
 - Disk Used Percentage: Proactively detect and address potential disk issues.

An Action Group (AKS-AG) was created to specify actions for the newly defined alerts. Currently, the action group is set to notify pmayer.devopseng@gmail.com, when any of the alert thresholds are breached.


## Secret Management <a name="secret-management"></a> 

A [Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/basic-concepts) (aks-rg-kv) was created to manage secrets (i.e., access credential). On creation a key vault is allocated a unique (to Azure) URI. Our URI is: https<span>://</span>aks-rg-kv.vault.azure.net/. The Key Vault URI is used to access and interact with the resources stored within the Azure Key Vault.

[RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview) is used to controle access to and management of the Key Vault. So, the Key Vault Administrator role was assigned to user: Paul Mayer.

Four secrets were added to the key vault. These replacing the database access credential, previously hard-coded in the app.py file. When the app.py file is executed, the secret value is assigned to the appropriate variable

| Variable Name  | Secret Name |
| ------------- | ------------- |
| server | db-server-name |
| database | database-name |
| username | db-server-username |
| password | db-server-password |

### Integrating Azure Key Vault with AKS
To integrate Key Vault with AKS, we must enable managed identity for the cluster. Then we must assigne the appropriate RBAC role to the identity.

#### [Enabling Managed Identity for AKS:](https://learn.microsoft.com/en-us/azure/aks/use-managed-identity)
Enable a managed identity for an existing AKS cluster:

az aks update --resource-group \<resource-group\> --name \<aks-cluster-name\> --enable-managed-identity

In our case:

az aks update --resource-group networking-resource-group --name terraform-aks-cluster --enable-managed-identity

When managed identity is enables, the clientId is printed out (ammongst other information). To retrieve the clientId, retrospectively, we can run:

az aks show --resource-group \<resource-group\> --name \<aks-cluster-name\> --query identityProfile

In our case:

az aks show --resource-group networking-resource-group --name terraform-aks-cluster --query identityProfile

#### Assign KV Permissions

Assigning Key Vault Permissions:  

Assign "Key Vault Secrets Officer" role to Managed Identity:

az role assignment create --role "Key Vault Secrets Officer" --assignee \<managed-identity-client-id\> --scope /subscriptions/\<subscription-id\>/resourceGroups/\<resource-group\>/providers/Microsoft.KeyVault/vaults/\<key-vault-name\>

In our case:

az role assignment create --role "Key Vault Secrets Officer" --assignee 9d1afaf4-dc19-4743-8e70-b27a8a5f6b37 --scope /subscriptions/3542213f-7e7a-4dad-aea4-fe30482ed0f3/resourceGroups/aks-rg/providers/Microsoft.KeyVault/vaults/aks-rg-kv


### Addatting the Code to Use KV
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

Provide connection URL to Key Vault:
key_vault_url = \<key vault URL from key vault overview page\>

Set up Azure Key Vault client with Managed Identity
credential = ManagedIdentityCredential()
secret_client = SecretClient(vault_url=key_vault_url, credential=credential)

Access the secret values from Key Vault
secret = secret_client.get_secret("secret-name")

Access the secret values
secret_value = secret.value

 Our our aditional application code looks like this:
<pre>
from azure.identity import ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

# Initialise Flask App
app = Flask(__name__)

# Provide connection URL to Key Vault:
key_vault_url = "https://aks-rg-kv.vault.azure.net/"

# Set up Azure Key Vault client with Managed Identity
credential = ManagedIdentityCredential()
secret_client = SecretClient(vault_url=key_vault_url, credential=credential)

# Access the secret values from Key Vault
secret = secret_client.get_secret("db-server-name")

# Access the secret values
secret_value = secret.value

# database connection                                             # KV keys             # Original vaules
server = secret_value                                             # db-server-name      # 'devops-project-server.database.windows.net'
# Now directly:
database = secret_client.get_secret("database-name").value        # database-name       # 'orders-db'
username = secret_client.get_secret("db-server-username").value   # db-server-username  # 'maya'
password = secret_client.get_secret("db-server-password").value   # db-server-password  # 'AiCore1237' 
driver= '{ODBC Driver 18 for SQL Server}'
</pre>

### Azure Identity and Azure Key Vault libraries
In order to run the new code, our application requires access to the Azure Identity and Azure Key Vault libraries. So, they need to be installed when the application container is built. The commands to install these libraries will be fed to the Dockerfile by the requirements.txt file.

New requirements.txt file:
<pre>
flask==2.2.2
pyodbc==4.0.39
SQLAlchemy==2.0.21
werkzeug==2.2.3
azure-identity
azure-keyvault-secrets
</pre>

### Deployment and Test
The modified application was deployed through the azure-pipelines.yml, build/deploy pipeline.

Application thoroughly tested via web-browser.
 - Pages traversed
 - Page contents checked
 - New order added

Here we see the final deployment of the order management service.

![FinalDeployment](https://github.com/HardToFindAUniqueUserName/Web-App-DevOps-Project/blob/main/Resources/FinalDeployment.GIF)



## Deployment Architecture
Herewith the architecture of the complete deployment:
[DevOps Pipeline Architecture.pdf](https://github.com/HardToFindAUniqueUserName/Web-App-DevOps-Project/files/14022921/DevOps.Pipeline.Architecture.pdf)

## Troubleshooting <a name="troubleshooting"></a>
Woke up one morning and my cluster was gone.
 Done just sing the Blues! <br>
Having recreated the cluster, remember to renew credentials in the kubectl file. This will allow the kubectl CLI to access the cluster. To do this run:

  - az aks get-credentials --name \<aks-cluster-name\> --resource-group \<resource-group-name\><br>

In our case:<br>

  - az aks get-credentials --name terraform-aks-cluster --resource-group networking-resource-group

Managed identity will have to be enabled for the new cluster:<br>

 - az aks update --resource-group <resource-group> --name <aks-cluster-name> --enable-managed-identity<br>

In our case:<br>

 - az aks update --resource-group networking-resource-group --name terraform-aks-cluster --enable-managed-identity

From the output, identify the ' "identityProfile": "kubeletidentity": "clientId" '

Sample snippet of output:
<pre>
 "identityProfile": {
    "kubeletidentity": {
      "clientId": "9d1afaf4-dc19-4743-8e70-b27a8a5f6b37",
      "objectId": "e7833490-e65c-451d-bb4d-2d7178e327b7",
      "resourceId": "/subscriptions/3542213f-7e7a-4dad-aea4-fe30482ed0f3/resourcegroups/MC_networking-resource-group_terraform-aks-cluster_uksouth/providers/Microsoft.ManagedIdentity/userAssignedIdentities/terraform-aks-cluster-agentpool"
    }
  },
</pre>
If you can't find the clientId, run:

 - az aks show --resource-group <resource-group> --name <aks-cluster-name> --query identityProfile

In our case:<br>

 - az aks show --resource-group networking-resource-group --name terraform-aks-cluster --query identityProfile

This will return information about the managed identity (inc. clientId under identityProfile):

Now assign "Key Vault Secrets Officer" role to Managed Identity:

 - az role assignment create --role "Key Vault Secrets Officer" --assignee \<managed-identity-client-id\> --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.KeyVault/vaults/{key-vault-name}

In our example:<br>

 - az role assignment create --role "Key Vault Secrets Officer" --assignee 9d1afaf4-dc19-4743-8e70-b27a8a5f6b37 --scope /subscriptions/3542213f-7e7a-4dad-aea4-fe30482ed0f3/resourceGroups/aks-rg/providers/Microsoft.KeyVault/vaults/aks-rg-kv

#### - NOTE: On a Windows machine with Linux emulation, use PS (as admin) to run these commands. 

Scripts that access the service container (like our Kubernetes@1 task that displays the external IP address of the service) will need to be updated with new access credentials. So, rebuild the Kubernetes@1 login task. However, this time specify connectionType as 'Azure Resource Manager' with Managed Identity authentication, rather than 'Kubernetes Service Connection'.

Final pipeline file is here:
<pre>
# CI/CD Pipeline
# Author: pmayer.devopseng@gmail.com
# Build, Deploy, Display Ex. IP
# Format: see https://aka.ms/yaml

trigger:
- none  # switch to main for submission

pool:
  vmImage: ubuntu-latest
  parallel: 1

steps:
- task: Docker@2
  displayName: 'Build'
  inputs:
    containerRegistry: 'DevOpsEng-DockerHub'
    repository: 'paulmayer2731 / web-app-devops-project'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
    tags: 'latest'

- task: KubernetesManifest@1
  displayName: 'Deploy'
  inputs:
    action: 'deploy'
    connectionType: 'azureResourceManager'
    azureSubscriptionConnection: 'Paul Mayer DevOps(3542213f-7e7a-4dad-aea4-fe30482ed0f3)'
    azureResourceGroup: 'networking-resource-group'
    kubernetesCluster: 'terraform-aks-cluster'
    namespace: 'default'
    manifests: 'application-manifest.yaml'

- task: Kubernetes@1
  inputs:
    connectionType: 'Azure Resource Manager'
    azureSubscriptionEndpoint: 'Paul Mayer DevOps(3542213f-7e7a-4dad-aea4-fe30482ed0f3)'
    azureResourceGroup: 'networking-resource-group'
    kubernetesCluster: 'terraform-aks-cluster'
    namespace: 'default'
    command: 'login'
- script: |
    kubectl describe services flask-app-service | grep 'LoadBalancer Ingress'
  displayName: LoadBalancer Ingress IP
</pre>

## Contributors <a name="contributors"></a>

- [Maya Iuga]([https://github.com/yourusername](https://github.com/maya-a-iuga))
- Paul Mayer

## License <a name="license"></a>

The project is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.
The project solution falls under the same licensing as the project presented by AiCore.
