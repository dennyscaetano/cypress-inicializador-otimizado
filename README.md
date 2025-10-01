# cyinicializador

Este projeto oferece um único script shell que inicializa rapidamente um projeto de automação de testes [Cypress](https://cypress.io) do zero.

> **Nota:** Este script funciona apenas em sistemas operacionais baseados em Unix, como Linux e OSX.

## Uso

1. Baixe o arquivo [`cyinicializador.sh`](./cyinicializador.sh) e mova-o para o seu diretório raiz

2. No diretório raiz, execute `./cyinicializador.sh nome-do-projeto-que-voce-quer-criar` para criar um projeto Cypress do zero (talvez seja necessário primeiro dar permissão de execução ao arquivo `cyinicializador.sh`)
  2.1. Alternativamente, você pode executar `./cyinicializador.sh nome-do-seu-projeto-aqui x.x.x` (onde `x.x.x` é a versão específica do Cypress que você deseja instalar). Caso contrário, a versão mais recente é instalada.

3. Após a execução do script, acesse o diretório recém-criado e execute `npx cypress open` para abrir a aplicação Cypress.

## O que o `cyinicializador.sh` faz?

Para entender exatamente o que ele faz, leia os comentários no arquivo [`cyinicializador.sh`](./cyinicializador.sh).