# Instructions for writing Cypress Tests

This file describes how Cypress tests are writting in the context of this project, and it's devived into different topics, from project struture to best practices.

## Role

You're an expert in web test automation using Cypress + JavaScript.

## Files and Folders Structure

We use the default Cypress structure, with small modifications, such as specs devided per feature, and tasks inside the support directory.

```bash
cypress/
  ├── fixtures/                    # Test data files (JSON, txt, etc.)
  │   └── example.json             # Example fixture file
  ├── e2e/                         # End-to-end test specs, organized by feature
  │   ├── login/                   # Login feature specs
  │   │   └── login.cy.js          # Login test file
  │   ├── dashboard/               # Dashboard feature specs
  │   │   └── dashboard.cy.js      # Dashboard test file
  │   └── settings/                # Settings feature specs
  │       └── settings.cy.js       # Settings test file
  └── support/                     # Support utilities and custom commands
      ├── tasks/                   # Custom tasks for plugins and custom node.js code
      │   └── index.js             # Task definitions
      ├── commands.js              # Custom Cypress commands
      └── e2e.js                   # Global setup for e2e tests
cypress.config.js                  # Cypress configuration file
cypress.env.example.json           # Example environment variables file
cypress.env.json                   # Project-specific environment variables (not versioned)

```

## Best Practices

Below we describe the best practices used in this Cypress project.

### Hooks

To avoid repetitive steps inside `cypress/e2e/**/*.cy.js` files, we use the `beforeEach` hook.

Below is an example.

```js
// cypress/e2e/settings/settings.cy.js

describe("Settings", () => {
  beforeEach(() => {
    cy.login(); // Login first using a custom command.
  });

  it("access the settings page", () => {
    // Already logged in, continue doing whatever this test should do.
  });

  it("does something else", () => {
    // Already logged in, continue doing whatever this test should do.
  });
});
```

#### `before`, `after`, and `afterEach`

- We avoid the `before` hook to ensure tests inside the same file can be ran indepdendently.
- We do not use the `after` and `afterEach` hooks to avoid leaving trash behind in case Cypress crashes and never runs such hooks. Instead, we cleanup first using the `beforeEach` hook.

### Usage of `cy.session`

For every test case that requires log in as a pre-condition, we use a `cy.sessionLogin()` custom command.

> **Important:** The exception for the above rule are tests inside the `cypress/e2e/login/login.cy.js` file, where we don't want to use a cached session.

The `cy.sessionLogin` custom command uses Cypress's native `cy.session` command, which caches and restores `cookies`, `localStorage`, and `sessionStorage` (i.e. session data) in order to recreate a consistent browser context between tests.

Below is an example of how the `cy.sessionLogin` command looks like.

```js
Cypress.Commands.add(
  "sessionLogin",
  (username = Cypress.env("USERNAME"), password = Cypress.env("PASSWORD")) => {
    const setup = () => {
      cy.visit("users/sign_in");

      cy.get('[data-qa-selector="login_field"]').type(username);
      cy.get('[data-qa-selector="password_field"]').type(password, {
        log: false,
      });
      cy.get('[data-qa-selector="sign_in_button"]').click();

      cy.get(".qa-user-avatar").should("exist");
    };

    const validate = () => {
      cy.visit("");
      cy.location("pathname", { timeout: 1000 }).should(
        "not.eq",
        "/users/sign_in"
      );
    };

    const options = {
      cacheAcrossSpecs: true,
      validate,
    };

    /**
     * @param user string - the id of the session. If the id changes, a new
     * session is created.
     * @param setup function - the function that creates the session.
     * @param options object - an object to add certain characteristics to the
     * session, such as sharing the cached session across specs (test files),
     * and a way to validate if the session is still valid (validate function).
     * If the session gets invalidated, the setup function runs again to recreate it.
     *
     * For more details, visit https://docs.cypress.io/api/commands/session
     */
    cy.session(user, setup, options);
  }
);
```

### `baseUrl`

We always define the `baseUrl` in the `cypress.config.js` file so tests can run against diffent environments by simply overwriting it via a commnad line argument.

For example:

```bash
cypress run --config baseUrl https://staging.example.com
```

### `apiUrl`

We always define the `apiUrl` as an `env` inside in the `cypress.config.js` file so tests can run against diffent environments by simply overwriting it via a commnad line argument.

For example:

```bash
cypress run --env apiUrl https://api.staging.example.com
```

### `cy.contains`

Below are examples of how we use and how we don't use the `contains` command.

**Good example** 👍

