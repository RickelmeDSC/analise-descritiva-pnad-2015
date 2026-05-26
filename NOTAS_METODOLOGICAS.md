# Notas Metodológicas — Análise PNAD 2015 com Pesos Amostrais (Etapa 1)

> Documento de trabalho destinado à revisão metodológica. Registra as decisões técnicas, suas justificativas e os pontos que merecem discussão.

---

## 1. Contexto

Este projeto começou como uma análise descritiva da PNAD 2015 em Python (Etapa 0), publicada no LinkedIn em maio de 2026. No post, a economista **Tanise Brandão** (PhD em Economia, Data Scientist em Antitrust & Competition) apontou que a análise utilizou a **amostra bruta**, sem aplicar os pesos amostrais da PNAD, e sugeriu o pacote `survey` do R para corrigir.

A Etapa 1 deste projeto é a resposta a essa observação: refazer a análise descritiva sobre os **microdados oficiais do IBGE**, em R, aplicando os pesos amostrais.

---

## 2. Origem dos dados

| Item | Detalhe |
|---|---|
| Fonte | IBGE — FTP oficial |
| URL | `https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_anual/microdados/2015/` |
| Pacote baixado | `Dados_20170517.zip` (29 MB) + dicionários, input SAS, metodologia, questionário |
| Data do download | 2026-05-26 |
| Arquivo principal | `PES2015.txt` — registros por pessoa, 356.904 linhas, 948 chars por linha (largura fixa) |
| Documentação de apoio | `Leitura_em_R_20170517.zip` (inclui `dicPNAD2015.Rdata`) |

Todo o conjunto baixado está em `data/microdados_pnad_2015/` (gitignored — qualquer pessoa que clonar o repositório reproduz baixando do mesmo link).

---

## 3. Variáveis selecionadas

Lemos apenas as colunas necessárias do `PES2015.txt`, usando as posições documentadas no arquivo `input PES2015.txt` (SAS INPUT). Isso economiza tempo de I/O e memória.

| Variável | Posição (início) | Largura | Tipo | Descrição |
|---|---:|---:|---|---|
| `UF` | 5 | 2 | inteiro | Unidade da Federação |
| `V0302` | 18 | 1 | inteiro | Sexo (2 = Masc, 4 = Fem na codificação IBGE) |
| `V8005` | 27 | 3 | inteiro | Idade do morador |
| `V0401` | 30 | 1 | inteiro | Condição na unidade domiciliar |
| `V0404` | 33 | 1 | inteiro | Cor ou raça |
| `V4803` | 703 | 2 | inteiro | Anos de estudo |
| `V4720` | 749 | 12 | double | Rendimento mensal de **todas as fontes** (pessoas de 10+) |
| `V4729` | 791 | 5 | double | **Peso amostral da pessoa** |

### 3.1. Escolha da variável de renda

A PNAD oferece pelo menos duas variáveis de renda no nível pessoal:

- **`V4718`** — Rendimento mensal do **trabalho principal**.
- **`V4720`** — Rendimento mensal de **todas as fontes** (inclui trabalho principal, secundário, aposentadorias, aluguéis, transferências etc.).

A Etapa 0 (CSV curado pela Alura) descrevia a renda como "rendimento mensal do trabalho principal", mas como não conseguimos confirmar qual variável original foi usada na curadoria, **adotamos `V4720` (todas as fontes)** na Etapa 1. Justificativa:

- É a medida socialmente mais relevante de bem-estar econômico.
- É o conceito que o IBGE prioriza nas tabulações oficiais (ex.: linhas de pobreza).
- Permite captar populações como aposentados e beneficiários de programas sociais, cuja exclusão distorceria a distribuição.

→ *Ponto aberto para revisão:* se houver preferência por restringir ao trabalho principal (V4718), a substituição é mecânica.

---

## 4. Tratamentos aplicados

Os filtros mantidos correspondem ao tratamento documentado da Etapa 0:

