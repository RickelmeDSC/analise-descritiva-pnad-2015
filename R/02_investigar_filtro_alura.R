# R/02_investigar_filtro_alura.R
#
# Diagnóstico exploratório:
# Por que o CSV da Etapa 0 (curado pela Alura) tem 76.840 registros,
# enquanto o microdado oficial do IBGE com V0401=1 + renda válida tem 116.467?
#
# Procuramos o(s) filtro(s) adicional(is) que a Alura aplicou.

source("R/setup.R")

# ----- Carregamento (mesma lógica do script 01) -----
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
  UF = col_integer(), V0302 = col_integer(), V8005 = col_integer(),
  V0401 = col_integer(), V0404 = col_integer(), V4803 = col_integer(),
  V4720 = col_double(), V4729 = col_double()
)

cat("Lendo microdados...\n")
microdados <- read_fwf(caminho_pes, posicoes, tipos, progress = FALSE)
cat("Total geral:", nrow(microdados), "registros\n\n")

# ----- 1. Frequência de V0401 (Condição na unidade domiciliar) -----
cat("=== Frequência de V0401 (Condição na unidade domiciliar) ===\n")
print(microdados |> count(V0401, sort = TRUE))

# Filtro base
ref <- microdados |> filter(V0401 == 1)
cat("\nApós V0401 == 1:", nrow(ref), "registros\n")

ref_renda <- ref |> filter(!is.na(V4720), V4720 != 999999999999)
cat("Após + renda válida:", nrow(ref_renda), "registros\n\n")

# ----- 2. Distribuição da idade -----
cat("=== Distribuição da idade (V8005) ===\n")
print(summary(ref_renda$V8005))
cat("\nLembrete: Etapa 0 tinha idade min = 13, max = 99\n\n")

# ----- 3. Frequência de Cor (V0404) -----
cat("=== Frequência de V0404 (Cor) entre pessoas de referência ===\n")
print(ref_renda |> count(V0404, sort = TRUE))
cat("\nLembrete: Etapa 0 NÃO tinha cor 9 (sem declaração)\n\n")

# ----- 4. Frequência da Renda zero -----
cat("=== Renda zero? ===\n")
print(ref_renda |> count(renda_zero = V4720 == 0))
cat("\nLembrete: Etapa 0 tinha min = 0, ou seja, INCLUIU rendas zero\n\n")

# ----- 5. Testar combinações de filtros -----
cat("=== Testando combinações de filtros — meta: 76.840 ===\n\n")

testes <- list(
  "[base] V0401==1 + renda válida"                                 = ref_renda,
  "+ V0404 != 9 (remove sem declaração)"                           = ref_renda |> filter(V0404 != 9),
  "+ V8005 >= 10"                                                  = ref_renda |> filter(V8005 >= 10),
  "+ V8005 >= 13"                                                  = ref_renda |> filter(V8005 >= 13),
  "+ V8005 >= 14"                                                  = ref_renda |> filter(V8005 >= 14),
  "+ V8005 >= 18"                                                  = ref_renda |> filter(V8005 >= 18),
  "+ V4720 > 0 (renda positiva)"                                   = ref_renda |> filter(V4720 > 0),
  "+ V0404 != 9 + V8005 >= 13"                                     = ref_renda |> filter(V0404 != 9, V8005 >= 13),
  "+ V0404 != 9 + V8005 >= 14"                                     = ref_renda |> filter(V0404 != 9, V8005 >= 14),
  "+ V0404 != 9 + V4720 > 0"                                       = ref_renda |> filter(V0404 != 9, V4720 > 0),
  "+ V8005 >= 13 + V4720 > 0"                                      = ref_renda |> filter(V8005 >= 13, V4720 > 0),
  "+ V0404 != 9 + V8005 >= 13 + V4720 > 0"                         = ref_renda |> filter(V0404 != 9, V8005 >= 13, V4720 > 0)
)

resultados <- tibble(
  filtro     = names(testes),
  n          = sapply(testes, nrow),
  diff_alura = sapply(testes, nrow) - 76840
) |>
  arrange(abs(diff_alura))

print(resultados, n = Inf)

cat("\n--- Interpretação:\n")
cat("Buscamos a linha onde 'diff_alura' é mais próxima de zero.\n")
cat("Essa combinação de filtros é a que mais provavelmente reproduz o\n")
cat("CSV curado da Alura.\n")
