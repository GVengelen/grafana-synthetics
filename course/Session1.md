# Session 1: Foundations and Setup

## Introduction to Synthetics
Synthetics are automated scripts that simulate user interactions with your applications and APIs. They help you proactively detect issues before your users do.

## Understanding the Observability Gap and the Role of Synthetics
The observability gap is the difference between what your monitoring tools can see and what your users actually experience. Synthetics bridge this gap by simulating real user journeys and API calls, providing visibility into the end-user experience.

## The Business Case for Proactive Monitoring
- Early detection of outages and performance issues
- Improved user satisfaction and reduced downtime
- Data-driven insights for continuous improvement
- SLA insights

## Setting Up Your Local Environment
### Prerequisites
- Node.js (v16+ recommended)
- k6 (for local test execution)
- Terraform (for infrastructure as code)
- Git (for version control)
- A Grafana Cloud account

### Steps
1. Clone the course repository:
   ```sh
   git clone <your-repo-url>
   cd grafana_synthetics
   ```
2. Install k6:
   - On macOS:
     ```sh
     brew install k6
     ```
   - On Windows/Linux: See [k6 installation docs](https://grafana.com/docs/k6/latest/set-up/install-k6/#windows).
3. Install Terraform:
   - On macOS:
     ```sh
     brew tap hashicorp/tap
     brew install hashicorp/tap/terraform
     ```
   - On Windows/Linux: See [Terraform installation docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
4. Configure your environment:
   - Copy the example secrets file and fill in your Grafana Cloud credentials:
     ```sh
     cp envs/dev/secrets.auto.example.tfvars envs/dev/secrets.auto.tfvars
     ```
   - Edit `envs/dev/secrets.auto.tfvars` with your Grafana Cloud API key and stack details.

## Creating Your First k6 Test
Create a file named `http.js` in the `scripts/` directory with the following content:

```js
import { check } from 'k6'
import http from 'k6/http'

export default function main() {
  const res = http.get('http://test.k6.io/');
  // console.log will be represented as logs in Loki
  console.log('got a response')
  check(res, {
    'is status 200': (r) => r.status === 200,
  });
}
```

Run your test locally:
```sh
docker run --rm -i grafana/k6 run - <scripts/http.js
```
