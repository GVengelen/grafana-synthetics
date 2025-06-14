# Session 1: Foundations and Setup

## Introduction to Synthetics
Synthetics are automated scripts that simulate user interactions with your applications and APIs. They help you proactively detect issues before your users do.

## Understanding the Observability Gap and the Role of Synthetics
The observability gap is the difference between what your monitoring tools can see and what your users actually experience. Synthetics bridge this gap by simulating real user journeys and API calls, providing visibility into the end-user experience.

![image](https://github.com/user-attachments/assets/c6233247-30e9-4b43-85c2-166bc524b4b1)

## The Business Case for Proactive Monitoring
- Early detection of outages and performance issues
- Improved user satisfaction and reduced downtime
- Data-driven insights for continuous improvement
- SLA insights

## Setting Up Your Local Environment
### Prerequisites
- Node.js (v16+ recommended)
- Docker (for running k6 tests)
- Terraform CLI (for infrastructure as code)
- Git (for version control)
- A Grafana Cloud account

### Steps
1. Create your own repository an name it grafana_synthetics
2. Clone the course repository:
   ```sh
   git clone <your-repo-url>
   cd grafana_synthetics
   ```
3. Install Docker:
   - On macOS: Download from [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   - On Windows/Linux: See [Docker installation docs](https://docs.docker.com/get-docker/)
   - Verify installation:
     ```sh
     docker --version
     ```
4. Install Terraform:
   - On macOS:
     ```sh
     brew tap hashicorp/tap
     brew install hashicorp/tap/terraform
     ```
   - On Windows/Linux: See [Terraform installation docs](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
5. Configure your environment:
   - Copy the example secrets file and fill in your Grafana Cloud credentials:
     ```sh
     cp envs/dev/secrets.auto.example.tfvars envs/dev/secrets.auto.tfvars
     ```
   - Edit `envs/dev/secrets.auto.tfvars` with your Grafana Cloud API key and stack details.

## Why k6 Over Traditional HTTP Checks?

When it comes to synthetic monitoring, you have several options including traditional HTTP health checks, dedicated monitoring services, or scriptable solutions like k6. Here's why we choose k6 for our synthetic monitoring strategy:

### Advantages of k6

**1. Enhanced Developer Experience**
- Run the same k6 scripts locally during development and in CI/CD pipelines
- Debug and iterate on tests in your familiar development environment
- No need for separate tooling between local development and production monitoring
- Version control your synthetic tests alongside your application code

**2. Consistency Across Test Types**
- Unified scripting approach for both browser-based and API-based tests
- Same JavaScript syntax and k6 APIs whether you're testing HTTP endpoints or full browser interactions
- Consistent reporting and metrics format across different test types
- Simplified learning curve - one tool, multiple use cases

**3. Advanced Scripting Capabilities**
- Complex test scenarios with conditional logic, loops, and data manipulation
- Multi-step user journeys that mirror real user behavior
- Custom metrics and advanced assertions beyond simple status code checks
- Built-in support for various protocols (HTTP/1.1, HTTP/2, WebSockets, gRPC)
- Parameterization and data-driven testing with external data sources
- Load testing capabilities for performance validation

**4. Better Observability Integration**
- Rich metrics and custom tags for detailed analysis
- Integration with Grafana dashboards for visualization
- Structured logging that integrates with Loki
- Custom metrics that align with your application's business logic

### Potential Drawbacks

**1. Learning Curve**
- Requires JavaScript knowledge for advanced scenarios
- More complex setup compared to simple HTTP ping checks
- Need to understand k6-specific APIs and concepts

**2. Resource Overhead**
- Higher resource consumption compared to lightweight HTTP checks
- Docker containers require more memory and CPU than simple curl commands
- Browser-based tests are particularly resource-intensive

**3. Maintenance Complexity**
- Scripts need maintenance as applications evolve
- More complex debugging when tests fail
- Potential for false positives if scripts aren't well-designed

**4. Overkill for Simple Checks**
- Traditional HTTP checks might be sufficient for basic uptime monitoring
- Additional complexity may not be justified for simple health endpoints

Despite these considerations, k6's flexibility and developer-friendly approach make it an excellent choice for comprehensive synthetic monitoring strategies, especially when you need more than basic uptime checks.

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

Run your test locally using Docker:

**Method 1: Pipe the script to Docker**
```sh
docker run --rm -i grafana/k6 run - <scripts/http.js
```

**Method 2: Mount the scripts directory**
```sh
docker run --rm -v "$PWD/scripts:/scripts" grafana/k6 run /scripts/http.js
```

**Method 3: Run from the scripts directory**
```sh
cd scripts
docker run --rm -v "$PWD:/workspace" -w /workspace grafana/k6 run http.js
```

The Docker approach has several advantages:
- No need to install k6 locally
- Consistent k6 version across different environments
- Easy to integrate into CI/CD pipelines
- Isolated execution environment