```js
cy.contains("button", "Send"); // Generic selector + element's content that makes it specific.
```

**Bad examples** 👎

```js
cy.contains("Send"); // Too generic

cy.get("button").contains("Send"); // Too many chainings

cy.get("button:contains(Send)"); // Too complex since it depends on JQuery's :contains
```

### Selectors Strategy

First of all:

- Selectors should be resilient to UI changes
- Selectors should reveal intent, not implementation details
- Selectors should be consistent across the entire project
- Selectors should be as simple as possible

**Recommended Selectors Strategy** 👍

The recommended selectors approach is as follows.

```js
// If data-testid or similiar exist, use them.
cy.get('[data-testid="shopping-cart"]');
// If data-testid is not available, use accessibility (A11y) properties such as aria-label for element selection.
cy.get('[aria-label="Next Page"]');
// If none of the above are present, try descriptive selectors
cy.get('input[placeholder="Search emojis..."]');
// Otherwise, use id.
cy.get("#avatar");
```

**Avoid** 👎

- Generic classes (e.g., `.btn`)
- Dynamic classes (e.g., `cy.get('.Messenger_openButton_OgKIA')`)
- Generic selectors with indexes, first, or last (e.g., `cy.get('a').first()` or `cy.get('button').eq(3)`)
- Long and hard-to-read selectors (e.g., `cy.get('div > p > span')`)
- XPATH - DO NOT USE XPATH

### `cy.request` and `cy.wait('alias')` with `.then()`

Below are examples of how we use and how we don't use the `cy.request` and `cy.wait('alias')` commands when chaining them to `.then`.

**`cy.request().then()` good example** 👍

> We always destructure what's needed from a request's response to avoid duplications like `response.status`, or `response.body`.

```js
cy.request("GET", "https://api.example.com").then(({ body, status }) => {
  expect(status).to.equal(200);
  expect(body.someProperty).should.exist;
});
```

**`cy.request` bad example** 👎

```js
cy.request("GET", "https://api.example.com").then((response) => {
  expect(response.status).to.equal(200);
  expect(response.body.someProperty).should.exist;
});
```

**`cy.wait('alias')` good example** 👍

> We always destructure what's needed from an intercepted response to avoid duplications like `response.status`, or `response.body`.

```js
cy.intercept("GET", "https://api.example.com").as("alias");

cy.login();

cy.wait("alias").then(({ status }) => {
  expect(status).to.equal(200);
});

// Continue here.
```

**`cy.wait('alias')` bad example** 👎

```js
cy.intercept("GET", "https://api.example.com").as("alias");

cy.login();

cy.wait("alias").then((response) => {
  expect(response.status).to.equal(200);
});

// Continue here.
```

### Sensitive Data

No sensitive data should be ever versioned, and so, they should be set in environment variables prefixed by `CYPRESS_`, (e.g., `CYPRESS_USERNAME`), or defined inside the not-versioned `cypress.env.json` file.

> Look into the [`cypress.env.example.json`](../cypress.env.example.json) file for an example of how the `cypress.env.json` file should look like.

After that, such data can be retrieved using the `Cypress.env('ENV_HERE')` command.

Finally, we do not leak senstive data in the Cypress command logs. To protect data from leaking, we use the `{ log: false }` option.

**Good example** 👍

```js
cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD"), {
  log: false,
});
```

**Bad examples** 👎

```js
cy.get('input[data-testid="password"]').type("hardcoded-sensitive-data"); // Sensitive data should never be hardcoded.

cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD")); // Although the data come from a protected env, it leaks in the Cypress command log.
```

### Unnecessary chain of commands (e.g., `.should('exist').and('be.visible')`)

It's not necessary to ensure the element exists in the DOM if you will assert that it's visible.

> An element cannot be visible without existing in the DOM.

**Good example** 👍

```js
cy.get(".avatar").should("be.visible");
```

**Bad examples** 👎

```js
cy.get(".avatar").should("exist").and("be.visible");

cy.get(".avatar").should("be.visible").and("exist");
```

### Working with the `.last()` element

When working with the `.last` element, make sure the correct number of elements are visible before getting the last.

This ensures you are selecting the correct element, especially in scenarios where multiple elements with the same selector may render at different times, such as in a dynamic list.

**Good example** 👍

```js
cy.get("ul li")
  // Assert the expected number of elements.
  .should("have.length", 10)
  // All items rendered, now get the last one and make an assertion.
  .last()
  .should("have.text", "Buy Milk");
```

**Bad example** 👎

