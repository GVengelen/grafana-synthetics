# Session 2: User Journey Simulation (90 minutes)

## Introduction

User journey simulation is a critical aspect of synthetic monitoring that allows you to test your application's functionality from an end-user perspective. In this session, we'll explore how to create effective user journey scripts that mimic real user behavior.

### Why User Journey Simulation Matters

Understanding and monitoring user journeys is crucial for several reasons:

- **Early Problem Detection**: By simulating how users interact with your application, you can identify issues before real users encounter them, reducing potential revenue loss and customer frustration.
- **End-to-End Validation**: Individual API endpoints might work perfectly in isolation, but fail when used together in a sequence that mirrors real user behavior.
- **Business Continuity**: User journeys typically represent critical business processes - if a payment flow or registration process breaks, it directly impacts your bottom line.
- **User Experience Insights**: Monitoring complete journeys provides visibility into the actual experience users have with your application, not just isolated components.
- **Cross-functional Alignment**: User journeys create a shared understanding between development, operations, and business teams about how the application should work.

## Understanding User Journey Scripts

- User journey scripts simulate real-world user interactions with your application
- Key components:
  - Authentication flows
  - Form submissions
  - Navigation paths
  - Critical user actions (e.g., purchases, data creation)
  - Logout processes
- Two primary approaches:
  - API-based checks (testing the back-end functionality)
  - Browser-based checks (testing the full UI/UX experience)

### The Anatomy of a User Journey

A well-designed user journey script typically follows this pattern:

1. **Setup Phase**: Preparing the test environment, generating test data
2. **Authentication**: Logging in or establishing session credentials(When applicable)
3. **Core Actions**: Performing the primary business operations (purchases, form submissions, etc.)
4. **Validation**: Confirming the expected outcomes at each step
5. **Cleanup**: Restoring the system to its original state (deleting test data, logging out)

This structure ensures tests are reliable, repeatable, and don't leave behind test artifacts that could affect future test runs.

## Browser-Based Monitoring vs API Checks

### API Checks

- **Pros:**
  - Faster execution
  - Lower resource requirements
  - More stable (fewer moving parts)
  - Ideal for backend service monitoring
- **Cons:**
  - Doesn't test the UI/frontend
  - Can't detect client-side JavaScript issues
  - Misses visual rendering problems

### Browser-Based Monitoring

- **Pros:**
  - Tests the entire user experience
  - Catches frontend issues (JavaScript, CSS, rendering)
  - Validates end-to-end functionality
  - More closely mirrors actual user behavior
- **Cons:**
  - Slower execution time
  - More resource-intensive
  - More complex to set up and maintain
  - More prone to false positives(brittle and flaky)

### When to Use Each Approach

- **Use API Checks When**:
  - You need to monitor core backend services
  - Performance and reliability are top priorities
  - You want to test microservices independently
  - You need higher frequency checks (every minute)
- **Use Browser Checks When**:
  - Frontend experience is critical to your business
  - You need to validate JavaScript functionality
  - You want to measure real user experience metrics
  - You need to test complex UI interactions

Ideally, your strategy employs both approaches, with API checks running more frequently and browser checks providing deeper validation at longer intervals.

## Creating Multi-Step User Simulations (15 minutes)

1. **Map the critical user journey**

   - Identify the most important flows for your business
   - Focus on revenue-generating paths first
   - Consider most common user interactions

2. **Break down the journey into steps**

   - Start with authentication if applicable
   - Include key interactions and validations
   - End with clean-up steps like logout or deletion

3. **Implement checks and assertions**

   - Validate each step completion
   - Check for expected content/elements
   - Set appropriate timeouts and waiting strategies

4. **Handle dependencies between steps**
   - Pass data between steps (IDs, tokens, etc.)
   - Ensure proper sequence of operations
   - Implement proper error handling

### Planning for Resilient User Journeys

When designing user journeys, consider:

