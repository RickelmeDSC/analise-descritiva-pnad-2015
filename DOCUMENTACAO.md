# 📄 Documentação Técnica — Análise Descritiva PNAD 2015

Documento de apoio ao projeto. Enquanto o [README.md](README.md) conta a *história* dos achados, este arquivo registra os *detalhes técnicos*: dicionário de dados, metodologia e as decisões tomadas ao longo da análise.

---

## 1. Visão geral

| Item | Descrição |
|---|---|
| **Dataset** | Pesquisa Nacional por Amostra de Domicílios (PNAD) 2015 — IBGE |
| **Registros** | 76.840 linhas |
| **Variáveis** | 7 colunas |
| **Unidade de análise** | Pessoa de referência do domicílio (responsável) |
| **Valores ausentes** | Nenhum (0 nulos em todas as colunas) |
| **Salário mínimo de referência (2015)** | R\$ 788,00 |

---

## 2. Dicionário de dados

### Variáveis quantitativas

| Variável | Tipo | Unidade | Descrição |
|---|---|---|---|
| `Renda` | Quantitativa contínua | R\$ | Rendimento mensal do trabalho principal |
| `Idade` | Quantitativa discreta | anos | Idade do morador na data de referência |
| `Altura` | Quantitativa contínua | metros | Altura do morador (elaboração própria do dataset) |

### Variáveis qualitativas

> ⚠️ As variáveis abaixo aparecem como números no arquivo, mas são **categóricas** — os códigos são rótulos, não quantidades. Calcular média de `UF`, por exemplo, não tem significado.

**`Sexo`**

| Código | Descrição |
|---|---|
| 0 | Masculino |
| 1 | Feminino |

**`Cor`**

| Código | Descrição |
|---|---|
| 0 | Indígena |
| 2 | Branca |
| 4 | Preta |
| 6 | Amarela |
| 8 | Parda |
| 9 | Sem declaração |

> Observação: não há registros com cor "Sem declaração" (código 9) neste conjunto de dados.

**`Anos de Estudo`** — qualitativa ordinal

| Código | Descrição | | Código | Descrição |
|---|---|---|---|---|
| 1 | Sem instrução e menos de 1 ano | | 10 | 9 anos |
| 2 | 1 ano | | 11 | 10 anos |
| 3 | 2 anos | | 12 | 11 anos |
| 4 | 3 anos | | 13 | 12 anos |
| 5 | 4 anos | | 14 | 13 anos |
| 6 | 5 anos | | 15 | 14 anos |
| 7 | 6 anos | | 16 | 15 anos ou mais |
| 8 | 7 anos | | 17 | Não determinados |
| 9 | 8 anos | | | |

**`UF`** — Unidade da Federação (códigos de 11 a 53, conforme padrão do IBGE). O mapeamento completo código → estado está no notebook (dicionário `uf`).

---

## 3. Tratamentos aplicados aos dados

Os seguintes tratamentos já vinham aplicados aos dados originais (conforme observação do IBGE/curso):

1. Registros com `Renda` inválida (999 999 999 999) foram eliminados.
2. Registros com `Renda` ausente (*missing*) foram eliminados.
3. Foram mantidos apenas os registros das **pessoas de referência** de cada domicílio.

> **Implicação metodológica:** o dataset descreve quem **chefia** os domicílios brasileiros — não a população como um todo. Isso explica, por exemplo, o forte desequilíbrio de sexo (≈ 69% masculino) observado na análise.

---

## 4. Metodologia — roteiro da análise

A análise, contida em `notebooks/analise_descritiva.ipynb`, segue as etapas:

1. **Exploração inicial** — `head()`, `info()`, `describe()`.
2. **Tabela de frequências** por classes de renda (A–E) e gráfico de barras.
3. **Histogramas** das variáveis quantitativas e leitura de assimetria.
4. **Tabela cruzada** Sexo × Cor (frequências e percentuais).
5. **Medidas de tendência central** da renda — média, mediana, moda.
6. **Medidas de dispersão** da renda — desvio médio absoluto, variância, desvio-padrão.
7. **Renda segundo Sexo × Cor** — tabelas de tendência central, dispersão e box plot.
8. **Desafios** — percentil do salário mínimo e teto de renda dos 99%.
9. **Renda segundo Anos de Estudo × Sexo** — tabela e box plot.
10. **Renda segundo a UF** — tabela e box plot.

