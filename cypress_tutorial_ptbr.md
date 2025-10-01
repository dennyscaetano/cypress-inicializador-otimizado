# Instruções para escrever testes Cypress

Este arquivo descreve como os testes Cypress são escritos no contexto deste projeto e está dividido em diferentes tópicos, desde a estrutura do projeto até boas práticas.

## Papel

Você é um especialista em automação de testes web usando Cypress + JavaScript.

## Estrutura de Arquivos e Pastas

Usamos a estrutura padrão do Cypress, com pequenas modificações, como specs divididas por feature e tasks dentro do diretório de support.

```
cypress/
  ├── fixtures/                    # Arquivos de dados de teste (JSON, txt, etc.)
  │   └── example.json             # Arquivo de fixture de exemplo
  ├── e2e/                         # Specs de teste end-to-end, organizados por feature
  │   ├── login/                   # Specs da feature Login
  │   │   └── login.cy.js          # Arquivo de teste de Login
  │   ├── dashboard/               # Specs da feature Dashboard
  │   │   └── dashboard.cy.js      # Arquivo de teste do Dashboard
  │   └── settings/                # Specs da feature Settings
  │       └── settings.cy.js       # Arquivo de teste de Settings
  └── support/                     # Utilitários de suporte e comandos customizados
      ├── tasks/                   # Tasks customizadas para plugins e código Node.js
      │   └── index.js             # Definições das tasks
      ├── commands.js              # Comandos Cypress customizados
      └── e2e.js                   # Configuração global para testes e2e
cypress.config.js                  # Arquivo de configuração do Cypress
cypress.env.example.json           # Arquivo de exemplo de variáveis de ambiente
cypress.env.json                   # Variáveis de ambiente específicas do projeto (não versionadas)
```

## Boas Práticas

Abaixo descrevemos as boas práticas usadas neste projeto Cypress.

### Hooks

Para evitar passos repetitivos dentro dos arquivos `cypress/e2e/**/*.cy.js`, usamos o hook `beforeEach`.

```javascript
// cypress/e2e/settings/settings.cy.js

describe("Settings", () => {
  beforeEach(() => {
    cy.login(); // Faz login primeiro usando um comando customizado
  });

  it("acessa a página de configurações", () => {
    // Já logado, continua realizando o que o teste precisa
  });

  it("faz outra coisa", () => {
    // Já logado, continua realizando o que o teste precisa
  });
});
```

#### before, after e afterEach

Evitamos o hook `before` para garantir que testes dentro do mesmo arquivo possam ser executados independentemente.
Não usamos os hooks `after` e `afterEach` para evitar lixo deixado caso o Cypress trave e não execute esses hooks. Em vez disso, limpamos primeiro usando o `beforeEach`.

### Uso de cy.session

Para cada caso de teste que exige login como pré-condição, usamos o comando customizado `cy.sessionLogin()`.

Importante: A exceção desta regra são os testes dentro do arquivo `cypress/e2e/login/login.cy.js`, onde não queremos usar uma sessão em cache.

Exemplo de implementação:

```javascript
Cypress.Commands.add(
  "sessionLogin",
  (username = Cypress.env("USERNAME"), password = Cypress.env("PASSWORD")) => {
    const setup = () => {
      cy.visit("users/sign_in");

      cy.get('[data-qa-selector="login_field"]').type(username);
      cy.get('[data-qa-selector="password_field"]').type(password, { log: false });
      cy.get('[data-qa-selector="sign_in_button"]').click();

      cy.get(".qa-user-avatar").should("exist");
    };

    const validate = () => {
      cy.visit("");
      cy.location("pathname", { timeout: 1000 }).should("not.eq", "/users/sign_in");
    };

    const options = {
      cacheAcrossSpecs: true,
      validate,
    };

    cy.session(user, setup, options);
  }
);
```

### baseUrl

Sempre definimos o `baseUrl` no arquivo `cypress.config.js` para que os testes possam rodar em diferentes ambientes simplesmente sobrescrevendo via argumento de linha de comando.

```
cypress run --config baseUrl=https://staging.example.com
```

### apiUrl

Sempre definimos `apiUrl` como variável de ambiente no arquivo `cypress.config.js` para possibilitar testes em diferentes ambientes.

```
cypress run --env apiUrl=https://api.staging.example.com
```

### cy.contains

Exemplo de uso correto:

```javascript
cy.contains("button", "Enviar"); // Seletor genérico + conteúdo do elemento
```

Exemplos incorretos:

```javascript
cy.contains("Enviar"); // Muito genérico
cy.get("button").contains("Enviar"); // Encadeamento desnecessário
cy.get("button:contains(Enviar)"); // Complexo e depende do jQuery
```

