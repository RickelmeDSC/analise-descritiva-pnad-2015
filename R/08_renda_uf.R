# R/08_renda_uf.R
#
# Etapa 1 — Renda segundo a UF, com pesos amostrais.
# Reproduz as células 73-76 do notebook Python (Etapa 0).
#
# Saídas:
#   - Tabela de renda MEDIANA por UF (com pesos), ordenada
#   - Comparação com a Etapa 0
#   - Gráfico de barras horizontal: ranking das UFs por renda mediana,
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
  rename(Renda = V4720, peso = V4729)

# ============================================================================
# 2. Dicionário de códigos de UF -> nome do estado
# ============================================================================
ufs_dic <- tribble(
  ~codigo, ~uf_nome,
  11, "Rondonia",        12, "Acre",
  13, "Amazonas",        14, "Roraima",
  15, "Para",            16, "Amapa",
  17, "Tocantins",       21, "Maranhao",
  22, "Piaui",           23, "Ceara",
  24, "Rio Grande do Norte", 25, "Paraiba",
  26, "Pernambuco",      27, "Alagoas",
  28, "Sergipe",         29, "Bahia",
  31, "Minas Gerais",    32, "Espirito Santo",
  33, "Rio de Janeiro",  35, "Sao Paulo",
  41, "Parana",          42, "Santa Catarina",
  43, "Rio Grande do Sul", 50, "Mato Grosso do Sul",
  51, "Mato Grosso",     52, "Goias",
  53, "Distrito Federal"
)

microdados <- microdados |>
  left_join(ufs_dic, by = c("UF" = "codigo"))

# ============================================================================
# 3. Survey design
# ============================================================================
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

# ============================================================================
# 4. Renda MEDIANA por UF — COM PESOS
# ============================================================================
medianas_pesos <- design_pnad |>
  group_by(uf_nome) |>
  summarise(mediana = survey_median(Renda, vartype = NULL), .groups = "drop") |>
  arrange(desc(mediana))

cat("\n=== Ranking de UFs por renda mediana — COM PESOS ===\n")
print(medianas_pesos, n = Inf)

# ============================================================================
# 5. Valores da Etapa 0 (notebook Python — ranking computado anteriormente)
# ============================================================================
medianas_etapa0 <- tribble(
  ~uf_nome,            ~mediana_etapa0,
  "Distrito Federal",   2000,
  "Santa Catarina",     1800,
  "Sao Paulo",          1600,
  "Rio Grande do Sul",  1500,
  "Mato Grosso do Sul", 1500,
  "Mato Grosso",        1500,
  "Parana",             1500,
  "Goias",              1500,
  "Rio de Janeiro",     1400,
  "Espirito Santo",     1274,
  "Rondonia",           1200,
  "Minas Gerais",       1200,
  "Amapa",              1200,
  "Roraima",            1000,
  "Tocantins",          1000,
  "Acre",                900,
  "Amazonas",            900,
  "Pernambuco",          900,
  "Para",                850,
  "Bahia",               800,
  "Rio Grande do Norte", 800,
  "Ceara",               789,
  "Alagoas",             788,
  "Sergipe",             788,
  "Paraiba",             788,
  "Piaui",               750,
  "Maranhao",            700
)

comparacao <- medianas_etapa0 |>
  left_join(
    medianas_pesos |> rename(mediana_ibge = mediana),
    by = "uf_nome"
  ) |>
  mutate(
    diff_abs = mediana_ibge - mediana_etapa0,
    diff_pct = (mediana_ibge - mediana_etapa0) / mediana_etapa0 * 100
  ) |>
  arrange(desc(mediana_ibge))

cat("\n=== Comparação Etapa 0 vs IBGE com pesos — Renda mediana por UF ===\n")
print(comparacao, n = Inf)

# ============================================================================
# 6. Gráfico de barras horizontal: ranking das UFs
# ============================================================================
dados_grafico <- comparacao |>
  pivot_longer(
    cols = c(mediana_etapa0, mediana_ibge),
    names_to = "fonte", values_to = "mediana"
  ) |>
  mutate(
    fonte = factor(fonte,
                   levels = c("mediana_etapa0", "mediana_ibge"),
                   labels = c("Etapa 0 (Alura)", "IBGE com pesos")),
    uf_nome = factor(uf_nome,
                     levels = rev(comparacao$uf_nome))
  )

grafico <- ggplot(dados_grafico, aes(x = mediana, y = uf_nome, fill = fonte)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_text(
    aes(label = sprintf("R$ %s",
                        format(round(mediana), big.mark = ".", decimal.mark = ","))),
    position = position_dodge(width = 0.75),
    hjust = -0.1, size = 2.6
  ) +
  scale_x_continuous(
    limits = c(0, max(dados_grafico$mediana) * 1.18),
    labels = scales::label_comma(big.mark = ".", decimal.mark = ",")
  ) +
  scale_fill_manual(values = c("#9a9a9a", "#1f6f8b")) +
  labs(
    title    = "Renda mediana por Unidade da Federação — comparação",
    subtitle = "Etapa 0 (CSV Alura, sem pesos) × Microdado IBGE com pesos amostrais",
    x = "Renda mediana (R$)",
    y = NULL,
    fill = NULL,
    caption = "Fonte: PNAD 2015 — pessoas de referência do domicílio | UFs ordenadas pela mediana IBGE com pesos"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = "top",
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "grey30"),
    plot.caption  = element_text(color = "grey50", size = 8),
    panel.grid.major.y = element_blank()
  )

dir.create("images/etapa1", showWarnings = FALSE, recursive = TRUE)
saida <- "images/etapa1/renda_uf_comparacao.png"
ggsave(saida, grafico, width = 11, height = 10, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