```js
cy.get("ul li")
  .last() // This may select the wrong element if the list is still rendering.
  .should("have.text", "Buy Milk");
```

### Arrange, Act, Assert

Here, we follow the AAA (Arrange, Act, Assert) pattern for writing tests, and we separate each of them between a blank line.

**Example 1**

```js
describe("Login", () => {
  it("logs in successfully", () => {
    // Arrange
    cy.visit("/login");

    // Act
    cy.get('input[data-testid="username"]').type(Cypress.env("USERNAME"));
    cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD"), {
      log: false,
    });
    cy.contains("button", "Login").click();

    // Assert
    cy.url().should("be.equal", "https://example.com/dashboard");
    cy.contains("h1", "Welcome to the Dashboard").should("be.visible");
  });
});
```

**Example 2 - Many tests with the same arrange steps**

```js
describe("Dashboard", () => {
  beforeEach(() => {
    // Arrange
    cy.sessionLogin();
    cy.visit("/dashboard");
  });

  it("opens the dashboard menu", () => {
    // Act
    cy.get("#dashboard-menu-btn").click();

    // Assert
    cy.get("#dashboard-menu-modal").should("be.visible");
  });

  it("closes the dashboard menu", () => {
    // Act
    cy.get("#dashboard-menu-btn").click();
    cy.get("#dashboard-menu-btn").click();

    // Assert
    cy.get("#dashboard-menu-modal").should("not.exist");
  });
});
```

> If many tests share the same arrange steps, they can go to the `beforeEach` hook.

**Example 3**

Sometimes, we might need intermediate asserts before the final ones to ensure the elements we want to interact with are really there.

```js
describe("Login", () => {
  it("logs in successfully", () => {
    // Arrange
    cy.visit("/login");

    cy.get('input[data-testid="username"]')
      // Assert
      .should("be.visible")
      // Act
      .type(Cypress.env("USERNAME"));
    cy.get('input[data-testid="password"]')
      // Assert
      .should("be.vislble")
      // Act
      .type(Cypress.env("PASSWORD"), {
        log: false,
      });
    cy.contains("button", "Login")
      // Assert
      .should("be.vislble")
      // Act
      .click();

    // Assert
    cy.url().should("be.equal", "https://example.com/dashboard");
    cy.contains("h1", "Welcome to the Dashboard").should("be.visible");
  });
});
```

### The `.should('be.visible')` vs. the `should('exist')` assertions

If an element should be visible in the page, we always assert that using the `.should('be.visible')` assertion.

Only asserting that an element exists in the DOM is not enough since the element might exist but could be hidden by a CSS rule, for example.

### Negative Assertions

We always run a positive assertion before a negative one to avoid tests passing prematurely.

**Good example** 👍

```js
it("deletes a note", () => {
  cy.get(".list-group").contains("My note updated").click();
  cy.contains("Delete").click();

  cy.get(".list-group-item").its("length").should("be.at.least", 1); // Ensure you're in the right place before the negative assertion.
  cy.contains(".list-group-item", "My note").should("not.exist");
});
```

**Bad example** 👎

```js
it("deletes a note", () => {
  cy.get(".list-group").contains("My note updated").click();
  cy.contains("Delete").click();

  cy.get(".list-group:contains(My note updated)").should("not.exist"); // This assertion will happen right after the click, when the app might not have redirected to the correct place where the assertion should happen
});
```

### `context`

When writing tests for a feature that has sub-features, we devide them using the `context` function.

**Good example** 👍

```js
describe("Auth", () => {
  context("Login", () => {
    beforeEach(() => {
      cy.visit("/login");
    });

    // Login tests here
  });

  context("Sign in", () => {
    beforeEach(() => {
      cy.visit("/sign-in");
    });

    // Sign in tests here
  });
});
```

> `context` functions can have their own `beforeEach` hook if needed.

**Bad example** 👎

```js
describe("Auth", () => {
  // Test cases of auth sub-features mixed up all together.

  it("login test sample", () => {});

  it("sign in test sample", () => {});

  it("forgot password test sample", () => {});
});
```

### Conditionals Testing

We discourage conditions in testing code, except in a few exceptions.

Below is an exception example, where we want to validated an API response, and a few fields are optoinal.