```r
microdados |>
  filter(V0401 == 1) |>                  # somente pessoa de referência
  filter(!is.na(V4720)) |>               # remove renda missing
  filter(V4720 != 999999999999)          # remove código de inválido
```

**Resultado:** 116.467 registros.

---

## 5. Desenho amostral — decisão importante

Adotamos um **design amostral SIMPLIFICADO**:

```r
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)
```

Isso significa que aplicamos os pesos amostrais (V4729) mas **não** declaramos a estrutura completa de estratos e unidades primárias de amostragem (UPA).

### 5.1. Por quê a simplificação

Uma busca exaustiva no `input PES2015.txt` mostrou que a PNAD anual de 2015 **não disponibiliza diretamente** as variáveis V4617 (estrato) e V4618 (UPA) no arquivo de pessoas. Para o design completo seria necessário:

1. Cruzar o `PES2015.txt` com o `DOM2015.txt` (arquivo de domicílios) via número de controle (`V0102`).
2. Reconstruir o estrato a partir de UF + situação censitária (urbano/rural) + tamanho do município.
3. Tratar o número de controle como identificador de UPA.

Esse caminho é viável e pode ser feito numa próxima iteração, mas adiciona complexidade significativa ao código.

### 5.2. O que o design simplificado garante e o que sacrifica

| | Garantido | Sacrificado |
|---|---|---|
| Médias, medianas, totais, percentuais | ✅ Corrigidos para a população | — |
| Variâncias e intervalos de confiança | — | ❌ Subestimados (tratamos como SRS) |

Como esta primeira fase é **descritiva** (não testes de hipótese, não inferência formal), o sacrifício é aceitável e claramente declarado. Para passos futuros que envolvam IC ou comparações com significância, o design completo será necessário.

→ *Ponto aberto para revisão:* validar se o design simplificado é aceitável para o output desejado, ou se deve-se evoluir para o design completo (com `strata = ~estrato_reconstruido`, `ids = ~V0102`, `nest = TRUE`).

---

## 6. Discrepância entre a Etapa 0 e o microdado IBGE

A Etapa 0 baseou-se em um CSV curado distribuído pela Alura como exercício do curso. Esse CSV tinha **76.840 registros**. O microdado IBGE oficial com os filtros documentados resulta em **116.467 registros**.

### 6.1. Investigação realizada

Testamos sistematicamente combinações de filtros plausíveis para reproduzir o tamanho da Etapa 0:

| Filtro | N | Δ vs 76.840 |
|---|---:|---:|
| Base (V0401=1 + renda válida) | 116.467 | +39.627 |
| + V0404 ≠ 9 | 116.466 | +39.626 |
| + V8005 ≥ 13 | 116.466 | +39.626 |
| + V8005 ≥ 18 | 116.289 | +39.449 |
| + V4720 > 0 | 106.868 | +30.028 |
| Tudo combinado | 106.867 | +30.027 |

**Mesmo com todos os filtros "naturais" aplicados, sobra um gap de ~30 mil registros sem explicação documentada.**

### 6.2. Hipóteses para o gap

1. **Subamostragem didática:** a Alura provavelmente fez uma amostragem (estratificada ou aleatória) para gerar um dataset menor e mais manejável em sala de aula. Suspeita reforçada pelo fato de a variável `Altura` ser sintética ("elaboração própria do curso").
2. **Filtro adicional não documentado** — talvez sobre situação censitária, ocupação ou outra característica não disponível no PES isoladamente.
3. **Versão diferente do microdado** — a Alura pode ter usado uma versão pré-revisada ou uma tabulação intermediária do IBGE.

### 6.3. Consequência metodológica

A Etapa 1 **não é uma "correção" da Etapa 0** no sentido literal. A Etapa 0 era uma análise sobre uma amostra curada (que adicionalmente ignorava pesos); a Etapa 1 é uma análise nova sobre os microdados completos com pesos. Ambas são válidas, mas respondem a perguntas ligeiramente diferentes.

A partir da Etapa 1, **a referência são os microdados oficiais do IBGE**.

---

## 7. Primeiros resultados (Renda)

Com a metodologia descrita, os primeiros números são:

```
População estimada (soma dos pesos): 67.243.802 pessoas de referência
```

| Métrica | SEM pesos (IBGE raw) | COM pesos (estimativa pop.) | Δ relativo |
|---|---:|---:|---:|
| Média | R$ 1.879 | R$ 1.893 | +0,7% |
| Mediana | R$ 1.070 | R$ 1.100 | +2,8% |
| Mínimo | 0 | 0 | — |
| Máximo | 200.000 | 200.000 | — |
| Desvio-padrão | 3.188 | 3.158 | -0,9% |

**Para contexto, a Etapa 0 (CSV Alura, sem pesos):** média R$ 2.000, mediana R$ 1.200.

### 7.1. Interpretação preliminar

- O efeito **apenas do peso amostral**, dentro do microdado IBGE, é **modesto** (1–3%). A amostra do IBGE já é bem balanceada por construção.
- O efeito da **mudança de fonte** (CSV curado → microdado IBGE), mesmo sem pesos, é **maior** (média +6,5%, mediana +12,1% no sentido Alura→IBGE).
- A intuição original da Tanise se confirma — "a forma da distribuição se sustenta; os valores absolutos mudam" — mas a maior parte da mudança vem da **fonte**, não dos pesos.

---

## 8. Reprodutibilidade

Todo o pipeline está nos arquivos:

- [`R/setup.R`](R/setup.R) — carrega os pacotes
- [`R/01_carregar_microdados.R`](R/01_carregar_microdados.R) — lê PES2015.txt, aplica filtros, constrói `svydesign`, gera tabela comparativa
- [`R/02_investigar_filtro_alura.R`](R/02_investigar_filtro_alura.R) — testes diagnósticos do gap entre Etapa 0 e IBGE

Os pacotes R utilizados são:

| Pacote | Versão | Uso |
|---|---|---|
| `survey` | 4.5 | Núcleo da análise com pesos amostrais |
| `srvyr` | 1.3.1 | Wrapper "tidy" do survey |
| `dplyr` | 1.2.1 | Manipulação de dados |
| `readr` | 2.2.0 | Leitura de arquivos largura-fixa |
| `tidyr`, `ggplot2` | — | Reshape e visualização |

Ambiente: R 4.6.0, Windows 11.

---

## 9. Limitações reconhecidas

1. **Design amostral simplificado** — variâncias e ICs são aproximados (ver §5).
2. **Variável de renda escolhida** — V4720 (todas as fontes), não V4718 (trabalho principal). Decisão revisável.
3. **Análise descritiva, não causal** — descrevemos associações entre renda, sexo, cor, escolaridade e UF, sem isolar mecanismos.
4. **Restrição às pessoas de referência** — análise não cobre cônjuges, filhos, outros parentes etc.
5. **Limitada à V0401 = 1** — assume que essa codificação está consistente em todos os domicílios e nas tabulações futuras do projeto.

---

## 10. Pontos abertos para revisão

Estes são pontos onde feedback metodológico seria especialmente valioso:

- [ ] O design simplificado é aceitável para o escopo? Ou já vale evoluir para o design completo com PSU/estrato?
- [ ] V4720 (todas as fontes) é a escolha apropriada? Ou faz mais sentido usar V4718 (trabalho principal)?
- [ ] A interpretação do gap Etapa 0 ↔ IBGE como "curadoria não documentada" parece razoável?
- [ ] Para os próximos cortes (sexo × cor × renda, escolaridade, UF), existe alguma boa prática específica de literatura econômica que devamos seguir?

---

## Referências

- IBGE, *Pesquisa Nacional por Amostra de Domicílios 2015 — Notas Metodológicas*. Rio de Janeiro: IBGE, 2017.
- Lumley, T. (2010). *Complex Surveys: A Guide to Analysis Using R*. Hoboken, NJ: John Wiley & Sons.
- Lumley, T. *Package `survey` documentation*. CRAN.
- Ellis, P. (2017). *survey analysis in R: tutorial with the `srvyr` package* (referência prática).
