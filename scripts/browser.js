import { browser } from "k6/browser";
import { check } from "https://jslib.k6.io/k6-utils/1.5.0/index.js";
import { sleep } from "k6";

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
    await page.goto("https://quickpizza.grafana.com//my_messages.php");

    await page.locator('input[name="login"]').type("admin");
    await page.locator('input[name="password"]').type("123");
    await sleep(15);

    await Promise.all([
      page.waitForNavigation(),
      page.locator('input[type="submit"]').click(),
    ]);

    await check(page.locator("h2"), {
      header: async (locator) =>
        (await locator.textContent()) == "Welcome, admin!",
    });
  } finally {
    await page.close();
  }
}
