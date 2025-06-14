# grafana_synthetics Terraform Project

## Table of Contents

- [Session 1: Foundations and Setup](Course/Session1.md)
- [Session 2: User Journey Simulation](Course/Session2.md)
- [Session 3: Deploying your synthetics on Grafana Cloud](Course/Session3.md)
- [Session 4: Performance Monitoring and Metrics](Course/Session4.md)

## Structure

- `terraform/synthetics` – Terraform configuration (resources, providers, variables, outputs, versions)
- `terraform/synthetics/envs/dev/secrets.auto.tfvars` – Environment-specific secrets and variables
- `.gitignore` – Ignore state, secrets, and local files
- `README.md` – Project documentation
- `scripts` - K6 automation scripts

## About this course
This course is created to help engineers setup Synthetic Monitoring in Grafana Cloud. It draws inspiration from blogs from the Grafana Website. Best practices might change over time but at the time of writing I've used the following examples:

- [top-5-user-requested-synthetic-monitoring-alerts-in-grafana-cloud](https://grafana.com/blog/2022/01/11/top-5-user-requested-synthetic-monitoring-alerts-in-grafana-cloud/)
- [grafana-cloud-synthetic-monitoring-all-the-latest-features/](https://grafana.com/blog/2024/05/01/grafana-cloud-synthetic-monitoring-all-the-latest-features/)

Please feel free to open a ticket or PR to improve this repository. I hope you enjoy the sessions and learn something useful!