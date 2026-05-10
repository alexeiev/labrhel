# Simulado RHCE EX294

Simulado interativo para a prova Red Hat Certified Engineer (RHCE) EX294v9K.

## Como executar

O arquivo `index.html` carrega as questoes dos arquivos `.md` via `fetch()`, por isso precisa de um servidor HTTP local.

```bash
cd Questoes_gimini_img
python3 -m http.server 8080
```

Acesse `http://localhost:8080` no navegador.

## Estrutura dos arquivos

```
Questoes_gimini_img/
├── index.html        # Interface do simulado
├── Questoes_PT.md    # Questoes em Portugues
├── Questoes_EN.md    # Questoes em Ingles
└── README.md
```

## Como adicionar/editar questoes

As questoes ficam nos arquivos `Questoes_PT.md` (portugues) e `Questoes_EN.md` (ingles). O parser do HTML identifica cada questao pelo marcador `## ` (heading nivel 2 do Markdown).

### Formato esperado

```markdown
# Titulo (ignorado pelo parser)

## 1. Titulo da primeira questao
Detalhamento da questao aqui.
Pode ter multiplas linhas.

## 2. Titulo da segunda questao
Detalhamento da segunda questao.
i) Sub-item
ii) Outro sub-item
```

### Regras

1. **Cada questao comeca com `## `** seguido do numero e titulo (ex: `## 5. Instalar pacotes`)
2. **Tudo abaixo do `## ` ate o proximo `## `** e considerado o corpo/detalhamento da questao
3. **A primeira linha** (`# Titulo`) e ignorada pelo parser, serve apenas como cabecalho do documento
4. **Mantenha a numeracao sequencial** para facilitar a organizacao
5. **Edite ambos os arquivos** (`Questoes_PT.md` e `Questoes_EN.md`) para manter as traducoes sincronizadas

### Exemplo: adicionando a questao 18

No arquivo `Questoes_PT.md`, adicione ao final:

```markdown
## 18. Configurar firewall em todos os nos gerenciados
i) Abra a porta 80/tcp para o servico httpd.
ii) Abra a porta 443/tcp para o servico https.
iii) Recarregue o firewall.
iv) O nome do playbook deve ser firewall.yml.
```

No arquivo `Questoes_EN.md`, adicione o equivalente em ingles:

```markdown
## 18. Configure firewall on all managed nodes
i) Open port 80/tcp for the httpd service.
ii) Open port 443/tcp for the https service.
iii) Reload the firewall.
iv) The playbook name should be firewall.yml.
```

Recarregue a pagina no navegador e a questao 18 aparecera automaticamente.

### Removendo uma questao

Basta apagar o bloco `## N. Titulo` e todo o conteudo ate o proximo `## ` em ambos os arquivos. Ajuste a numeracao das questoes seguintes se necessario.
