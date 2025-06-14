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
1. Creates a new user account
2. Logs in with the created credentials
3. Performs a series of API actions
4. Verifies the results
5. Cleans up and logs out

You can run the test at each step using:

```bash
docker run --rm -i grafana/k6 run - <scripts/http.js
```

### Step 1: Setting up your script file

Empty the file called `http.js` in the `scripts` directory. We'll create an more advanced script in this assignment.

Start with importing the required libraries:

```javascript
import {check, fail} from "k6";
import http from "k6/http";
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
```

In this step, we're importing three essential components:
- `check` and `fail` from k6 for assertions and error handling
- `http` module for making API requests
- Utility functions `randomString` and `randomIntBetween` for generating test data

These imports give us the core functionality we need to our user journey tests.

### Step 2: Create the main test function

Add the default export function that will contain our test steps:

```javascript
export default function() {
  // Our user journey steps will go here
}
```

This default function is the entry point for k6. When your test runs, k6 will execute this function for each virtual user. All our journey steps will be contained within this function, ensuring they run in the correct sequence.

### Step 3: Generate dynamic user information

Inside the function, add code to generate random user credentials:

```javascript
// User info
const first_name = randomString(10);
const last_name = randomString(10);
const email = `${first_name}.${last_name}@test.com`; 
const password = randomString(10);
```

This step demonstrates an important best practice in user journey testing - using dynamic data. By generating random values for each test run:

1. We avoid collisions between concurrent test executions
2. We prevent test data buildup in the application database
3. We ensure our tests can verify the system works with a variety of inputs, not just hardcoded values

The email format combines first and last name, creating a recognizable pattern while still ensuring uniqueness.

### Step 4: Implement user registration

Add the first step to register a new user:

```javascript
// STEP 1: Register a new user
let response = http.post("https://test-api.k6.io/user/register/", {
    first_name,
    last_name,
    username: email,
    email,
    password
});

check(response, {
    '1. User registration': (r) => r.status === 201,
}) || fail(`User registration failed with ${response.status}`);
```

In this critical first step of our user journey, we're:

1. **Making a POST Request**: We send a POST request to the registration endpoint with our dynamically generated user information.

2. **Submitting Form Data**: We provide all required fields for creating a new user account: first name, last name, username (using the email), email address, and password.

3. **Validating Success**: We use the `check` function to verify the response status code is 201 (Created), which indicates successful user creation.

4. **Implementing Error Handling**: If the check fails, we use the `fail` function to abort the test with a descriptive error message that includes the actual status code. This helps with troubleshooting when tests fail.

This is a proper API interaction patterns and error handling. The registration is a prerequisite for all following steps in our journey - if a user can't register, there's no point continuing with the test.

If users cannot sign up, this is very bad for our company!

![Login authentication flow](./images/login.jpg)

### Step 5: Implement user authentication

Add code to log in with the newly created user:

```javascript
// STEP 2: Authenticate
response = http.post("https://test-api.k6.io/auth/cookie/login/", { username:email, password });

check(response, {
    "2a. login successful": (r) => r.status === 200,
    "2b. user name is correct": (r) => r.json('first_name') === first_name,
    "2c. user email is correct": (r) => r.json('email') === email
});
```

In this authentication step, we're:

1. Sending the credentials we created in the previous step to the login endpoint
2. Using multiple checks to validate not just the HTTP status code, but also the content of the response
3. Verifying that the system correctly associates our login with the user profile we created

Here we show that the authentication system is working and we can login with our new user!

### Step 6: Create a crocodile

Add code to create a new crocodile in the system:

```javascript
// STEP 3: Create a "crocodile"
const name = randomString(10);
const sex = ['M','F'][randomIntBetween(0,1)];
const date_of_birth = new Date().toISOString().split('T')[0];

response = http.post("https://test-api.k6.io/my/crocodiles/",{name, sex, date_of_birth});

const id = parseInt(response.json('id'));
check(response, {
    "3a. Crocodile created and has and id": (r) => r.status === 201 && id && id > 0,
    "3b. Crocodile name is correct": (r) => r.json('name') === name,
}) || fail(`Crocodile creation failed with status ${response.status}`);
```