### Estratégia de Seletores

Regras principais:
- Seletores devem ser resistentes a mudanças de UI
- Devem revelar intenção, não detalhes de implementação
- Devem ser consistentes em todo o projeto
- Devem ser o mais simples possível

Seletores recomendados:

```javascript
cy.get('[data-testid="shopping-cart"]'); // Usar data-testid se existir
cy.get('[aria-label="Next Page"]'); // Usar propriedades de acessibilidade se data-testid não existir
cy.get('input[placeholder="Search emojis..."]'); // Seletores descritivos se nada acima existir
cy.get("#avatar"); // Usar id como último recurso
```

Evitar:
- Classes genéricas (.btn)
- Classes dinâmicas (.Messenger_openButton_OgKIA)
- Seletores genéricos com índices, first ou last
- Seletores longos e difíceis de ler
- XPATH

### cy.request e cy.wait('alias') com .then()

Exemplo correto de `cy.request().then()`:

```javascript
cy.request("GET", "https://api.example.com").then(({ body, status }) => {
  expect(status).to.equal(200);
  expect(body.someProperty).should.exist;
});
```

Exemplo incorreto:

```javascript
cy.request("GET", "https://api.example.com").then((response) => {
  expect(response.status).to.equal(200);
  expect(response.body.someProperty).should.exist;
});
```

Exemplo correto de `cy.wait('alias').then()`:

```javascript
cy.intercept("GET", "https://api.example.com").as("alias");

cy.login();

cy.wait("alias").then(({ status }) => {
  expect(status).to.equal(200);
});
```

Exemplo incorreto:

```javascript
cy.wait("alias").then((response) => {
  expect(response.status).to.equal(200);
});
```

### Dados Sensíveis

Não versionar dados sensíveis. Devem ser definidos como variáveis de ambiente prefixadas por `CYPRESS_` ou no arquivo `cypress.env.json` não versionado.

Exemplo correto:

```javascript
cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD"), { log: false });
```

Exemplos incorretos:

```javascript
cy.get('input[data-testid="password"]').type("dados-sensiveis-hardcoded");
cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD")); // Vazamento no log
```

### Encadeamento desnecessário

Não é necessário usar `.should('exist').and('be.visible')`, pois um elemento visível já existe no DOM.

Exemplo correto:

```javascript
cy.get(".avatar").should("be.visible");
```

### Trabalhando com .last()

Certifique-se de que o número correto de elementos está visível antes de usar `.last()`.

Exemplo correto:

```javascript
cy.get("ul li")
  .should("have.length", 10)
  .last()
  .should("have.text", "Buy Milk");
```

### AAA (Arrange, Act, Assert)

Separar cada etapa com uma linha em branco.

Exemplo:

```javascript
describe("Login", () => {
  it("loga com sucesso", () => {
    // Arrange
    cy.visit("/login");

    // Act
    cy.get('input[data-testid="username"]').type(Cypress.env("USERNAME"));
    cy.get('input[data-testid="password"]').type(Cypress.env("PASSWORD"), { log: false });
    cy.contains("button", "Login").click();

    // Assert
    cy.url().should("be.equal", "https://example.com/dashboard");
    cy.contains("h1", "Bem-vindo ao Dashboard").should("be.visible");
  });
});
```

### Assertions .should('be.visible') vs .should('exist')

Sempre usar `.should('be.visible')` se o elemento deve estar visível.
`.should('exist')` sozinho não garante que o elemento é visível.

### Negative Assertions

Sempre executar uma asserção positiva antes da negativa.

### context

Use `context()` para dividir sub-features dentro de uma feature.

### Condições em testes

Evitar condições em testes, exceto em casos específicos, como validação de respostas de API opcionais ou testes em diferentes viewports.
Testes devem ser determinísticos.

### cy.wait(Number)

Proibido o uso de números fixos no `cy.wait()`. Sempre usar intercepts com alias.

### Configuração Cypress sem support ou fixtures

```javascript
const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    fixturesFolder: false,
    supportFile: false,
  },
});
```

### Imports de pacotes internos vs externos

- Importar pacotes externos primeiro
- Deixar linha em branco entre externos e internos
- Importar em ordem alfabética

### Indentação

Usar 2 espaços de indentação.

### Scripts npm

Não é necessário usar `npx` dentro dos scripts npm.

Exemplo correto:

```json
"scripts": {
  "cy:open": "cypress open",
  "test": "cypress run"
}
```

Exemplo incorreto:

```json
"scripts": {
  "cy:open": "npx cypress open",
  "test": "npx cypress run"
}
```

