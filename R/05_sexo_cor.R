# R/05_sexo_cor.R
#
# Etapa 1 — Tabela cruzada Sexo × Cor com pesos amostrais.
# Reproduz as células 38-39 do notebook Python (Etapa 0).
#
# Saídas:
#   - Tabela cruzada percentual (Sexo × Cor) com pesos
#   - Totais marginais (% por Sexo e por Cor)
#   - Comparação com a Etapa 0
#   - Gráfico de barras: composição por Cor — Etapa 0 vs IBGE com pesos

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
  rename(Renda = V4720, peso = V4729)

# ============================================================================
# 2. Recodificar Sexo e Cor para rótulos legíveis
#    Atenção aos códigos brutos do IBGE (V0302: 2/4; V0404: 0/2/4/6/8/9)
# ============================================================================
microdados <- microdados |>
  mutate(
    Sexo = case_when(
      V0302 == 2 ~ "Masculino",
      V0302 == 4 ~ "Feminino",
      TRUE       ~ NA_character_
    ),
    Cor = case_when(
      V0404 == 0 ~ "Indigena",
      V0404 == 2 ~ "Branca",
      V0404 == 4 ~ "Preta",
      V0404 == 6 ~ "Amarela",
      V0404 == 8 ~ "Parda",
      V0404 == 9 ~ "Sem declaracao",
      TRUE       ~ NA_character_
    )
  ) |>
  mutate(
    Sexo = factor(Sexo, levels = c("Masculino", "Feminino")),
    Cor  = factor(Cor,  levels = c("Indigena", "Branca", "Preta",
                                   "Amarela", "Parda", "Sem declaracao"))
  )

# ============================================================================
# 3. Survey design (com pesos)
# ============================================================================
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

# ============================================================================
# 4. Tabela cruzada Sexo × Cor (com pesos, em % do total)
# ============================================================================
crosstab_pesos <- design_pnad |>
  group_by(Sexo, Cor) |>
  summarise(freq = survey_total(vartype = NULL), .groups = "drop") |>
  mutate(perc = freq / sum(freq) * 100)

cat("\n=== Crosstab Sexo × Cor — COM PESOS (% do total) ===\n")
crosstab_pesos |>
  select(Sexo, Cor, perc) |>
  pivot_wider(names_from = Cor, values_from = perc) |>
  print()

# ============================================================================
# 5. Totais marginais
# ============================================================================
totais_sexo <- design_pnad |>
  group_by(Sexo) |>
  summarise(perc = survey_prop(vartype = NULL) * 100)

totais_cor <- design_pnad |>
  group_by(Cor) |>
  summarise(perc = survey_prop(vartype = NULL) * 100) |>
  arrange(desc(perc))

cat("\n=== Total por Sexo (com pesos) ===\n")
print(totais_sexo)

cat("\n=== Total por Cor (com pesos) ===\n")
print(totais_cor)

# ============================================================================
# 6. Comparação com a Etapa 0
# ============================================================================
# Valores da Etapa 0 (notebook Python, célula 39):
etapa0_sexo <- tibble(
  Sexo = factor(c("Masculino", "Feminino"), levels = c("Masculino", "Feminino")),
  etapa0_perc = c(69.30, 30.70)
)

etapa0_cor <- tibble(
  Cor = factor(c("Indigena", "Branca", "Preta", "Amarela", "Parda"),
               levels = c("Indigena", "Branca", "Preta",
                          "Amarela", "Parda", "Sem declaracao")),
  etapa0_perc = c(0.46, 41.40, 10.92, 0.46, 46.76)
)

cat("\n=== Comparação por Sexo: Etapa 0 vs IBGE com pesos ===\n")
totais_sexo |>
  left_join(etapa0_sexo, by = "Sexo") |>
  rename(ibge_pesos_perc = perc) |>
  mutate(diff_pp = ibge_pesos_perc - etapa0_perc) |>
  print()

cat("\n=== Comparação por Cor: Etapa 0 vs IBGE com pesos ===\n")
totais_cor |>
  left_join(etapa0_cor, by = "Cor") |>
  rename(ibge_pesos_perc = perc) |>
  mutate(diff_pp = ibge_pesos_perc - etapa0_perc) |>
  print()

# ============================================================================
# 7. Gráfico — composição por Cor (Etapa 0 vs IBGE com pesos)
# ============================================================================
dados_grafico <- totais_cor |>
  filter(Cor != "Sem declaracao") |>
  rename(ibge_pesos = perc) |>
  left_join(etapa0_cor |> rename(etapa0 = etapa0_perc), by = "Cor") |>
  pivot_longer(cols = c(etapa0, ibge_pesos),
               names_to = "fonte", values_to = "perc") |>
  mutate(
    fonte = factor(fonte, levels = c("etapa0", "ibge_pesos"),
                   labels = c("Etapa 0 (Alura, sem pesos)",
                              "IBGE com pesos amostrais")),
    Cor   = factor(Cor, levels = c("Indigena", "Amarela", "Preta",
                                   "Branca", "Parda"))
  )

grafico <- ggplot(dados_grafico, aes(x = Cor, y = perc, fill = fonte)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    aes(label = sprintf("%.1f%%", perc)),
    position = position_dodge(width = 0.8),
    vjust = -0.3, size = 3
  ) +
  scale_y_continuous(
    limits = c(0, max(dados_grafico$perc) * 1.1),
    expand = c(0, 0)
  ) +
  scale_fill_manual(values = c("#9a9a9a", "#1f6f8b")) +
  labs(
    title    = "Composição por Cor entre pessoas de referência",
    subtitle = "Etapa 0 (CSV Alura, sem pesos) × Microdado IBGE com pesos amostrais",
    x = "Cor",
    y = "Percentual do total (%)",
    fill = NULL,
    caption = "Fonte: PNAD 2015 — pessoas de referência do domicílio"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "top",
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "grey30"),
    plot.caption  = element_text(color = "grey50", size = 8)
  )

dir.create("images/etapa1", showWarnings = FALSE, recursive = TRUE)
saida <- "images/etapa1/sexo_cor_comparacao.png"
ggsave(saida, grafico, width = 10, height = 6, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