- **Stateful vs. Stateless**: How will you manage state between steps?
- **Idempotency**: Can your test be run multiple times without side effects?
- **Isolation**: Will concurrent test runs interfere with each other?
- **Rollback Strategies**: How will you clean up if a test fails mid-journey?
- **Data Dependencies**: What test data needs to exist or be created?

Answering these questions upfront leads to more robust and maintainable test scripts.

## Advanced Scripting Techniques

To be able to create your test script it's important to keep in mind that good tests implement certain patterns. Here are some, altough this list might not be exhaustive.

### Dynamic Data Generation

- Generating random test data for uniqueness
- Creating test users on the fly
- Working with timestamps and dates

### Error Handling and Recovery

- Try/catch blocks for error handling
- Conditional flows based on application state
- Proper cleanup even when errors occur

### Test Isolation

- Creating unique test users per run
- Cleaning up created data
- Avoiding shared state between test runs

### Performance Assertions

- Setting response time thresholds
- Measuring critical rendering metrics
- Detecting performance regressions

## Hands-on: Building a Complete User Journey

In this exercise, we'll build a comprehensive user journey that:

1. Load the storefront landing page
2. Create a custom pizza through the API
3. Attempt to rate a pizza without valid credentials
4. Validate the responses returned at every step

You can run the test at each step using:

```bash
docker run --rm -i grafana/k6 run - <scripts/http.js
```

### Step 1: Setting up your script file

Empty the file called `http.js` in the `scripts` directory. We'll create an more advanced script in this assignment.

Start with importing the required libraries:

```javascript
import { group, sleep, check } from "k6";
import http from "k6/http";
```

In this step, we're importing the core building blocks needed for an API journey:

- `group` helps us label related requests so they appear together in k6 output
- `sleep` pauses between iterations to keep the journey realistic
- `check` provides assertions for response validation
- `http` gives us access to the k6 HTTP client

### Step 2: Create the main test function

Add the default export function that will contain our test steps:

```javascript
export default function () {
  let params;
  let resp;
  let url;

  group("Default group", function () {
    // Steps will go here
  });

  sleep(1);
}
```

The default function is executed for every iteration. We predeclare reusable variables for clarity, wrap our steps inside a descriptive group, and add a short pause at the end to avoid hammering the API.

### Step 3: Load the storefront landing page

Add the first step to confirm the website is available:

```javascript
// Step 1: Get the home page
params = {
  headers: {},
  cookies: {},
};

url = http.url`https://quickpizza.grafana.com/`;
resp = http.request("GET", url, null, params);

check(resp, { "status equals 200": (r) => r.status === 200 });
```

This snippet performs a simple GET request against the storefront. We validate that the page responds with a 200 OK status, ensuring the site is reachable before moving deeper into the flow.

### Step 4: Create a custom pizza

The next step uses the pizza builder API with a pre-generated token:

```javascript
// Step 2: Create a pizza
params = {
  headers: {
    authorization: `Token Gck7WTaMAB9NKlM1`,
  },
  cookies: {},
};

url = http.url`https://quickpizza.grafana.com/api/pizza`;
resp = http.request(
  "POST",
  url,
  `{"maxCaloriesPerSlice":1000,"mustBeVegetarian":false,"excludedIngredients":[],"excludedTools":[],"maxNumberOfToppings":5,"minNumberOfToppings":2,"customName":""}`,
  params,
);

check(resp, { "status equals 200": (r) => r.status === 200 });
```

Here we authenticate with an API token, send the pizza preferences as JSON, and assert that the pizza was successfully created. This mirrors how a user might configure a custom pizza through the UI.

### Step 5: Attempt an unauthorized rating

Finish the journey by verifying authorization rules on the ratings endpoint:

```javascript
// Step 3: Rank a pizza
params = {
  headers: {},
  cookies: {},
};

url = http.url`https://quickpizza.grafana.com/api/ratings`;
resp = http.request("POST", url, `{"pizza_id":24596,"stars":5}`, params);

