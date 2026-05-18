# CLAUDE.md — Análise Descritiva PNAD 2015

## Sobre este projeto
**Nome:** analise-descritiva-pnad-2015
**Tipo:** Projeto de análise de dados (primeiro projeto real do portfólio)
**Origem:** Projeto final do curso "Estatística com Python — Frequências e Medidas" (Alura)
**Dataset:** Pesquisa Nacional por Amostra de Domicílios 2015 (PNAD/IBGE)

## Quem sou
Rickelme (RickelmeDSC). Em transição de carreira para Análise de Dados + IA + Automação. Estou no início da jornada — este é meu **primeiro contato real com Pandas, Seaborn e análise estatística aplicada**.

## Fase atual do roadmap
**Fase 1 — Fundamentos (Semanas 2–3)**

Já concluí:
- Python: variáveis, condicionais, loops, funções, estruturas de dados, exceções
- Repositórios: `python-fundamentos`, `jornada-dados-ia`

Em andamento:
- Estatística com Python (frequências e medidas) — projeto final é ESTE notebook
- Próximo: SQLite + Pandas profundo

## Objetivo deste projeto

Construir uma **análise descritiva completa** do dataset PNAD 2015 cobrindo:

1. **Tabela de frequências** por classe de renda (A-E)
2. **Histogramas** das variáveis quantitativas (renda, idade, altura)
3. **Tabela cruzada** sexo × cor
4. **Medidas de tendência central** (média, mediana, moda)
5. **Medidas de dispersão** (variância, desvio padrão, desvio médio absoluto)
6. **Análise segmentada** (renda por sexo/cor, renda por UF, renda por anos de estudo)
7. **Box plots** comparativos
8. **Conclusões escritas** com interpretação dos resultados

Resultado esperado: notebook profissional + README contando a história dos achados (desigualdade de renda no Brasil) + repositório que sirva como peça de portfólio.

## Variáveis do dataset

| Variável | Tipo | Descrição |
|----------|------|-----------|
| Renda | Quantitativa | Rendimento mensal do trabalho principal (R$) |
| Idade | Quantitativa | Idade do morador em anos |
| Altura | Quantitativa | Altura do morador em metros (elaboração própria) |
| UF | Qualitativa | Unidade da Federação (código) |
| Sexo | Qualitativa | 0=Masculino, 1=Feminino |
| Cor | Qualitativa | 0=Indígena, 2=Branca, 4=Preta, 6=Amarela, 8=Parda, 9=Sem declaração |
| Anos de Estudo | Qualitativa ordinal | 1=Sem instrução até 17=Não determinados |

Salário mínimo de 2015: R$ 788,00

## Estrutura do repositório

```
analise-descritiva-pnad-2015/
├── README.md
├── CLAUDE.md
├── .gitignore
├── requirements.txt
├── data/
│   └── dados.csv
├── notebooks/
│   └── analise_descritiva.ipynb
└── images/
    └── (prints dos gráficos principais)
```

## Stack utilizada

- **Python 3.11+**
- **Pandas** — manipulação de DataFrames
- **NumPy** — operações numéricas
- **Seaborn** — visualizações estatísticas
- **Matplotlib** — gráficos base
- **SciPy** — funções estatísticas (percentileofscore, etc.)
- **Jupyter** — notebook interativo

## Regras de código

- **Comentários em português** explicando o raciocínio
- **Markdown rico entre células de código** — não só código solto, mas narrativa
- **Conclusões escritas em prosa** após cada análise (não só números)
- **Gráficos com títulos, labels e cores intencionais** — não usar default cego
- **snake_case** para variáveis e funções
- **DataFrames com nomes descritivos** — `df_renda` em vez de só `df`
- **Não usar `df.head()` sem antes explicar o que está acontecendo**

## Convenções de commit

- `feat: adiciona análise de [tópico]`
- `feat: adiciona tabela de frequência por classe de renda`
- `feat: adiciona histogramas das variáveis quantitativas`
- `docs: atualiza conclusões da seção [X]`
- `style: melhora visualização do gráfico [Y]`
- `fix: corrige cálculo de [Z]`

