# R/07_renda_escolaridade.R
#
# Etapa 1 — Renda segundo Anos de Estudo × Sexo, com pesos amostrais.
# Reproduz as células 67-71 do notebook Python (Etapa 0).
#
# Saídas:
#   - Tabela de renda MEDIANA por Anos de Estudo × Sexo (com pesos)
#   - Comparação com a Etapa 0
#   - Gráfico de linhas: progressão da renda mediana por escolaridade,
#     comparando Etapa 0 vs IBGE com pesos, facetado por Sexo

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
microdados <- read_fwf(caminho_pes, posicoes, tipos, progress = FALSE) |>
  filter(V0401 == 1, !is.na(V4720), V4720 != 999999999999) |>
  rename(Renda = V4720, peso = V4729) |>
  mutate(
    Sexo = factor(
      case_when(V0302 == 2 ~ "Masculino", V0302 == 4 ~ "Feminino"),
      levels = c("Masculino", "Feminino")
    )
  )

# ============================================================================
# 2. Survey design
# ============================================================================
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

# ============================================================================
# 3. Renda MEDIANA por Anos de Estudo × Sexo — COM PESOS
# ============================================================================
medianas_pesos <- design_pnad |>
  group_by(V4803, Sexo) |>
  summarise(mediana = survey_median(Renda, vartype = NULL), .groups = "drop") |>
  rename(anos_estudo = V4803)

cat("\n=== Renda mediana por Anos de Estudo × Sexo — COM PESOS ===\n")
medianas_pesos |>
  pivot_wider(names_from = Sexo, values_from = mediana) |>
  print(n = Inf)

# ============================================================================
# 4. Valores da Etapa 0 (notebook Python, célula 68)
# ============================================================================
medianas_etapa0 <- tibble(
  anos_estudo = rep(1:17, times = 2),
  Sexo = factor(
    rep(c("Masculino", "Feminino"), each = 17),
    levels = c("Masculino", "Feminino")
  ),
  mediana = c(
    # Masculino, códigos 1 a 17 (Sem instrução → Não determinados)
    700, 788, 788, 800, 1000, 1045, 1200, 1200, 1300, 1200,
    1218, 1500, 1800, 2400, 2500, 4000, 1200,
    # Feminino
    390, 400, 450, 500, 788, 788, 788, 788, 800, 788,
    800, 1000, 1200, 1300, 1600, 2800, 788
  )
)

# ============================================================================
# 5. Comparação Etapa 0 vs IBGE com pesos
# ============================================================================
comparacao <- medianas_etapa0 |>
  rename(mediana_etapa0 = mediana) |>
  left_join(
    medianas_pesos |> rename(mediana_ibge = mediana),
    by = c("anos_estudo", "Sexo")
  ) |>
  mutate(
    diff_abs = mediana_ibge - mediana_etapa0,
    diff_pct = ifelse(mediana_etapa0 > 0,
                      (mediana_ibge - mediana_etapa0) / mediana_etapa0 * 100,
                      NA)
  )

cat("\n=== Comparação Etapa 0 vs IBGE com pesos (medianas em R$) ===\n")
print(comparacao, n = Inf)

# ============================================================================
# 6. Gráfico de linhas — exclui código 17 (Não determinados)
# ============================================================================
dados_grafico <- bind_rows(
  medianas_etapa0 |>
    rename(mediana_renda = mediana) |>
    mutate(fonte = "Etapa 0 (Alura)"),
  medianas_pesos |>
    rename(mediana_renda = mediana) |>
    mutate(fonte = "IBGE com pesos")
) |>
  filter(anos_estudo != 17) |>
  mutate(
    fonte = factor(fonte, levels = c("Etapa 0 (Alura)", "IBGE com pesos"))
  )

grafico <- ggplot(
  dados_grafico,
  aes(x = anos_estudo, y = mediana_renda, color = fonte, shape = fonte)
) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.2) +
  facet_wrap(~ Sexo, ncol = 1) +
  scale_x_continuous(breaks = 1:16) +
  scale_y_continuous(
    labels = scales::label_comma(big.mark = ".", decimal.mark = ",")
  ) +
  scale_color_manual(values = c("#9a9a9a", "#1f6f8b")) +
  labs(
    title    = "Renda mediana por Anos de Estudo — comparação",
    subtitle = "Etapa 0 (CSV Alura, sem pesos) × Microdado IBGE com pesos amostrais",
    x = "Código de Anos de Estudo (1 = sem instrução  ...  16 = 15 anos ou mais)",
    y = "Renda mediana (R$)",
    color = NULL, shape = NULL,
    caption = "Fonte: PNAD 2015 — pessoas de referência do domicílio"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    plot.title    = element_text(face = "bold"),
    strip.text    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "grey30"),
    plot.caption  = element_text(color = "grey50", size = 8)
  )

dir.create("images/etapa1", showWarnings = FALSE, recursive = TRUE)
saida <- "images/etapa1/renda_escolaridade_comparacao.png"
ggsave(saida, grafico, width = 11, height = 7, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
