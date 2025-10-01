# Cria o diretório do projeto e acessa ele
mkdir workspaces/$1
cd workspaces/$1
# Inicializa o git e o .gitignore
git init
touch .gitignore
echo ".DS_Store\ncypress.env.json\ncypress/downloads/\ncypress/screenshots/\ncypress/videos/\nnode_modules/" > .gitignore
# Cria um arquivo readme a ser definido
touch README.md
echo "# $1\n\nA definir." > README.md
# Inicializa o npm
npm init -y
# Instala o Cypress (se a versão for fornecida, será instalada, caso contrário, a versão mais recente é instalada)
if [ "$2" ]; then
  npm i cypress@"$2" -D
else
  npm i cypress -D
fi
# Cria os arquivos cypress.env.json e cypress.env.example.json com objetos vazios como padrão
touch cypress.env.json
echo "{}" > cypress.env.json
touch cypress.env.example.json
echo "{}" > cypress.env.example.json
# Cria o arquivo cypress.config.js com uma configuração básica para testes e2e
cat > cypress.config.js << 'EOF'
const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    fixturesFolder: false,
    supportFile: false,
  },
})
EOF
# Cria um arquivo de teste de exemplo apenas com o esqueleto da suíte de testes
mkdir cypress/
mkdir cypress/e2e/
cat > cypress/e2e/spec.cy.js << 'EOF'
describe('Suíte de Testes de Exemplo', () => {
  beforeEach(() => {
    // cy.visit('url-aqui')
  })

  it('funciona', () => {
    // adicione a lógica do teste aqui
  })
})
EOF
# Versiona e comita todos os arquivos e diretórios
git add .
git commit -m "Cria projeto cypress"
# Abre o projeto no VSCode
code .