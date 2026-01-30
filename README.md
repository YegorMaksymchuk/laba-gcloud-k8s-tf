# laba-gcloud-k8s-tf

Infrastructure-as-Code repository for provisioning a GKE cluster on Google Cloud using Terraform and the `tf-google-gke-cluster` module.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`) configured with a project and credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (optional, for cluster access after deploy)
- Access to the `tf-google-gke-cluster` module (or your own fork)

## Commands to create the GKE cluster

Run these steps in order. Replace placeholders (e.g. `YOUR_PROJECT_ID`) with values from your `vars.tfvars` or environment.

### 1. Navigate to the Terraform directory

```bash
cd laba-gcloud-k8s-tf
```

Use the full path to your project root if needed. All following commands assume you are in this directory.

### 2. Authenticate with GCP (local only)

```bash
gcloud auth application-default login
```

Opens a browser for sign-in and saves Application Default Credentials so Terraform can use the GCS backend and create resources. **Skip this step if you are using Google Cloud Shell** (credentials are already configured there). After login, you should see "Credentials saved to file".

### 3. Enable Kubernetes Engine API

```bash
gcloud services enable container.googleapis.com --project=YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with your `GOOGLE_PROJECT` value from `vars.tfvars` (e.g. `silicon-amulet-485722-g6`). Without this, `terraform apply` fails with **Error 403: Kubernetes Engine API has not been used... or it is disabled**. Wait 1–2 minutes after running before the next step.

**Example:**

```bash
gcloud services enable container.googleapis.com --project=silicon-amulet-485722-g6
```

### 4. Create a GCS bucket (if not done yet)

