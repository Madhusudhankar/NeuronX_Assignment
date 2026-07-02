# NeuraNx Assignment - Azure

## 📌 Overview
This project provisions a small Azure infrastructure stack using Terraform, focusing on clean, reusable Infrastructure as Code (IaC).

---

## 📖 Table of Contents
* [📋 Prerequisites](#-prerequisites)
* [🛠️ Resources Created](#%EF%B8%8F-resources-created)
* [🌐 Access](#-access)
* [⚙️ Setup Guides](#%EF%B8%8F-setup-guides)
* [💻 How to Run (Locally)](#-how-to-run-locally)
* [🔄 CI/CD Pipeline](#-cicd-pipeline)
* [💾 Remote State](#-remote-state)
* [📐 Design Notes](#-design-notes)
* [⚠️ Challenges Faced & Solutions](#%EF%B8%8F-challenges-faced--solutions)
* [🤖 AI Usage Declaration](#-ai-usage-declaration)
* [🔗 References](#-references)

---

## 📋 Prerequisites

Please ensure the following tooling, versions, and cloud access requirements are satisfied prior to initialization.

### Tooling Requirements

| Tool | Minimum Version | Purpose |
| :--- | :--- | :--- |
| **Terraform CLI** | `v1.5.0` | Infrastructure deployment & state management |
| **Azure CLI** | `v2.50.0` | Local account authentication & credential provisioning |
| **Git** | `v2.30.0` | Version control & remote repository management |

### Cloud & Platform Access

| Platform | Requirement | Purpose |
| :--- | :--- | :--- |
| **Azure Subscription** | Active status | Hosting target resources |
| **Azure IAM Role** | `Contributor` or `Owner` | Provisioning permissions inside subscription bounds |
| **GitHub Account** | Repository Admin | Configuring pipeline secrets & running CI/CD |

---

## 🛠️ Resources Created
* **Resource Group:** Logical container that group-manages the lifecycle of all deployed project resources.
* **Storage Account + Container:** Cloud storage backend used to securely hold and lock the remote Terraform state file.
* **Virtual Network + Subnet:** Isolated cloud network infrastructure that provides secure IP address allocations for compute resources.
* **Network Security Group (NSG):** Stateful firewall configuration used to control inbound and outbound traffic to the network.
* **Azure Container Instances (ACI):** Serverless container hosting environment used to provision and spin up lightweight applications instantly.
* **Azure App Service:** Fully managed platform-as-a-service (PaaS) framework optimized for hosting scaling web architectures.

![Resource Group Demo](demo-rg.jpg)

---

## 🌐 Access
After deployment, you can access your resources via the following endpoints:

* **Azure App Service URL:** `https://<your-app-service-name>.azurewebsites.net`
* **Azure Container Instance (ACI) FQDN:** `http://<your-aci-dns-label>.<region>.azurecontainer.io`

---

## ⚙️ Setup Guides

### 1. Generate Azure Credentials
Create an Azure Service Principal with **Contributor** access to authenticate the GitHub pipeline:
```bash
az ad sp create-for-rbac --name "myTerraformSP" --role contributor --scopes /subscriptions/<SUBSCRIPTION_ID> --sdk-auth
```

### 2. Configure GitHub Secrets
Save the JSON output from the command above into your GitHub repository settings under **Settings > Secrets and variables > Actions** using the following key:
* `AZURE_CREDENTIALS`

---

## 💻 How to Run (Locally)

### 1. Authenticate
```bash
az login
```

### 2. Initialize
```bash
terraform init
```

### 3. Validate
```bash
terraform validate
```

### 4. Plan
```bash
terraform plan -var-file="terraform.tfvars"
```

### 5. Apply
```bash
terraform apply -var-file="terraform.tfvars"
```

---

## 🔄 CI/CD Pipeline
The deployment relies on GitHub Actions pipelines split into distinct stages:

### Stage 1: Lint & Validate (`validate_and_lint`)
* Runs `terraform fmt` to check style.
* Runs `terraform validate` to check syntax.

### Stage 2: AZ Login & Plan
* Runs only if Stage 1 finishes successfully (`needs: validate_and_lint`).
* Executes `terraform plan` and generates structural execution receipts.

### Steps to use Pipeline.
 * Clone the Repo locally or as you need.
 * Replace the values in terraform.tfvars file and commit the changes.
 * Pipeline gets triggered once the changes merged into main branch. 

---

## 💾 Remote State
The infrastructure utilizes an Azure Storage backend configured in the `backend.tf` file:

* **Storage Account:** Stores the state file securely.
* **Blob Container:** Holds the `.tfstate` file path.
* **State Locking:** Enabled via Azure Blob storage leases to prevent concurrent execution conflicts.

---

## 📐 Design Notes

### Decisions
* **ACI over VM:** Chosen for lightweight, fast provisioning.
* **NSG Rules:** Minimal footprint (only HTTP/HTTPS allowed via least privilege).
* **Random DNS Suffix:** Implemented to avoid naming collisions across global Azure regions.
* **Parameterized Config:** Variables used globally to promote module reuse.

### Trade-offs
* Resouces are created indenpendently, The resources are not performing any task collectively as an application.
* No auto-scaling configured for the container instances.
* Public endpoints are used instead of securing resources inside a private subnet.
* Minimal logging and monitoring tools are implemented.

### Production Enhancements (Security & Compliance)
To graduate this deployment into a secure, hardened enterprise environment, the following implementations are required:

* **Network Isolation:** Transition public compute workloads (ACI and App Service) into private virtual networks using Azure Private Endpoints and Private Link services.
* **Secrets Hardening:** Eliminate plaintext environment variables by pulling database strings, connection certificates, and sensitive payloads from Azure Key Vault using Managed Identities.
* **Traffic Control:** Route public ingress traffic through an Azure Application Gateway or Azure Front Door to layer Web Application Firewall (WAF) rule sets against common vulnerabilities.
* **Compliance & Auditing:** Enable diagnostic streaming to an Azure Log Analytics Workspace via Azure Monitor, and enforce enterprise governance using predefined Azure Policies (e.g., restricting allowed deployment regions and requiring structural infrastructure tagging).
* **Multi-Environment Segmentation:** Isolate workloads across distinct subscriptions and maintain separate, structurally locked state files for Dev, Stage, and Prod environments.
* **Right-Sizing Resources:** Perform capacity planning to select appropriate SKUs that balance performance, security, and cost.

---

## ⚠️ Challenges Faced & Solutions

### 1. GitHub Push Rejections (Azure Provider Binary Size File Bounds)
* **Challenge:** Pushing local changes to the remote GitHub repository failed with a hard rejection error. The execution trace showed that Git was tracking the local `.terraform/` dependency cache subdirectory, which contained the compiled AzureRM provider plugin binary (`terraform-provider-azurerm`). At over 220MB, the provider exceeded GitHub's maximum strict per-file upload limitation of 100MB.
* **Solution:** Cleaned out the tracked cache from the active index history and deployed a standardized `.gitignore` file to the root workspace. Adding custom rules to explicitly ignore `.terraform/`, `*.tfstate*`, and system plugin runtimes stopped the local build artifacts from ever staging, allowing pure infrastructure declaration code to pass through securely.

### 2. GitHub Actions Session Eviction (Independent Login Stage)
* **Challenge:** Configuring `az login` as a completely standalone, independent stage/job in the GitHub Actions workflow caused immediate downstream command failures. Because GitHub Actions provisions fresh, isolated runner environments (containers/VMs) for each separate job, the authenticated session state was wiped out when the initial login stage terminated, leaving subsequent `terraform plan` and `terraform apply` stages unauthenticated.
* **Solution:** Re-architected the workflow file to bundle the `Azure/login@v1` step directly within the active task execution steps of both the Plan and Apply deployment stages. Authenticating inline inside the local task scope ensured the runner maintained an active security context for all nested Terraform blocks.

### 3. Local CLI Token Refresh Failures (Legacy MFA)
* **Challenge:** Running Terraform commands locally after executing `az login` resulted in persistent authentication errors and token handshake failures. The issue stemmed from the user account using a legacy Multi-Factor Authentication (MFA) mechanism (e.g., SMS/Voice) that failed to pass modern interactive conditional access evaluations requested by the AzureRM Terraform provider.
* **Solution:** Navigated to Microsoft Entra ID (formerly Azure AD), disabled the outdated tenant-level per-user legacy MFA requirements, and explicitly configured modern Authenticator MFA on the user profile. Once updated to the Microsoft Authenticator app, conditional tokens successfully injected into the local session context during `az login`.

### 4. Global Resource Naming Conflicts
* **Challenge:** Azure Storage Accounts and App Services require globally unique DNS names. Initial resource creation attempts failed because common naming variations were already taken by other users globally.
* **Solution:** Integrated the Terraform `random_string` resource to dynamically generate a 6-character unique suffix, appending it to resource names during evaluation.

### 5. GitHub Actions Pipeline Authentication
* **Challenge:** Securely passing deployment permissions to the GitHub Actions worker without hardcoding vulnerable IAM keys or interactive passwords.
* **Solution:** Generated a dedicated, scoped Azure Service Principal via the Azure CLI and safely embedded its JSON payloads into GitHub encrypted repository secrets as `AZURE_CREDENTIALS`.

---

## 🤖 AI Usage Declaration

### GitHub Copilot

I developed this project with assistance from GitHub Copilot.

Copilot was used to:

- Generate the initial Terraform project structure.
- Suggest Terraform configuration patterns.
- Improve the README documentation.
- Assist with creating the Table of Contents and documentation sections.
- Help verify variable definitions and resource organization.

Examples include:

- Applying the secondary region structure.
- Verifying variable definitions.
- Generating the initial README structure based on the available code.

All infrastructure decisions, code modifications, testing, validation, debugging, and final implementation were completed and verified by me.

### Google AI

Google AI was used primarily for learning and understanding Terraform and Azure concepts before implementing changes.

It was used for topics such as:

- Understanding GitHub Actions secrets in public repositories.
- Comparing Client Secret authentication with OIDC for Azure Login.
- Handling large files in Git repositories.
- Reviewing Terraform provider documentation and version compatibility.

The information obtained was used only as guidance, and all final implementation decisions and code modifications were completed by me.

## 🔗 References

- Terraform Documentation: https://developer.hashicorp.com/terraform/docs
- Azure Provider Documentation: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure CLI Documentation: https://learn.microsoft.com/cli/azure/
- GitHub Actions Documentation: https://docs.github.com/actions
- Azure Login GitHub Action: https://github.com/Azure/login