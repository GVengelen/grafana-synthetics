# Session 3: Deploying Synthetics with Terraform (90 minutes)

## Introduction
In this session, we'll explore how to automate the deployment of your synthetic monitoring checks using Infrastructure as Code (IaC) principles. By the end of this session, you'll understand how to configure, version, and automate your Grafana Synthetics deployments using Terraform and GitHub Actions.

### Why Automate Synthetic Monitoring Deployments?
Automating your synthetic monitoring deployments offers several key advantages:

- **Consistency**: Ensures all environments follow the same monitoring standards
- **Version Control**: Track changes to your monitoring configurations over time
- **Auditability**: Know who changed what and when
- **Repeatability**: Easily replicate monitoring setups across environments
- **Scalability**: Manage hundreds of checks without manual intervention
- **Disaster Recovery**: Quickly restore your monitoring setup if needed

And let's be honest, we want to automate everything!
![Automate everything](./images/automate.jpg)

## Understanding the Deployment Lifecycle

### Setting up synthetics the wrong way
Traditionally, setting up synthetic monitoring involves:
1. Logging into a monitoring portal
2. Manually configuring checks through a UI
3. Testing the checks
4. Documenting configurations separately
5. Manually updating checks when needed

This approach has several drawbacks:
- Time-consuming for large numbers of checks
- Prone to human error
- Difficult to track changes
- Challenging to maintain consistency

### The IaC Approach(the right way)
With Infrastructure as Code:
1. Define monitoring checks in code (Terraform)
2. Version the code in a repository (GitHub)
3. Review changes through pull requests
4. Automatically deploy approved changes (GitHub Actions)
5. Track the state of deployed resources

Benefits include:
- Automated, consistent deployments
- Built-in change management
- Easy scaling to hundreds of checks
- Self-documenting configurations(Because code is my documentation)

## Configuring Synthetics in Grafana Cloud

### Understanding Grafana Cloud Synthetics
Grafana Cloud Synthetics provides:
- API-based checks for backend monitoring
- Browser-based checks for frontend experience
- Multi-region probing(both public and private)
- Advanced alerting capabilities
- Integration with other Grafana observability tools

### Key Configuration Concepts
When setting up Grafana Synthetics, you'll work with:

1. **Checks**: Individual monitoring tests (API or browser)
2. **Probes**: Geographic locations where checks run from
3. **Frequency**: How often checks execute
4. **Timeouts**: Maximum duration for check execution
5. **Thresholds**: Performance or availability targets
6. **Alerting**: Notification rules when checks fail

### Authentication and Access
To automate Grafana Cloud Synthetics deployments, you'll need:
- A Grafana Cloud account
- API keys with appropriate permissions
- Service account tokens for CI/CD

## Setting Up Terraform for Grafana Synthetics

### What is Terraform?
Terraform is an open-source Infrastructure as Code tool that allows you to define and provision infrastructure using a declarative configuration language. It supports hundreds of providers, like Grafana Cloud.

### Why Terraform for Synthetics?
Terraform is ideal for managing synthetic monitoring because:
- It provides a consistent workflow for all resources
- It tracks the state of deployed resources
- It supports planning changes before applying them
- It integrates well with CI/CD pipelines
- It's declarative

## Hands-on: Deploy Your Synthetics Using Terraform

In this exercise, we'll set up a complete Terraform project to deploy Grafana Synthetics checks. We'll create all necessary files and directories from scratch and then automate the deployment using GitHub Actions.

### Step 1: Setting Up Your Project Structure

First, let's create a proper directory structure for our Terraform project:

```bash
mkdir -p terraform/synthetics
cd terraform/synthetics
```

Within this directory, we'll create several files:
- `main.tf` - Main Terraform configuration
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `providers.tf` - Provider configuration
- `checks.tf` - Synthetic check definitions

### Step 2: Configuring the Terraform Provider

Create a file called `providers.tf` with the following content:

