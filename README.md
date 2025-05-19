# grafana_synthetics Terraform Project

## Structure

- `main/` – Main Terraform configuration (resources, providers, variables, outputs, versions)
- `modules/` – For reusable Terraform modules (optional, can be empty)
- `envs/dev/secrets.auto.tfvars` – Environment-specific secrets and variables
- `.gitignore` – Ignore state, secrets, and local files
- `README.md` – Project documentation

## Usage

1. Copy `main/secrets.auto.tfvars.example` to `envs/dev/secrets.auto.tfvars` and fill in your real values.
2. Change to the `main/` directory:
   ```sh
   cd main
   ```
3. Run Terraform commands, specifying the environment variable file:
   ```sh
   terraform init
   terraform plan -var-file=../envs/dev/secrets.auto.tfvars
   terraform apply -var-file=../envs/dev/secrets.auto.tfvars
   ```

## Extending
- Place reusable code in `modules/` (create if needed).
- For multiple environments, add more folders under `envs/` (e.g., `envs/prod/`).

## Security
- Never commit secrets or state files.
- Review `.gitignore` regularly.
