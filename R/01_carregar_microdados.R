# R/01_carregar_microdados.R
#
# Etapa 1 - Carregamento dos microdados oficiais PNAD 2015 (IBGE)
# e primeira análise comparativa com pesos amostrais.
#
# Objetivo deste script:
#   1. Ler do PES2015.txt apenas as colunas necessárias (não os 948 chars inteiros)
#   2. Filtrar para Pessoas de Referência com renda válida (mesmos critérios da Etapa 0)
#   3. Construir um objeto de survey design com os pesos da PNAD (V4729)
#   4. Calcular estatísticas da Renda COM pesos amostrais
#   5. Gerar uma tabela comparativa "sem pesos" (Etapa 0) vs "com pesos" (Etapa 1)
#
# Resultado esperado:
#   - As medianas devem mudar pouco (mediana é robusta).
#   - As médias devem mudar mais (a média é puxada pelos extremos, e os pesos
#     redistribuem o que era a "amostra" para o que estima a "população").
#   - Os mínimos e máximos não mudam (são valores extremos observados).

source("R/setup.R")

# ----------------------------------------------------------------------------
# 1. Localizar o arquivo PES2015.txt
# ----------------------------------------------------------------------------
caminho_pes <- list.files(
  path       = "data/microdados_pnad_2015/Dados_20170517",
  pattern    = "^PES2015\\.txt$",
  recursive  = TRUE,
  full.names = TRUE
)
stopifnot(length(caminho_pes) == 1)
cat("Arquivo de microdados:", caminho_pes, "\n")
cat("Tamanho:", round(file.info(caminho_pes)$size / 1024^2, 1), "MB\n\n")

# ----------------------------------------------------------------------------
# 2. Definir as posições das colunas (largura fixa)
#
# Cada linha do PES2015.txt tem 948 caracteres. Cada variável ocupa uma faixa
# fixa de posições, definida no "input PES2015.txt" fornecido pelo IBGE.
# Aqui pegamos APENAS as colunas que vamos usar — economiza tempo e memória.
# ----------------------------------------------------------------------------
posicoes <- fwf_positions(
  start = c(  5, 18, 27, 30, 33, 703, 749, 791),
  end   = c(  6, 18, 29, 30, 33, 704, 760, 795),
  col_names = c("UF", "V0302", "V8005", "V0401",
                "V0404", "V4803", "V4720", "V4729")
)

# Tipos das colunas — V4720 (renda) pode chegar a 12 dígitos (ex.: 999999999999),
# que estoura inteiro de 32 bits, então usamos double.
tipos <- cols(
  UF    = col_integer(),
  V0302 = col_integer(),
  V8005 = col_integer(),
  V0401 = col_integer(),
  V0404 = col_integer(),
  V4803 = col_integer(),
  V4720 = col_double(),
  V4729 = col_double()
)

# ----------------------------------------------------------------------------
# 3. Ler o arquivo (pode levar 1-2 minutos por causa do tamanho)
# ----------------------------------------------------------------------------
cat("Lendo PES2015.txt — pode demorar 1-2 minutos...\n")
t0 <- Sys.time()
microdados <- read_fwf(
  file         = caminho_pes,
  col_positions = posicoes,
  col_types     = tipos,
  progress      = FALSE
)
cat("Leitura concluída em", round(as.numeric(Sys.time() - t0, units = "secs"), 1), "segundos.\n")
cat("Total de registros lidos:", nrow(microdados), "\n\n")

# ----------------------------------------------------------------------------
# 4. Aplicar os MESMOS filtros da Etapa 0
#
# Etapa 0 (cell 5 do notebook):
#   - Foram eliminados registros onde Renda era inválida (999 999 999 999)
#   - Foram eliminados registros onde Renda era missing
#   - Foram mantidos somente as Pessoas de Referência (V0401 == 1)
# ----------------------------------------------------------------------------
microdados <- microdados |>
  filter(V0401 == 1) |>                  # somente pessoa de referência
  filter(!is.na(V4720)) |>               # remove missing
  filter(V4720 != 999999999999)          # remove código de inválido

cat("Após filtros (pessoa de referência + renda válida):", nrow(microdados), "registros.\n")
cat("Referência Etapa 0:                                  76840 registros.\n\n")