```terraform
provider "grafana" {
  url             = "https://gjvengelen.grafana.net/"
  auth            = var.grafana_service_token
  sm_url          = "https://synthetic-monitoring-api-eu-west-2.grafana.net"
  sm_access_token = var.sm_access_token
}
```
You can create a free account at [grafana](https://grafana.com/auth/sign-up).
Each user you is eligible for a 14-day trial of Pro and forever-free access to Grafana Cloud.

You can find the urls for the provider at: https://{your-instance-name}.grafana.net/a/grafana-synthetic-monitoring-app/config/terraform

This configures Terraform to use the Grafana provider, which allows us to interact with the Grafana Cloud API.

### Step 3: Setting Up Variables

Create a file called `variables.tf` to define the input variables:

```terraform
variable "grafana_service_token" {
  description = "Grafana service token"
  type        = string
  sensitive   = true
}

variable "sm_access_token" {
  description = "Synthetic Monitoring access token"
  type        = string
  sensitive   = true
}
```

These variables allow us to customize our deployment without changing the code.

### Step 4: Creating Your First Synthetic Check

Now, let's create a file called `main.tf` to define our synthetic checks:

First we'll add the monitoring probes provider, this will allow us to select probes by name instead of having to use their id's

```terraform
data "grafana_synthetic_monitoring_probes" "main" {}
```

Then we'll add our browser check
```terraform
resource "grafana_synthetic_monitoring_check" "Synthetics_BrowserCheck_login" {
  job       = "Synthetics:BrowserCheck"
  target    = "login"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.London]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../../scripts/browser.js")
    }
  }
}
```

Then we'll add our http check:
```terraform
resource "grafana_synthetic_monitoring_check" "Synthetics_HttpCheck_crocodiles" {
  job       = "Synthetics:BrowserCheck2"
  target    = "crocodiles"
  enabled   = true
  probes    = [data.grafana_synthetic_monitoring_probes.main.probes.Frankfurt,]
  labels    = {}
  frequency = 300000
  timeout   = 60000
  settings {
    browser {
      script = file("${path.module}/../../scripts/http.js")
    }
  }
}
```

What did we add?

| Property | Description | Default Value |
|----------|-------------|---------------|
| `resource "grafana_synthetic_monitoring_check"` | Declares a Terraform resource that creates a synthetic monitoring check in Grafana Cloud | N/A |
| `"Synthetics_HttpCheck_crocodiles"` | The resource name/identifier within Terraform, used to reference this check elsewhere | N/A |
| `job` | The job name that appears in Grafana UI and metrics, useful for grouping related checks | No default, required |
| `target` | A descriptive name for what this check is targeting | No default, required |
| `enabled` | Controls whether the check is active (true) or disabled (false) | `true` |
| `probes` | Specifies which geographic locations will run this check | No default, at least one probe required |
| `labels` | Key-value pairs for organizing and filtering checks | `{}` (empty map) |
| `frequency` | How often the check runs in milliseconds (300000ms = 5 minutes) | `60000` (1 minute) |
| `timeout` | Maximum time allowed for the check to complete before it's considered failed | `10000` (10 seconds) |
| `settings` | Contains configuration specific to the check type | Required block, no default |
| `browser` | Indicates this is a browser-based check | Required for browser checks |
| `script` | Points to the JavaScript file containing the check logic | No default, required for browser checks |

### Step 5: Adding Output Variables

Create an `outputs.tf` file to expose useful information about your deployed checks:

```terraform
output "synthetic_browser_monitoring_check_id" {
  description = "The ID of the created synthetic monitoring check."
  value       = grafana_synthetic_monitoring_check.Synthetics_BrowserCheck_login
}
output "synthetic_http_monitoring_check_id" {
  description = "The ID of the created synthetic monitoring check."
  value       = grafana_synthetic_monitoring_check.Synthetics_HttpCheck_crocodiles
}
```

These outputs make it easier to find and access your checks after deployment.

### Step 6: Creating a Main Configuration File

Finally, create a `versions.tf` file as the entry point for your Terraform configuration:

```terraform
terraform {
  required_version = ">= 1.1.0"

  cloud {
    organization = "Grafana_Synthetics_Workshop"

    workspaces {
      name = "grafana-synthetics-main"
    }
  }

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 2.0.0"
    }
  }
}

```

This sets up where Terraform will store its state and what versions to use. We'll use Terraform Cloud as a backend.

### Step 7: Creating a terraform.tfvars File

I've provided an example variables file at `envs/dev/secrets.auto.example.tfvars`. You should:

1. Copy this file to a new file in the same directory, removing "example" from the name:

```bash
cp envs/dev/secrets.auto.example.tfvars envs/dev/secrets.auto.tfvars
```

2. Edit this new file with your actual credentials:

```terraform
# Local .tfvars file for sensitive values (do not commit to git)
grafana_service_token = "<Insert your Grafana service token here>"
# create a service account here https://{your-instance-name}.grafana.net/org/serviceaccounts
sm_access_token       = "<Insert your Synthetic Monitoring access token here>" 
# get your token here https://{your-instance-name}.grafana.net/a/grafana-synthetic-monitoring-app/config/access-tokens
```

**Important**: Never commit the `*.tfvars` files (except example files) to version control as they contain sensitive information. Ensure they're included in your `.gitignore` file.

### Step 8: Setting Up Terraform Cloud

We'll bee using Terraform Cloud as our backend (as specified in `versions.tf`), we need to set up an account and configure authentication:

1. **Create a Terraform Cloud Account**:
   - Go to [app.terraform.io](https://app.terraform.io/signup/account) and sign up for a free account
   - Verify your email address

2. **Create an Organization**:
   - After signing in, you'll be prompted to create an organization
   - Name it "Grafana_Synthetics_Workshop" to match our configuration (or update the configuration to match your org name)

3. **Create a Workspace**:
   - Navigate to Workspaces → Create a new Workspace
   - Select "CLI-driven workflow"
   - Name it "grafana-synthetics-main" to match our configuration

4. **Set execution to local**
    - Navigate to [here]
(https://app.terraform.io/app/Grafana_Synthetics_Workshop/workspaces/grafana-synthetics-main/settings/general)
    - Select execution mode `Local (custom)`
    - Click save settings

5. **Generate an API Token**:
   - Click on your user icon in the top right
   - Go to User Settings → Tokens
   - Click "Create an API token"
   - Name it (e.g., "Terraform CLI") and create the token
   - **Copy the token immediately** as it won't be shown again

6. **Configure Terraform CLI Authentication**:
   - Create or edit the Terraform CLI configuration file in your home directory:

```bash
vi ~/.terraformrc
```
you can use nano as well, I'm not judging.

   - Add the following content, replacing `YOUR_TOKEN_HERE` with your actual token:

```
credentials "app.terraform.io" {
  token = "YOUR_TOKEN_HERE"
}
```

   - Save the file and exit

This configuration allows Terraform to authenticate with Terraform Cloud when you run commands like `terraform init` and `terraform apply`.

### Step 9: Initializing and Applying Your Terraform Configuration

Now, let's initialize our Terraform project by first stepping into our directory:

```bash
cd terraform/synthetics
```
And now run:

```bash
terraform init
```

This will download the necessary provider plugins and set up your working directory.

Let's see what changes Terraform would make without actually applying them:

```bash
terraform plan -var-file="../envs/dev/secrets.auto.tfvars"
```

The `-var-file` flag specifies where Terraform should look for variable values, in this case pointing to our secrets file we created earlier. This ensures our sensitive credentials are properly loaded.

Review the plan to ensure it matches your expectations. Then, apply the changes:

```bash
terraform apply -var-file="../envs/dev/secrets.auto.tfvars"
```

Confirm by typing `yes` when prompted. Terraform will now create your synthetic monitoring checks in Grafana Cloud.

## Setting Up GitHub Actions for Automated Deployment

Now that we have our Terraform configuration working, let's set up GitHub Actions to automate the deployment process.

### Step 1: Create a GitHub Repository

If you started from scratch, create a new GitHub repository for your project:

```bash
git init
git add .
git commit -m "Initial commit of Terraform configuration"
```

Create a new repository on GitHub and push your code:

```bash
git remote add origin https://github.com/yourusername/yourprojectname.git
git push -u origin main
```

### Step 2: Set Up GitHub Secrets

In your GitHub repository, go to Settings > Secrets > Actions and add the following secrets:
- `GRAFANA_SERVICE_TOKEN`: Your Grafana Service Account Token
- `SM_ACCESS_TOKEN`: Your Grafana Synthetics Monitoring Token
- `TF_STATE_TOKEN`: Your Terraform Cloud Api Token

These secrets will be used by GitHub Actions to authenticate with Grafana Cloud.

### Step 3: Create a GitHub Actions Workflow

GitHub Actions workflows are defined in YAML files stored in the `.github/workflows` directory of your repository. Let's create this structure and add our workflow file:

1. First, create the directory structure for GitHub Actions:

```bash
mkdir -p .github/workflows
```

2. Next, create a new file called `on.create-pr.yml` in this directory:

```bash
touch .github/workflows/on.create-pr.yml
```

3. Open this file in your editor and add the following content:

Let's add the workflow name at the top:

```yaml
name: Pull Request Validation
```

This line sets the name of the workflow that will appear in the GitHub Actions UI. A clear, descriptive name helps team members understand the workflow's purpose at a glance.

Next, we define when this workflow should run:

```yaml
on:
  pull_request:
    branches: [ main ]
```

The `on` section specifies the GitHub events that trigger the workflow:
- `pull_request`: This workflow runs whenever a pull request is created or updated
- `branches: [ main ]`: It only triggers for pull requests targeting the main branch, not feature branches

Now we'll define the jobs this workflow will run:

```yaml
jobs:
  validate-scripts:
    runs-on: ubuntu-latest
    name: Validate K6 Scripts
```

This begins the `jobs` section, which contains all the tasks the workflow performs:
- `validate-scripts`: This is the job ID, used internally by GitHub Actions
- `runs-on: ubuntu-latest`: This job will run on the latest Ubuntu runner
- `name: Validate K6 Scripts`: A human-readable name for this job in the GitHub UI

Now we'll enter the steps for our script validation job:

```yaml
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
```

Steps are executed sequentially:
- `name: Checkout code`: Provides a label for this step
- `uses: actions/checkout@v4`: Uses the checkout action to clone your repository code to the runner

Next, we set up the K6 testing tool:

```yaml        
      - uses: grafana/setup-k6-action@v1
        with:
          browser: true
```

This step:
- Uses the official [Grafana K6](https://github.com/grafana/run-k6-action) setup action
- `with: browser: true`: Configures K6 with browser support, which is necessary for browser-based tests

Then we run the validation tests:

```yaml
      - uses: grafana/run-k6-action@v1
        with:
          path: |
            ./scripts/*.js
```

This step:
- Uses the K6 run action to execute our test scripts
- `path: ./scripts/*.js`: Runs all JavaScript files in the scripts directory
- The pipe symbol `|` allows for multiple paths if needed

Now we'll define our second job for Terraform planning:

```yaml
  terraform-plan:
    runs-on: ubuntu-latest
    name: Terraform Plan
    needs: validate-scripts
```

This job:
- Has the ID `terraform-plan`
- Runs on Ubuntu like our first job
- Has a descriptive name "Terraform Plan"
- `needs: validate-scripts`: Only runs if the script validation job succeeds, creating a dependency. Since we don't want to update our checks if any of them fails upfront.

The steps for the Terraform job start with checking out code again:

```yaml    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
```

Each job runs in a fresh environment, so we need to check out the code again.

Next, we set up Terraform:

```yaml        
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.5"
          cli_config_credentials_token: ${{ secrets.TF_STATE_TOKEN }}
```

This step:
- Uses HashiCorp's official Terraform setup action
- `terraform_version: "~1.5"`: Installs Terraform 1.5.x
- `cli_config_credentials_token`: Configures Terraform with our cloud token from GitHub secrets

We then check Terraform formatting:

```yaml          
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
```

This step:
- Runs the `terraform fmt` command to ensure code is properly formatted
- `-check`: Fails if files aren't formatted correctly rather than changing them
- `-recursive`: Checks all Terraform files in all subdirectories

Next, we initialize Terraform:

```yaml        
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform/synthetics
```

This step:
- Runs `terraform init` to download providers and set up the backend
- `working-directory: ./main`: Changes to the main directory before running the command

We validate the Terraform configuration:

```yaml        
      - name: Terraform Validate
        run: terraform validate
        working-directory: ./terraform/synthetics
```

This step:
- Runs `terraform validate` to check for syntax errors and internal consistency
- Works in the same directory as the previous step

Finally, we create a Terraform plan:

```yaml        
      - name: Terraform Plan
        run: terraform plan -no-color
        working-directory: ./terraform/synthetics
        env:
          TF_VAR_grafana_service_token: ${{ secrets.GRAFANA_SERVICE_TOKEN }}
          TF_VAR_sm_access_token: ${{ secrets.SM_ACCESS_TOKEN }}
```

This step:
- Runs `terraform plan` to show what changes would be made
- `-no-color`: Removes color codes which can interfere with GitHub's display
- `env`: Sets environment variables that become Terraform variables
- The secrets are securely passed from GitHub to Terraform

Now let's create another workflow file for applying changes:

```bash
touch .github/workflows/on.merge-main.yml
```

5. Add the following content to this file:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  validate-scripts:
    runs-on: ubuntu-latest
    name: Validate K6 Scripts
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - uses: grafana/setup-k6-action@v1
        with:
          browser: true

      - uses: grafana/run-k6-action@v1
        with:
          path: |
            ./scripts/*.js

  terraform-apply:
    runs-on: ubuntu-latest
    name: Apply Terraform Changes
    needs: validate-scripts
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.5"
          cli_config_credentials_token: ${{ secrets.TF_STATE_TOKEN }}
          
      - name: Terraform Init
        run: terraform init
        working-directory: ./main
          
      - name: Terraform Plan
        run: terraform plan -no-color -out=tfplan
        working-directory: ./main
        env:
          TF_VAR_grafana_service_token: ${{ secrets.GRAFANA_SERVICE_TOKEN }}
          TF_VAR_sm_access_token: ${{ secrets.SM_ACCESS_TOKEN }}
          
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        working-directory: ./main
        env:
          TF_VAR_grafana_service_token: ${{ secrets.GRAFANA_SERVICE_TOKEN }}
          TF_VAR_sm_access_token: ${{ secrets.SM_ACCESS_TOKEN }}
```

This workflow runs whenever changes are pushed to the `main` branch (typically after a pull request is merged) and automatically applies the Terraform changes. We run the test again, since merge queues and rebases could brake existing tests.

### Step 4: Create a .gitignore File

Create a `.gitignore` file to exclude sensitive files:

```
# .gitignore
# Ignore secrets and Terraform state
secrets.auto.tfvars
terraform/synthetics/.terraform/
*.tfstate
*.tfstate.*
```

### Step 5: Commit and Push Your GitHub Actions Workflow

Commit your GitHub Actions workflow and push it to the repository:

```bash
git add .github/ .gitignore
git commit -m "Add GitHub Actions workflow"
git push
```

### Step 6: Test the Workflow

To test the workflow:
1. Create a new branch
2. Make a change to one of your Terraform files
3. Push the branch and create a pull request
4. Observe how GitHub Actions runs the Terraform plan
5. Merge the pull request and see how it automatically applies the changes

## Best Practices for Terraform and Grafana Synthetics

### Organizing Your Terraform Code
- Use modules for reusable check configurations
- Separate checks by environment (prod, staging, etc.)
- Use consistent naming conventions

### Managing Secrets
- Never commit secrets to version control
- Use environment variables or a secrets manager
- Rotate tokens regularly

### Deployment Strategies
- Use pull requests for all changes
- Implement mandatory code reviews
- Test changes in a staging environment first

### Monitoring Your Monitoring
- Set up alerts for failed synthetic checks
- Monitor the GitHub Actions workflow itself
- Have a fallback plan if automation fails

## Advanced Topics

### Dynamic Check Generation
For large-scale monitoring, you might want to generate checks dynamically:

```terraform
locals {
  apis = [
    { name = "User API", url = "https://api.example.com/users/health" },
    { name = "Order API", url = "https://api.example.com/orders/health" },
    { name = "Payment API", url = "https://api.example.com/payments/health" }
  ]
}

resource "grafana_synthetic_monitoring_check" "api_checks" {
  for_each  = { for api in local.apis : api.name => api }
  
  name      = "${each.value.name} Health Check"
  target    = each.value.url
  job       = replace(lower(each.value.name), " ", "_")
  enabled   = true
  frequency = var.check_frequency
  timeout   = 3000
  
  probes    = var.probe_locations
  
  settings {
    http {
      method = "GET"
      valid_status_codes = [200]
    }
  }
}
```

### Importing Existing Checks
If you already have checks created manually, you can import them into Terraform:

```bash
terraform import grafana_synthetic_monitoring_check.existing_check check_id
```

## Q&A and Wrap-up (10 minutes)
- Review key concepts
- Address questions
- Share best practices and common pitfalls
- Preview the next session

## Further Reading
- [Grafana Terraform Provider Documentation](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