You need a bucket to store Terraform state. See [Creating a GCS bucket](#creating-a-gcs-bucket) below. Then in `main.tf`, set the `bucket` name in the `backend "gcs"` block to your bucket name (replace `your-bucket-name` or the current value).

### 5. Initialize Terraform

```bash
terraform init
```

Downloads providers and the GKE module and configures the GCS backend. You should see **"Terraform has been successfully initialized!"**. If you see "could not find default credentials", complete step 2 first, then run `terraform init` again.

### 6. Format and validate

```bash
terraform fmt
terraform validate
```

`terraform fmt` reformats `.tf` files. `terraform validate` checks syntax and configuration. Expect **"Success! The configuration is valid."**

### 7. Plan changes

```bash
terraform plan -var-file=vars.tfvars -out=tfplan
```

Shows the planned infrastructure changes and saves the plan to `tfplan`. Review the output (resources to add/change/destroy). You can run `terraform apply tfplan` next to apply exactly this plan.

### 8. Apply changes (create the cluster)

```bash
terraform apply -var-file=vars.tfvars
```

Or, to use the saved plan and skip the interactive prompt:

```bash
terraform apply tfplan
```

To apply without confirmation:

```bash
terraform apply -var-file=vars.tfvars -auto-approve
```

Creates the GKE cluster and node pool. This can take several minutes. You should see **"Apply complete! Resources: X added, 0 changed, 0 destroyed."**

### 9. Verify

```bash
terraform show
```

Displays the current state in readable form. In [GCP Console → Kubernetes Engine → Clusters](https://console.cloud.google.com/kubernetes/list), your cluster should appear with status **Running**.

### 10. Get kubectl access (optional)

```bash
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION --project=PROJECT_ID
```

Replace `CLUSTER_NAME` (usually `main` from the module), `REGION` (e.g. `europe-central2`), and `PROJECT_ID` with your values. Then run:

```bash
kubectl get nodes
```

You should see the cluster nodes in `Ready` state.

**Example:**

```bash
gcloud container clusters get-credentials main --region=europe-central2 --project=silicon-amulet-485722-g6
kubectl get nodes
```

---

## Setup

1. **Set variable values**  
   Edit `vars.tfvars` and set `GOOGLE_PROJECT`, `GOOGLE_REGION`, and optionally `GKE_NUM_NODES` and `GKE_MACHINE_TYPE` for your GCP project.

2. **Create a GCS bucket for Terraform state**  
   See [Creating a GCS bucket](#creating-a-gcs-bucket) below. Then in `main.tf`, replace the bucket name in the `backend "gcs"` block with your bucket name.

### Avoiding SSD quota errors (SSD_TOTAL_GB exceeded)

If `terraform apply` fails with **GCE_QUOTA_EXCEEDED: Quota 'SSD_TOTAL_GB' exceeded**:

- **Small instance and 2 nodes:** In `vars.tfvars` set `GKE_MACHINE_TYPE = "g1-small"` (or `e2-small`, `e2-micro`) and `GKE_NUM_NODES = 2` — fewer nodes and a smaller type reduce total disk usage and cost.
- **Different region:** Change `GOOGLE_REGION` to a region with more SSD quota (e.g. `europe-west1`, `us-central1`).
- **HDD instead of SSD:** In the `tf-google-gke-cluster` module, in the node pool `node_config` use `disk_type = "pd-standard"` and `disk_size_gb = 50` so node disks are HDD and do not count toward SSD quota. In this repo the downloaded module (`.terraform/modules/gke_cluster`) may already have this; after `terraform init` those changes can be overwritten, so for a permanent fix add the same in your module repository.

---

## Creating a GCS bucket

The bucket is required to store Terraform state in Google Cloud Storage.

### Option 1: Google Cloud Console

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. Select your **project** in the top bar.
3. In the left menu go to **Cloud Storage** → **Buckets** (or open [Storage](https://console.cloud.google.com/storage/browser)).
4. Click **Create bucket**.
5. Set:
   - **Name** — a unique bucket name (e.g. `my-project-tf-state`). The name must be globally unique in GCP.
   - **Location type** — choose **Region** and the same region as for GKE (e.g. `europe-central2`), or **Multi-region** (e.g. `eu`).
   - **Storage class** — Standard is sufficient for state.
   - **Access control** — leave **Uniform** (recommended).
6. Click **Create**.
7. Copy the **bucket name** and set it in `main.tf` in the `backend "gcs"` block (replace `your-bucket-name`).

### Option 2: gcloud (terminal)

1. Install and configure [Google Cloud CLI](https://cloud.google.com/sdk/docs/install), then run `gcloud auth login` and `gcloud config set project YOUR_PROJECT_ID`.
2. Run (replace values as needed):

```bash
# Replace BUCKET_NAME with a unique name (e.g. my-project-tf-state)
# Replace REGION with your region (e.g. europe-central2)
export BUCKET_NAME="my-project-tf-state"
export REGION="europe-central2"

gcloud storage buckets create gs://${BUCKET_NAME} \
  --location=${REGION} \
  --project=YOUR_PROJECT_ID
```

3. Use the value of `BUCKET_NAME` as the bucket name in `main.tf` in the `backend "gcs"` block.

### After creating the bucket

In `main.tf`, in the `terraform { backend "gcs" { ... } }` block, replace `your-bucket-name` with your bucket name. Then run `terraform init` (or `terraform init -migrate-state` if you already have local state to move to GCS).

---

## Troubleshooting

### Error: could not find default credentials

If `terraform init` fails with **"google: could not find default credentials"**, Terraform cannot reach the GCS backend because Google Cloud credentials are not configured.

- **Option 1 (recommended):** Run Terraform from **Google Cloud Shell** — credentials are already configured there.
- **Option 2 (local):** Run Application Default Credentials login:
  ```bash
  gcloud auth application-default login
  ```
  Choose your account and allow access. Then run `terraform init` again.

### Error 403: Kubernetes Engine API disabled (SERVICE_DISABLED)

If `terraform apply` fails with **Error 403: Kubernetes Engine API has not been used in project ... or it is disabled**, enable the API:

```bash
gcloud services enable container.googleapis.com --project=YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with your project ID. Wait 1–2 minutes, then run `terraform apply` again (or `terraform apply tfplan`).

### Saved plan is stale

If `terraform apply tfplan` fails with **"Saved plan is stale"**, the state changed after the plan was created. Generate a new plan and apply it:

```bash
terraform plan -var-file=vars.tfvars -out=tfplan
terraform apply tfplan
```

---

## Terraform commands reference

From the directory containing the Terraform files:

| Command | Purpose |
|---------|--------|
| `terraform init` | Initialize backend and download providers and modules. Run again after changing the backend. |
| `terraform fmt` | Format `.tf` files. |
| `terraform validate` | Check configuration syntax and validity. |
| `terraform plan -var-file=vars.tfvars` | Show planned changes. Add `-out=tfplan` to save the plan. |
| `terraform apply -var-file=vars.tfvars` | Apply changes (or use `terraform apply tfplan` for a saved plan). Use `-auto-approve` to skip confirmation. |
| `terraform show` | Display current state. |
| `terraform destroy -var-file=vars.tfvars` | Destroy all resources managed by this configuration. |

After adding or changing the GCS backend, run `terraform init` again. If you had local state, use `terraform init -migrate-state` to move it to GCS.

**Optional:** To estimate cost before apply, run `infracost breakdown --path . --terraform-var-file=vars.tfvars` (requires [Infracost](https://www.infracost.io/) and API key).

---

## What to commit and what not (file reference)

### Do not commit (in .gitignore or do not add to the repo)

| File / folder | What it does | Why not to commit |
|---------------|--------------|-------------------|
| `.terraform/` | Terraform cache: providers, modules, internal data | Local cache; recreated by `terraform init` |
| `*.tfstate` | Current infrastructure state (resources, attributes) | May contain secrets; conflicts can corrupt state |
| `*.tfstate.*` | State backup files | Same — sensitive data |
| `*.tfplan` | Saved plan (`terraform plan -out=...`) | May contain variable values; not required in repo |
| `.terraform.lock.hcl` | Locks provider versions | In this repo it is in .gitignore; some projects commit it for consistent versions |
| `vars.tfvars` | Variable values (project ID, region, node count) | If it contains real project IDs or secrets, do not publish; use `vars.tfvars.example` with placeholders instead |

### Commit these (and what each file is for)

| File | What it does |
|------|--------------|
| `main.tf` | GCS backend for state; call to the GKE module (source, variables) |
| `variables.tf` | Variable declarations (GOOGLE_PROJECT, GOOGLE_REGION, GKE_NUM_NODES, GKE_MACHINE_TYPE) |
| `vars.tf` | Empty or extra defaults; optional to commit |
| `vars.tfvars` | Concrete values for plan/apply; commit only if free of secrets, or replace with an example file |
| `.gitignore` | List of files/patterns for Git to ignore (state, .terraform, tfplan) |
| `README.md` | Documentation: commands, bucket, troubleshooting, security |

---

## Security

Do **not** commit to a public repository:

- Terraform state files (`*.tfstate`, `*.tfstate.*`) — they may contain secrets
- `vars.tfvars` if it contains real project IDs, credentials, or other secrets (use `vars.tfvars.example` with placeholders instead)
- Logs or dumps that include credentials

Terraform state may contain sensitive data (passwords, keys). Store it in a secure, access-controlled location (e.g. GCS with IAM). Prefer environment variables or a secrets manager for credentials used by Terraform.

---

## Deliverable

The answer to the task is the **link to this repository** (e.g. the `develop` or `main` branch with the completed changes).