# ----------------------------------------------------------------------------
# 5. Renomear colunas para os nomes amigáveis da Etapa 0
# ----------------------------------------------------------------------------
microdados <- microdados |>
  rename(
    Sexo            = V0302,
    Idade           = V8005,
    Cor             = V0404,
    `Anos de Estudo` = V4803,
    Renda           = V4720,
    peso            = V4729
  )

# ----------------------------------------------------------------------------
# 6. Construir o objeto de survey design
#
# Sobre a escolha do design:
#   Usamos design SIMPLIFICADO (ids = ~1, weights = ~peso). Isso já corrige
#   pontos amostrais (média, mediana, totais) para refletir a população.
#   Para correção de variância com PSU/estrato (design completo), seria preciso
#   reconstruir a estrutura de amostragem a partir do arquivo DOM e do número
#   de controle — possível em uma próxima iteração.
#   Esta escolha está documentada em NOTAS_METODOLOGICAS.md (a criar).
# ----------------------------------------------------------------------------
design_pnad <- microdados |>
  as_survey_design(ids = 1, weights = peso)

cat("Design amostral construído.\n")
cat("População estimada (soma dos pesos):", format(sum(microdados$peso), big.mark = "."), "pessoas\n\n")

# ----------------------------------------------------------------------------
# 7. Estatísticas da Renda — COM PESOS (Etapa 1)
# ----------------------------------------------------------------------------
stats_com_pesos <- design_pnad |>
  summarise(
    media   = survey_mean(Renda, vartype = NULL),
    mediana = survey_median(Renda, vartype = NULL)
  )

# survey_mean e survey_median são as funções "ponderadas" do srvyr.
# Para min, max e desvio-padrão ponderado, usamos cálculos diretos:
desvio_p_com_pesos <- sqrt(
  sum(microdados$peso * (microdados$Renda - sum(microdados$peso * microdados$Renda) / sum(microdados$peso))^2) /
    sum(microdados$peso)
)
min_renda <- min(microdados$Renda)
max_renda <- max(microdados$Renda)

# ----------------------------------------------------------------------------
# 8. Estatísticas da Renda — SEM PESOS (replicando Etapa 0 com os MESMOS dados
#    do IBGE — isso confirma se nossa leitura está correta)
# ----------------------------------------------------------------------------
stats_sem_pesos <- microdados |>
  summarise(
    media    = mean(Renda),
    mediana  = median(Renda),
    minimo   = min(Renda),
    maximo   = max(Renda),
    desvio_p = sd(Renda)
  )

# ----------------------------------------------------------------------------
# 9. Tabela comparativa final
# ----------------------------------------------------------------------------
cat("=================================================================\n")
cat("  Comparação: Renda da pessoa de referência (PNAD 2015)\n")
cat("  Etapa 0 (CSV curado, sem pesos)  vs  Etapa 1 (microdados, COM pesos)\n")
cat("=================================================================\n\n")

comparacao <- tibble(
  metrica   = c("media", "mediana", "minimo", "maximo", "desvio_p"),
  sem_pesos = c(stats_sem_pesos$media,
                stats_sem_pesos$mediana,
                stats_sem_pesos$minimo,
                stats_sem_pesos$maximo,
                stats_sem_pesos$desvio_p),
  com_pesos = c(stats_com_pesos$media,
                stats_com_pesos$mediana,
                min_renda,
                max_renda,
                desvio_p_com_pesos)
) |>
  mutate(
    diff_abs     = com_pesos - sem_pesos,
    diff_rel_pct = (com_pesos - sem_pesos) / sem_pesos * 100
  )

print(comparacao, n = Inf)

cat("\n--- Como ler:\n")
cat("  sem_pesos      = estatística calculada na amostra bruta (Etapa 0)\n")
cat("  com_pesos      = estatística calculada com os pesos amostrais (Etapa 1)\n")
cat("  diff_abs       = diferença absoluta (com_pesos - sem_pesos)\n")
cat("  diff_rel_pct   = diferença relativa em %\n")

cat("\nReferência da Etapa 0 (notebook Python):\n")
cat("  média = 2000.38  |  mediana = 1200  |  min = 0  |  max = 200000  |  std = 3323.39\n")