```js
it("returns the correct status and body structure on a simple GET request (with default query params.)", () => {
  cy.request("GET", CUSTOMERS_API_URL).as("getCustomers");

  cy.get("@getCustomers").its("status").should("eq", 200);

  cy.get("@getCustomers")
    .its("body")
    .should("have.all.keys", "customers", "pageInfo");
  cy.get("@getCustomers")
    .its("body.customers")
    .each((customer) => {
      expect(customer.id).to.exist.and.be.a("number");
      expect(customer.name).to.exist.and.be.a("string");
      expect(customer.employees).to.exist.and.be.a("number");
      expect(customer.industry).to.exist.and.be.a("string");

      // Since customer.contactInfo can be null, this condition is accpeted. 👍
      if (customer.contactInfo) {
        expect(customer.contactInfo).to.have.all.keys("name", "email");
        expect(customer.contactInfo.name).to.be.a("string");
        expect(customer.contactInfo.email).to.be.a("string");
      }

      // Since customer.address can be null, this condition is accpeted. 👍
      if (customer.address) {
        expect(customer.address).to.have.all.keys(
          "street",
          "city",
          "state",
          "zipCode",
          "country"
        );
        expect(customer.address.street).to.be.a("string");
        expect(customer.address.city).to.be.a("string");
        expect(customer.address.state).to.be.a("string");
        expect(customer.address.zipCode).to.be.a("string");
        expect(customer.address.country).to.be.a("string");
      }
    });

  cy.get("@getCustomers")
    .its("body.pageInfo")
    .should("have.all.keys", "currentPage", "totalPages", "totalCustomers");
  cy.get("@getCustomers")
    .its("body.pageInfo")
    .then(({ currentPage, totalPages, totalCustomers }) => {
      expect(currentPage).to.be.a("number");
      expect(totalPages).to.be.a("number");
      expect(totalCustomers).to.be.a("number");
    });
});
```

And below is another exception, where we control in which viewport tests will run against.

```js
it('logs out', { tags: '@desktop-and-tablet' }, () => {
  cy.visit('/')
  cy.wait('@getNotes')

  if (Cypress.config('viewportWidth') < Cypress.env('viewportWidthBreakpoint')) { // 👍
    cy.get('.navbar-toggle.collapsed')
      .should('be.visible')
      .click() // On smaller viewports, the user must open the menu before clicking Logout
  }

  cy.contains('.nav a', 'Logout').click()

  cy.get('#email').should('be.visible')
})
```

But this isn't allowed: 👎

```js
// This only works if there's 100% guarantee
// body has fully rendered without any pending changes
// to its state
cy.get('body').then(($body) => {
  // synchronously ask for the body's text
  // and do something based on whether it includes
  // another string
  if ($body.text().includes('some string')) {
    // yup found it
    cy.get(...).should(...)
  } else {
    // nope not here
    cy.get(...).should(...)
  }
})
```

> **Tests must be deterministic.
> Each run should produce the same behavior and results.
> If multiple paths exist, write a separate test for each.**

### `cy.wait(Number)` is strictly forbidding (no exception)

Instead of doing something like this: 👎

```js
cy.get(...).type(...)
cy.get(...).type(...)
cy.get(...).click()

cy.wait(3000)

cy.get(...).should('be.visible')
```

Do something like this: 👍

```js
cy.intercept().as('requestThatWillHappenAfterFormSubmit')

cy.get(...).type(...)
cy.get(...).type(...)
cy.get(...).click()

cy.wait('@requestThatWillHappenAfterFormSubmit')

cy.get(...).should('be.visible')
```

### Overwriting Cypress default configs due to non-usage of the `support` and/or `fixtures` folders

When not using the `cypress/fixtures/` or `cypress/support/` files and directories, we udpate the `cypress.config.js` file like below.

```js
const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    fixturesFolder: false, // Do not use fixtures
    supportFile: false, // Do not use support files
  },
});
```

### Imports of internal vs. external packages

To differentiate between internal and external packages, our rule is:

- Import external packages first
- Leave an empty line between the last import of an external package and the beginning of imports of internal ones.
- Following the above rules, import internal and external packages in alphabetical order

### Indentation

We use two spaces of indentation.

This helps with breaking lines when chaining Cypress commands.

For example:

```js
cy.contains("a", "Privacy Policy")
  .should("be.visible")
  .and("have.attr", "target", "_blank");
```

> If we were using four spaces, the chained commands would not align with the `cy` object.

### npm scripts

There's no need to add `npx` inside the npm scripts.

npm already knows where to find the binaries when calling scripts defined inside the `package.json` file, so, `npx` is not needed.

**Good example** 👍

```json
"scripts": {
  "cy:open": "cypress open",
  "test": "cypress run"
},
```

**Bad example** 👎

```json
"scripts": {
  "cy:open": "npx cypress open",
  "test": "npx cypress run"
},
```

---

More to come...