## Como me ajudar (instruções para o Claude Code)

### Filosofia geral
Este é meu **primeiro projeto real de análise de dados**. Quero aprender Pandas, Seaborn e estatística aplicada construindo este projeto. NÃO quero que você gere o notebook inteiro de uma vez.

### Quando eu pedir ajuda em uma análise

1. **Pergunte primeiro:** "Já tentou? Como pensou em resolver?"
2. **Explique o conceito estatístico** envolvido antes do código (ex: "antes de calcular a moda, lembra que a moda é o valor mais frequente. No Pandas, isso é..."
3. **Mostre o código em partes pequenas**, explicando cada linha
4. **Conecte com o significado real**: o que esse número diz sobre a sociedade brasileira?

### Estilo de explicação
- **Português** sempre
- **Analogias do dia a dia** para conceitos estatísticos
- **Interpretação dos números**, não só cálculo
- **Boas práticas de visualização** (cores, escalas, títulos)
- Mostrar **alternativas** quando houver mais de uma forma de fazer

### Para visualizações
- Sempre sugerir título, label de eixos, cor com propósito
- Explicar **por que** escolher histograma vs barra vs box plot
- Apontar quando uma escala (log, linear) é mais apropriada

### Para conclusões
- Me ajude a **interpretar os números** em contexto social
- Sugira o que destacar e o que omitir
- Aponte quando uma conclusão é forte vs frágil estatisticamente

### Code review
Quando eu pedir review:
- Comece pelo que está bom
- 1-3 melhorias prioritárias
- Explique o **porquê** de cada sugestão
- Se a análise tem viés ou falha estatística, aponte com cuidado

## O que NÃO fazer

- ❌ Não gerar células inteiras do notebook sem eu pedir
- ❌ Não usar bibliotecas além das listadas (não tem plotly, não tem dash)
- ❌ Não usar machine learning ainda (só descritiva)
- ❌ Não fazer conclusões prontas — me ajude a chegar nelas
- ❌ Não usar nomes de variáveis em inglês
- ❌ Não pular a explicação do "por quê" para ir direto ao "como"

## O notebook segue um roteiro

O projeto tem 75 células com roteiro pré-definido pelo curso. A ordem é:

1. Importar bibliotecas
2. Carregar dataset
3. Visualizar conteúdo
4. Tabela de frequências por classes de renda
5. Gráfico de barras das frequências
6. Conclusões da distribuição de renda
7. Histogramas das variáveis quantitativas
8. Histograma de renda até R$ 20.000
9. Tabela cruzada Sexo × Cor
10. Conclusões do cruzamento
11. Medidas de tendência central da renda
12. Medidas de dispersão da renda
13. Renda por Sexo × Cor (média, mediana, máximo)
14. Dispersão da renda por Sexo × Cor
15. Box plot Renda × Sexo × Cor
16. Desafios: percentil de salário mínimo, top 1%
17. Renda × Anos de Estudo × Sexo
18. Box plot da mesma análise
19. Renda por UF
20. Box plot por UF

## Onde estou agora

[Atualizar à medida que avançar]
- ⏳ Iniciando: carregar dataset e primeiras explorações

## Próximos passos depois deste projeto

1. Concluir o notebook completo
2. Escrever README profissional contando a história dos achados
3. Postar no LinkedIn com 2-3 insights principais
4. Iniciar SQLite (próximo curso do roadmap)
5. **Semana 3:** começar Projeto 1 — Dashboard de Finanças Pessoais

## Repositórios relacionados

```
github.com/RickelmeDSC/
├── python-fundamentos              ← exercícios de curso
├── jornada-dados-ia                ← scripts iniciais ✅
├── analise-descritiva-pnad-2015    ← este repo
├── dashboard-financas-pessoais     ← futuro Projeto 1
├── ecommerce-analytics             ← futuro Projeto 2
├── pipeline-noticias-ia            ← futuro Projeto 3
└── agente-analista-dados           ← futuro Projeto 4
```