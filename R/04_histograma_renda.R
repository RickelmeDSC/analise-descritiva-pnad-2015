# R/04_histograma_renda.R
#
# Etapa 1 — Histograma da renda até R$ 20.000, comparando:
#   - Etapa 0 (CSV Alura, sem pesos)
#   - Microdado IBGE com pesos amostrais
#
# Decisão de design: usamos eixo Y em DENSIDADE (não em contagem). Razão:
# as contagens absolutas são incomparáveis (76k registros vs 67 milhões de
# pessoas estimadas). Em densidade, as duas distribuições ficam na mesma
# escala e a comparação visual é direta.

source("R/setup.R")

# ============================================================================
# 1. Carregar microdados IBGE
# ============================================================================
caminho_pes <- list.files(
  "data/microdados_pnad_2015/Dados_20170517",
  pattern = "^PES2015\\.txt$", recursive = TRUE, full.names = TRUE
)
posicoes <- fwf_positions(
  start = c(5, 18, 27, 30, 33, 703, 749, 791),
  end   = c(6, 18, 29, 30, 33, 704, 760, 795),
  col_names = c("UF", "V0302", "V8005", "V0401",
                "V0404", "V4803", "V4720", "V4729")
)
tipos <- cols(
  UF=col_integer(), V0302=col_integer(), V8005=col_integer(),
  V0401=col_integer(), V0404=col_integer(), V4803=col_integer(),
  V4720=col_double(), V4729=col_double()
)

cat("Lendo microdados IBGE...\n")
ibge <- read_fwf(caminho_pes, posicoes, tipos, progress = FALSE) |>
  filter(V0401 == 1, !is.na(V4720), V4720 != 999999999999) |>
  rename(Renda = V4720, peso = V4729)
cat("IBGE:  ", nrow(ibge), "registros\n")

# ============================================================================
# 2. Carregar CSV da Etapa 0 (Alura)
# ============================================================================
cat("\nLendo CSV da Etapa 0 (Alura)...\n")
alura <- read_csv("data/dados.csv", show_col_types = FALSE)
cat("Alura:", nrow(alura), "registros\n")

# ============================================================================
# 3. Recorte para visualização: renda ≤ R$ 20.000
#    (mesmo recorte do histograma da Etapa 0, célula 35)
# ============================================================================
ibge_rec <- ibge |>
  filter(Renda <= 20000) |>
  select(Renda, peso)

alura_rec <- alura |>
  filter(Renda <= 20000) |>
  select(Renda) |>
  mutate(peso = 1)   # peso = 1 = mesma coisa que "sem pesos"

cat("\nRecorte (renda ≤ R$ 20.000):\n")
cat("  Etapa 0 (Alura):  ", nrow(alura_rec), "registros\n")
cat("  IBGE bruto:       ", nrow(ibge_rec), "registros\n")

# ============================================================================
# 4. Medianas para linhas de referência (calculadas no recorte)
# ============================================================================
mediana_alura <- median(alura_rec$Renda)

design_ibge_rec <- ibge_rec |>
  as_survey_design(ids = 1, weights = peso)
mediana_ibge_pop <- design_ibge_rec |>
  summarise(m = survey_median(Renda, vartype = NULL)) |>
  pull(m)

cat(sprintf("\nMediana Etapa 0 (recorte):       R$ %.0f\n", mediana_alura))
cat(sprintf("Mediana IBGE com pesos (recorte): R$ %.0f\n", mediana_ibge_pop))

# ============================================================================
# 5. Montar o dataset para o gráfico
# ============================================================================
dados_grafico <- bind_rows(
  alura_rec |> mutate(fonte = "Etapa 0 (CSV Alura, sem pesos)"),
  ibge_rec  |> mutate(fonte = "IBGE com pesos amostrais")
) |>
  mutate(
    fonte = factor(
      fonte,
      levels = c("Etapa 0 (CSV Alura, sem pesos)",
                 "IBGE com pesos amostrais")
    )
  )

medianas <- tibble(
  fonte = factor(
    c("Etapa 0 (CSV Alura, sem pesos)", "IBGE com pesos amostrais"),
    levels = levels(dados_grafico$fonte)
  ),
  mediana = c(mediana_alura, mediana_ibge_pop)
)

# ============================================================================
# 6. Histograma comparativo (faceted)
# ============================================================================
cat("\nConstruindo histograma comparativo...\n")

grafico <- ggplot(dados_grafico, aes(x = Renda, weight = peso, fill = fonte)) +
  # Histograma com eixo Y em densidade (comparável entre fontes)
  geom_histogram(
    aes(y = after_stat(density)),
    bins = 50, alpha = 0.85,
    color = "white", linewidth = 0.1
  ) +
  # Linha vertical da mediana
  geom_vline(
    data = medianas, aes(xintercept = mediana),
    linetype = "dashed", color = "black", linewidth = 0.55
  ) +
  # Rótulo da mediana
  geom_text(
    data = medianas,
    aes(x = mediana,
        label = sprintf("mediana = R$ %s",
                        format(mediana, big.mark = ".", decimal.mark = ","))),
    y = Inf, vjust = 1.6, hjust = -0.05,
    size = 3.2, inherit.aes = FALSE
  ) +
  facet_wrap(~ fonte, ncol = 1) +
  scale_fill_manual(values = c("#9a9a9a", "#1f6f8b")) +
  scale_x_continuous(
    labels = scales::label_comma(big.mark = ".", decimal.mark = ",")
  ) +
  labs(
    title    = "Distribuição da renda até R$ 20.000 — comparação",
    subtitle = "Etapa 0 (CSV Alura, sem pesos) × Microdado IBGE com pesos amostrais",
    x = "Renda mensal (R$)",
    y = "Densidade",
    caption = "Fonte: PNAD 2015 — pessoas de referência do domicílio"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    strip.text      = element_text(face = "bold"),
    plot.title      = element_text(face = "bold"),
    plot.subtitle   = element_text(color = "grey30"),
    plot.caption    = element_text(color = "grey50", size = 8)
  )

dir.create("images/etapa1", showWarnings = FALSE, recursive = TRUE)
saida <- "images/etapa1/histograma_renda_comparacao.png"
ggsave(saida, grafico, width = 10, height = 7, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
