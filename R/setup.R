# R/setup.R
#
# Carrega os pacotes usados em toda a análise da Etapa 1.
# Use `source("R/setup.R")` no início de cada script.

library(readr)    # leitura de CSV (equivalente prático ao pd.read_csv)
library(dplyr)    # manipulação de dados (equivalente prático ao Pandas)
library(tidyr)    # reshape — pivot e melt
library(ggplot2)  # visualização (equivalente prático ao Seaborn)
library(survey)   # núcleo da análise com pesos amostrais (sugestão da Tanise)
library(srvyr)    # wrapper "tidy" do survey — sintaxe parecida com dplyr

cat("Pacotes carregados.\n")