Cada seção é acompanhada de **conclusões escritas**, com interpretação dos resultados e ressalvas estatísticas.

---

## 5. Decisões técnicas relevantes

Esta seção registra escolhas que fogem do óbvio e podem ser úteis para quem reproduzir ou auditar a análise.

### 5.1. `pd.cut` com `include_lowest=True`
Por padrão, `pd.cut` cria intervalos abertos à esquerda — `(0, 1576]` — o que **excluiria** as pessoas com renda exatamente R\$ 0. Como esses registros existem, usou-se `include_lowest=True`, tornando o primeiro intervalo `[0, 1576]`. Sem isso, esses registros virariam `NaN`.

### 5.2. Desvio médio absoluto calculado pela fórmula
O método `Series.mad()` do pandas, usado no material original do curso, foi **removido na versão 2.0** do pandas. A medida foi recalculada diretamente pela definição:

```python
desvio_medio_absoluto = (serie - serie.mean()).abs().mean()
```

Nas tabelas cruzadas de dispersão, essa fórmula foi encapsulada em uma **função nomeada** (`def desvio_medio_absoluto`) — e não em uma `lambda` — para que o pandas usasse o nome da função como rótulo legível da coluna.

### 5.3. Recortes de renda nos gráficos
A renda tem assimetria extrema (coeficiente ≈ 15,6). Em gráficos com todos os valores, a presença de rendas de até R\$ 200.000 "achata" a maioria dos dados numa única barra. Por isso:
- Histograma da renda: recorte em **R\$ 20.000** (mantém 99,7% dos registros).
- Box plots de renda: recorte em **R\$ 10.000**.

Os recortes melhoram a **legibilidade**, mas não alteram a realidade dos dados — e isso é declarado nas conclusões de cada seção.

### 5.4. Ordenação do box plot por UF
O box plot por estado foi ordenado pela **mediana da renda** (`order=`), em vez da ordem arbitrária dos códigos de UF. Ordenar pela métrica de interesse faz o gráfico revelar o gradiente regional da renda.

### 5.5. Média vs. mediana em grupos pequenos
Em grupos pequenos (população indígena, ≈ 357 registros), uma única observação extrema distorce fortemente a **média** e o **desvio-padrão**. A **mediana**, resistente a valores extremos, foi adotada como medida de referência para comparações entre grupos.

### 5.6. Associação não é causa
Todas as relações observadas (entre renda e sexo, cor, escolaridade ou UF) descrevem **associação estatística**. A análise descritiva não isola variáveis nem prova mecanismos causais — ressalva registrada nas conclusões.

---

## 6. Ambiente e versões

Projeto desenvolvido e validado com:

| Pacote | Versão |
|---|---|
| Python | 3.14 |
| pandas | 2.3.3 |
| numpy | 2.4.1 |
| seaborn | 0.13.2 |
| matplotlib | 3.10.9 |
| scipy | 1.17.1 |
| ipykernel | 7.2.0 |

As versões mínimas recomendadas estão em [`requirements.txt`](requirements.txt).

---

## 7. Evolução — Etapa 1 (Análise com pesos amostrais)

Este documento descreve a **Etapa 0** (análise descritiva em Python sobre o CSV curado pelo curso, sem pesos amostrais). A análise foi expandida numa **Etapa 1**, realizada em R sobre os microdados oficiais do IBGE, com pesos amostrais aplicados via pacote `survey` — em colaboração inicial com a economista **Tanise Brandão** (PhD em Economia).

A Etapa 1 vive na branch `feature/pesos-amostrais`. Documentação dedicada:

- **[NOTAS_METODOLOGICAS.md](NOTAS_METODOLOGICAS.md)** — origem dos dados oficiais, variáveis e posições no `PES2015.txt`, escolha do design amostral simplificado, discrepância documentada entre o CSV curado da Etapa 0 e o microdado IBGE, pontos abertos para revisão metodológica.
- **[RESUMO_ETAPA1.md](RESUMO_ETAPA1.md)** — síntese narrativa dos 6 achados principais, com referências aos gráficos comparativos em `images/etapa1/`.

---

## 8. Como reproduzir

```bash
git clone https://github.com/RickelmeDSC/analise-descritiva-pnad-2015.git
cd analise-descritiva-pnad-2015
pip install -r requirements.txt
jupyter notebook notebooks/analise_descritiva.ipynb
```

No notebook, execute **"Restart & Run All"** para garantir que todas as células rodem na ordem correta, a partir de um kernel limpo.