Here, we're interacting with a different API endpoint to create a new resource (a "crocodile"). We're testing the ability to:

- Work with multiple API endpoints
- Handle different request/response structures
- Chain actions together (register -> login -> create object)

### Step 7: Delete the created object

Add code to clean up by deleting the created object:

```javascript
// STEP 4: Delete the "crocodile"
// (The http.url helper will group distinct URLs together in the metrics)
response = http.del(http.url`https://test-api.k6.io/my/crocodiles/${id}/`);
check(response, {
    "4a. Crocodile was deleted": (r) => r.status === 204
}) 
```

Cleanup steps are crucial in tests that modify data. Here we're:

- Using the HTTP DELETE method to remove the object we created
- Verifying the deletion was successful with a 204 No Content status check

![Cleanup](./images/cleanup.jpg)

### Step 8: Implement logout

Finally, add code to log out:

```javascript
// STEP 5: Logout
response = http.post(`https://test-api.k6.io/auth/cookie/logout/`);

check(response, {
    "5a. Logout successful": (r) => r.status === 200
});
```

Logging out ensures our test user session is properly closed. This step is especially important in applications where session management is critical.

### Complete Script

Your final script should look like this:

```javascript
import {check, fail} from "k6";
import http from "k6/http";
import { randomString, randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export default function() {

    // User info
    const first_name = randomString(10);
    const last_name = randomString(10);
    const email = `${first_name}.${last_name}@test.com`; 
    const password = randomString(10);

    // STEP 1: Register a new user
    let response = http.post("https://test-api.k6.io/user/register/", {
        first_name,
        last_name,
        username: email,
        email,
        password
    });

    check(response, {
        '1. User registration': (r) => r.status === 201,
    }) || fail(`User registration failed with ${response.status}`);

    // STEP 2: Authenticate
    response = http.post("https://test-api.k6.io/auth/cookie/login/", { username:email, password });

    check(response, {
        "2a. login successful": (r) => r.status === 200,
        "2b. user name is correct": (r) => r.json('first_name') === first_name,
        "2c. user email is correct": (r) => r.json('email') === email
    });

    // STEP 3: Create a "crocodile" object
    const name = randomString(10);
    const sex = ['M','F'][randomIntBetween(0,1)];
    const date_of_birth = new Date().toISOString().split('T')[0];

    response = http.post("https://test-api.k6.io/my/crocodiles/",{name, sex, date_of_birth});

    const id = parseInt(response.json('id'));
    check(response, {
        "3a. Crocodile created and has and id": (r) => r.status === 201 && id && id > 0,
        "3b. Crocodile name is correct": (r) => r.json('name') === name,
    )} || fail(`Crocodile creation failed with status ${response.status}`);

    // STEP 4: Delete the "crocodile"
    // (The http.url helper will group distinct URLs together in the metrics)
    response = http.del(http.url`https://test-api.k6.io/my/crocodiles/${id}/`);
    check(response, {
        "4a. Crocodile was deleted": (r) => r.status === 204
    }) 

    // STEP 5: Logout
    response = http.post(`https://test-api.k6.io/auth/cookie/logout/`);

    check(response, {
        "5a. Logout successful": (r) => r.status === 200
    });
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
import { browser } from 'k6/browser';
import { check } from 'k6';

export const options = {
  scenarios: {
    ui: {
      executor: 'shared-iterations',
      options: {
        browser: {
          type: 'chromium',
        },
      },
    },
  },
  thresholds: {
    checks: ['rate==1.0'],
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
await page.goto("https://test.k6.io/my_messages.php");
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
import { browser } from 'k6/browser';
import { check } from 'k6';

export const options = {
  scenarios: {
    ui: {
      executor: 'shared-iterations',
      options: {
        browser: {
          type: 'chromium',
        },
      },
    },
  },
  thresholds: {
    checks: ['rate==1.0'],
  },
};

export default async function () {
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // STEP 1: Navigate to login page
    await page.goto("https://test.k6.io/my_messages.php");

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
      header: async (locator) => (await locator.textContent()) == "Welcome, admin!",
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
