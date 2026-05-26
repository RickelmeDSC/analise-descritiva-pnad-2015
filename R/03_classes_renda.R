# R/03_classes_renda.R
#
# Etapa 1 — Distribuição da população por classes de renda (A-E),
# com pesos amostrais.
#
# Reproduz a análise das células 17-27 do notebook Python (Etapa 0),
# agora usando o microdado oficial do IBGE com pesos amostrais.
#
# Saídas:
#   - Tabela impressa no console: distribuição com pesos, sem pesos, e
#     a comparação tripla com a Etapa 0
#   - Gráfico de barras comparativo em images/etapa1/

source("R/setup.R")

# ============================================================================
# 1. Carregar e filtrar o microdado IBGE
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
  UF    = col_integer(), V0302 = col_integer(), V8005 = col_integer(),
  V0401 = col_integer(), V0404 = col_integer(), V4803 = col_integer(),
  V4720 = col_double(),  V4729 = col_double()
)

cat("Lendo microdados...\n")
microdados <- read_fwf(caminho_pes, posicoes, tipos, progress = FALSE) |>
  filter(V0401 == 1, !is.na(V4720), V4720 != 999999999999) |>
  rename(Renda = V4720, peso = V4729)

cat("Pessoas de referência com renda válida:", nrow(microdados), "\n\n")

# ============================================================================
# 2. Definir as classes A-E (mesmos cortes da Etapa 0)
# ============================================================================
sm <- 788   # salário mínimo de 2015
breaks <- c(0, 2 * sm, 5 * sm, 15 * sm, 25 * sm, Inf)
labels_classe <- c("E", "D", "C", "B", "A")   # ordem ASCENDENTE por renda

microdados <- microdados |>
  mutate(
    classe = cut(
      Renda,
      breaks = breaks,
      labels = labels_classe,
      include.lowest = TRUE,
      right = TRUE
    )
  )

# ============================================================================
# 3. Survey design (simplificado: só pesos)
# ============================================================================
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

# ============================================================================
# 4. Distribuição COM pesos amostrais (estimativa populacional)
# ============================================================================
classes_com_pesos <- design_pnad |>
  group_by(classe) |>
  summarise(freq = survey_total(vartype = NULL)) |>
  mutate(perc = freq / sum(freq) * 100) |>
  arrange(desc(classe))

cat("=== Distribuição por classe — COM PESOS (estimativa populacional) ===\n")
print(classes_com_pesos)

# ============================================================================
# 5. Distribuição SEM pesos (microdado IBGE bruto, para comparação interna)
# ============================================================================
classes_sem_pesos <- microdados |>
  count(classe) |>
  mutate(perc = n / sum(n) * 100) |>
  arrange(desc(classe))

cat("\n=== Distribuição por classe — SEM PESOS (microdado bruto) ===\n")
print(classes_sem_pesos)

# ============================================================================
# 6. Comparação tripla: Etapa 0 (Alura) x IBGE sem pesos x IBGE com pesos
# ============================================================================
# Valores percentuais da Etapa 0 (extraídos do notebook Python, célula 25)
etapa0 <- tibble(
  classe       = factor(c("A", "B", "C", "D", "E"),
                        levels = c("A", "B", "C", "D", "E")),
  etapa0_perc  = c(0.546590, 1.069755, 9.423477, 24.208745, 64.751432)
)

comparacao <- etapa0 |>
  left_join(
    classes_sem_pesos |> select(classe, ibge_sem_pesos = perc),
    by = "classe"
  ) |>
  left_join(
    classes_com_pesos |> select(classe, ibge_com_pesos = perc),
    by = "classe"
  )

cat("\n=== Comparação tripla das proporções (%) ===\n")
print(comparacao)

# ============================================================================
# 7. Gráfico de barras comparativo
# ============================================================================
dir.create("images/etapa1", showWarnings = FALSE, recursive = TRUE)

dados_grafico <- comparacao |>
  pivot_longer(
    cols = c(etapa0_perc, ibge_sem_pesos, ibge_com_pesos),
    names_to = "fonte",
    values_to = "perc"
  ) |>
  mutate(
    fonte = factor(
      fonte,
      levels = c("etapa0_perc", "ibge_sem_pesos", "ibge_com_pesos"),
      labels = c("Etapa 0 (CSV Alura)",
                 "IBGE sem pesos",
                 "IBGE com pesos amostrais")
    )
  )

grafico <- ggplot(dados_grafico, aes(x = classe, y = perc, fill = fonte)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75) +
  geom_text(
    aes(label = sprintf("%.1f%%", perc)),
    position = position_dodge(width = 0.8),
    vjust = -0.3, size = 2.9
  ) +
  scale_y_continuous(
    limits = c(0, max(dados_grafico$perc) * 1.1),
    expand = c(0, 0)
  ) +
  scale_fill_manual(values = c("#9a9a9a", "#7fb069", "#1f6f8b")) +
  labs(
    title    = "Distribuição por classe de renda — comparação tripla",
    subtitle = "Etapa 0 (CSV curado pela Alura) vs microdado IBGE, sem e com pesos amostrais",
    x = "Classe de renda",
    y = "Percentual de pessoas (%)",
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

saida <- "images/etapa1/classes_renda_comparacao.png"
ggsave(saida, grafico, width = 10, height = 6, dpi = 100, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", saida))