check(resp, { "status equals 401": (r) => r.status === 401 });
```

This negative test posts a rating without credentials and confirms the API rejects the request with a 401 Unauthorized response. Including failure-path checks like this helps verify that access controls are intact.

### Complete Script

Your final script should look like this:

```javascript
import { group, sleep, check } from "k6";
import http from "k6/http";

export default function () {
  let params;
  let resp;
  let url;

  group("Default group", function () {
    // Step 1: Get the home page
    params = {
      headers: {},
      cookies: {},
    };

    url = http.url`https://quickpizza.grafana.com/`;
    resp = http.request("GET", url, null, params);

    check(resp, { "status equals 200": (r) => r.status === 200 });

    // Step 2: Create a pizza
    params = {
      headers: {
        authorization: `Token Gck7WTaMAB9NKlM1`,
      },
      cookies: {},
    };

    url = http.url`https://quickpizza.grafana.com/api/pizza`;
    resp = http.request(
      "POST",
      url,
      `{"maxCaloriesPerSlice":1000,"mustBeVegetarian":false,"excludedIngredients":[],"excludedTools":[],"maxNumberOfToppings":5,"minNumberOfToppings":2,"customName":""}`,
      params,
    );

    check(resp, { "status equals 200": (r) => r.status === 200 });

    // Step 3: Rank a pizza
    params = {
      headers: {},
      cookies: {},
    };

    url = http.url`https://quickpizza.grafana.com/api/ratings`;
    resp = http.request("POST", url, `{"pizza_id":24596,"stars":5}`, params);

    check(resp, { "status equals 401": (r) => r.status === 401 });
  });
  sleep(1);
}
```

Give it a try by running:

```bash
docker run --rm -i grafana/k6 run - <scripts/http.js
```

![Succes](./images/great_succes.jpg)

## Browser-based User Journey Example (10 minutes)

While the previous example showed an API-based user journey, here's how you can create a browser-based user journey. Let's implement a browser-based test that simulates a user logging into a web application.

You can run the test at each step by running:

```bash
docker run --rm -i -v $(pwd):/home/k6/screenshots grafana/k6:master-with-browser run - <scripts/browser.js
```

### Step 1: Setting up the browser test environment

Create a new file `browser.js` in the scripts directory.

First, we need to import the necessary modules and configure our test options:

```javascript
import { browser } from "k6/browser";
import { check } from "https://jslib.k6.io/k6-utils/1.5.0/index.js";

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      options: {
        browser: {
          type: "chromium",
        },
      },
    },
  },
  thresholds: {
    checks: ["rate==1.0"],
  },
};
```

In this setup, we're:

1. **Importing the browser module**: This provides browser automation capabilities in k6
2. **Importing the check function**: For validation, just like in our HTTP test
3. **Configuring test options**:
   - Setting up a scenario named "ui" with the shared-iterations executor
   - Specifying chromium as our browser type
   - Defining a threshold that requires a 100% check success rate

Browser-based tests in k6 use [Playwright](https://playwright.dev/) under the hood, which provides a modern way to automate browsers.

### Step 2: Creating the main test function

Next, we define our main test function with the async keyword, since browser interactions are asynchronous:

```javascript
export default async function () {
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Our browser test steps will go here
  } finally {
    // Cleanup
    await page.close();
  }
}
```

Here we're:

1. **Creating a browser context**: This is like a private browsing session
2. **Opening a new page**: Similar to opening a new tab in a browser
3. **Using try/finally**: This ensures we always close the page even if the test fails
4. **Implementing proper cleanup**: Closing the page when we're done to free resources

This follows the same best practices as our HTTP test by ensuring proper setup and cleanup.

### Step 3: Navigating to the login page

Now we start the actual test steps by navigating to the login page:

```javascript
// STEP 1: Navigate to login page
await page.goto("https://quickpizza.grafana.com/my_messages.php");
```

This simulates a user typing a URL into their browser and navigating to the page. The `await` keyword is important here because we need to wait for the page to load before proceeding.

### Step 4: Locators and filling out the login form

Locators are a key concept in browser automation that allow us to find and interact with specific elements on a webpage. They act as "selectors" that pinpoint exactly which element we want to work with. In browser testing frameworks like Playwright, locators provide powerful ways to:

- Find elements by CSS selectors (like we're using here)
- Find elements by XPath(last resort)
- Find elements by text content(prone to break)
- Find elements by their accessibility attributes
- Chain locators to find elements within other elements

Locators are resilient by design - they'll automatically wait for elements to appear, retry if the DOM changes, and handle element state changes appropriately. This helps create more stable tests compared to directly accessing DOM elements.

You can find locators by using Chrome DevTools and inspecting the html of the page your testing.

In our login form example below, we're using CSS selectors to locate the input fields by their "name" attribute:

```javascript
// STEP 2: Fill login form
await page.locator('input[name="login"]').type("admin");
await page.locator('input[name="password"]').type("123");
```

- **Finding elements by selector**: Using CSS selectors to find the login and password fields
- **Typing text**: Simulating a user typing their credentials
- **Waiting for each action**: The `await` ensures each step completes before the next begins

In this part of the test, we interact with UI elements just like a real user would.

### Step 5: Submitting the form and handling navigation

Now we submit the form and wait for the resulting page navigation:

```javascript
// STEP 3: Submit form and wait for navigation
await Promise.all([
  page.waitForNavigation(),
  page.locator('input[type="submit"]').click(),
]);
```

This is a critical pattern in browser testing where we:

1. **Wait for navigation and click simultaneously**: Using Promise.all ensures we don't miss the navigation event
2. **Click the submit button**: Simulating a user clicking to submit the form
3. **Wait for the page to load**: Ensuring we don't proceed until the new page is ready

This pattern prevents race conditions that can make browser tests flaky.

### Step 6: Verifying successful login

Finally, we verify that the login was successful:

```javascript
// STEP 4: Verify successful login
await check(page.locator("h2"), {
  header: async (locator) => (await locator.textContent()) == "Welcome, admin!",
});
```

Here we're:

1. **Finding the welcome header**: Locating the h2 element that should contain the welcome message
2. **Checking its content**: Verifying that it contains the expected text
3. **Using async/await properly**: Handling the asynchronous nature of browser interaction

This validation proves that not only did the page load, but the login was successful and the application is in the expected state.

### Complete Browser Script

Your complete browser test script should look like this:

```javascript
import { browser } from "k6/browser";
import { check } from "https://jslib.k6.io/k6-utils/1.5.0/index.js";

