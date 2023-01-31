library(dplyr)
library(tidyr)
library(readr)

try_raw <- read.delim('data/TRY/24551.txt', quote = "") %>% 
  as_tibble()

try_means <- try_raw %>% 
  filter(TraitName %in% c(
    'Leaf carbon (C) content per leaf dry mass',
    'Leaf area (in case of compound leaves: leaflet, petiole excluded)',
    'Leaf carbon/nitrogen (C/N) ratio',
    'Leaf phenols content per leaf dry mass',
    'Leaf sugar content per leaf dry mass')) %>%  
  group_by(TraitName, AccSpeciesName, OrigUnitStr) %>% 
  summarize(meanValue = mean(as.numeric(OrigValueStr), na.rm = T)) %>% 
  pivot_wider(
    names_from = TraitName,
    values_from = meanValue)

write_csv(try_means, 'data/TRY/TRY_means.csv')
  
try_categorical <- try_raw %>% 
  filter(TraitName %in% c(
    'Plant palatability',
    'Plant defence mechanisms: chemical',
    'Plant defence mechanisms: physical',
    'Species potential allelopathy',
    'Species tolerance to human impact')) %>% 
  select(AccSpeciesName, DataName, OrigValueStr) %>% 
  pivot_wider(
    names_from = DataName,
    values_from = OrigValueStr)

write_csv(try_categorical, 'data/TRY/TRY_categorical.csv')
