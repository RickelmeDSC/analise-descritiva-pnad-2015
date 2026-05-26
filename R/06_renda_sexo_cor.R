# R/06_renda_sexo_cor.R
#
# Etapa 1 — Renda segundo Sexo × Cor com pesos amostrais.
# Reproduz as células 55-57 e 60-62 do notebook Python.
#
# Saídas:
#   - Tabela cruzada de RENDA MEDIANA por Sexo × Cor (com pesos)
#   - Comparação com a Etapa 0
#   - Gráfico de barras: renda mediana por Cor, separado por Sexo,
#     comparando Etapa 0 vs IBGE com pesos

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
    Sexo = case_when(V0302 == 2 ~ "Masculino", V0302 == 4 ~ "Feminino"),
    Cor  = case_when(
      V0404 == 0 ~ "Indigena",
      V0404 == 2 ~ "Branca",
      V0404 == 4 ~ "Preta",
      V0404 == 6 ~ "Amarela",
      V0404 == 8 ~ "Parda"
    )
  ) |>
  filter(!is.na(Cor)) |>   # remove cor 9 (Sem declaração, irrisório)
  mutate(
    Sexo = factor(Sexo, levels = c("Masculino", "Feminino")),
    Cor  = factor(Cor,  levels = c("Indigena", "Amarela", "Preta", "Branca", "Parda"))
  )

# ============================================================================
# 2. Survey design
# ============================================================================
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

# ============================================================================
# 3. Medianas por Sexo × Cor — COM PESOS
# ============================================================================
medianas_pesos <- design_pnad |>
  group_by(Sexo, Cor) |>
  summarise(mediana = survey_median(Renda, vartype = NULL), .groups = "drop")

cat("\n=== Renda MEDIANA por Sexo × Cor — COM PESOS (Etapa 1) ===\n")
medianas_pesos |>
  pivot_wider(names_from = Cor, values_from = mediana) |>
  print()

# ============================================================================
# 4. Comparação com a Etapa 0 (valores do notebook Python, célula 55)
# ============================================================================
medianas_etapa0 <- tribble(
  ~Sexo,        ~Cor,       ~mediana_etapa0,
  "Masculino",  "Indigena",      797.5,
  "Masculino",  "Branca",       1700,
  "Masculino",  "Preta",        1200,
  "Masculino",  "Amarela",      2800,
  "Masculino",  "Parda",        1200,
  "Feminino",   "Indigena",      788,
  "Feminino",   "Branca",       1200,
  "Feminino",   "Preta",         800,
  "Feminino",   "Amarela",      1500,
  "Feminino",   "Parda",         800
) |>
  mutate(
    Sexo = factor(Sexo, levels = c("Masculino", "Feminino")),
    Cor  = factor(Cor,  levels = c("Indigena", "Amarela", "Preta", "Branca", "Parda"))
  )

comparacao <- medianas_etapa0 |>
  left_join(medianas_pesos, by = c("Sexo", "Cor")) |>
  rename(mediana_ibge_pesos = mediana) |>
  mutate(
    diff_abs = mediana_ibge_pesos - mediana_etapa0,
    diff_pct = (mediana_ibge_pesos - mediana_etapa0) / mediana_etapa0 * 100
  )

cat("\n=== Comparação Etapa 0 vs IBGE com pesos — Renda mediana (R$) ===\n")
print(comparacao, n = Inf)

# ============================================================================
# 5. Gráfico de barras: mediana por Cor, separado por Sexo
# ============================================================================
dados_grafico <- comparacao |>
  select(Sexo, Cor, mediana_etapa0, mediana_ibge_pesos) |>
  pivot_longer(
    cols = c(mediana_etapa0, mediana_ibge_pesos),
    names_to = "fonte", values_to = "mediana"
  ) |>
  mutate(
    fonte = factor(fonte,
                   levels = c("mediana_etapa0", "mediana_ibge_pesos"),
                   labels = c("Etapa 0 (Alura)", "IBGE com pesos"))
  )

grafico <- ggplot(dados_grafico, aes(x = Cor, y = mediana, fill = fonte)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_text(
    aes(label = sprintf("R$ %s",
                        format(round(mediana), big.mark = ".", decimal.mark = ","))),
    position = position_dodge(width = 0.8),
    vjust = -0.3, size = 2.9
  ) +
  facet_wrap(~ Sexo, ncol = 1) +
  scale_y_continuous(
    limits = c(0, max(dados_grafico$mediana) * 1.15),
    labels = scales::label_comma(big.mark = ".", decimal.mark = ",")
  ) +
  scale_fill_manual(values = c("#9a9a9a", "#1f6f8b")) +
  labs(
    title    = "Renda mediana por Sexo × Cor — comparação",
    subtitle = "Etapa 0 (CSV Alura, sem pesos) × Microdado IBGE com pesos amostrais",
    x = "Cor",
    y = "Renda mediana (R$)",
    fill = NULL,
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
saida <- "images/etapa1/renda_sexo_cor_comparacao.png"
ggsave(saida, grafico, width = 11, height = 7, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