export const options = {
  scenarios: {
    ui: {
      executor: "shared-iterations",
      options: {
        browser: {
          type: "chromium",
        },
      },
    },
  },
  thresholds: {
    checks: ["rate==1.0"],
  },
};

export default async function () {
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // STEP 1: Navigate to login page
    await page.goto("https://quickpizza.grafana.com/my_messages.php");

    // STEP 2: Fill login form
    await page.locator('input[name="login"]').type("admin");
    await page.locator('input[name="password"]').type("123");

    // STEP 3: Submit form and wait for navigation
    await Promise.all([
      page.waitForNavigation(),
      page.locator('input[type="submit"]').click(),
    ]);

    // STEP 4: Verify successful login
    await check(page.locator("h2"), {
      header: async (locator) =>
        (await locator.textContent()) == "Welcome, admin!",
    });
  } finally {
    // Cleanup
    await page.close();
  }
}
```

You can run this browser test with:

```bash
docker run --rm -i -v $(pwd):/home/k6/screenshots grafana/k6:master-with-browser run - <scripts/browser.js
```

This browser-based test also validates login functionality like our HTTP test, but it does so by interacting with the actual user interface rather than directly with the API. This allows us to verify not just that the backend works, but that the entire user experience functions correctly.

## Further reading

- https://grafana.com/docs/k6/latest/using-k6-browser/recommended-practices/
