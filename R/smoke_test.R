# R/smoke_test.R
#
# Smoke test da Etapa 1.
#
# Objetivo: verificar que o ambiente R + tidyverse roda end-to-end usando o
# MESMO CSV da Etapa 0 (sem pesos amostrais).
#
# Resultado esperado: os números devem bater EXATAMENTE com o describe()
# do notebook Python. Quando, mais à frente, trocarmos para os microdados
# oficiais do IBGE e aplicarmos os pesos, é aí que os valores começarão
# a divergir entre "amostra bruta" e "estimativa populacional" — e é
# justamente esse o resultado que a parceria com a Tanise quer evidenciar.

# Carrega os pacotes (script separado para reuso)
source("R/setup.R")

# Lê o mesmo CSV do notebook Python (caminho relativo à raiz do projeto)
dados <- read_csv("data/dados.csv")

cat("\n=== Dimensões do dataset ===\n")
cat("Linhas:", nrow(dados), "\n")
cat("Colunas:", ncol(dados), "\n")

cat("\n=== Renda — estatísticas (SEM pesos amostrais) ===\n")
dados |>
  summarise(
    media    = mean(Renda),
    mediana  = median(Renda),
    minimo   = min(Renda),
    maximo   = max(Renda),
    desvio_p = sd(Renda)
  ) |>
  print()

cat("\nReferência Python (Etapa 0):\n")
cat("  média = 2000.38  |  mediana = 1200  |  min = 0  |  max = 200000  |  std = 3323.39\n")
cat("Se os valores acima coincidem, o ambiente R está pronto para a Etapa 1.\n")
