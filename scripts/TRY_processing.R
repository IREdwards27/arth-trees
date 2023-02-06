
# setup -------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)

try_raw <- read.delim('data/TRY/24551.txt', quote = "") %>% 
  as_tibble()

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')

# create and write means of stats by species ------------------------------

try_means <- try_raw %>% 
  filter(TraitName %in% c(
    'Leaf carbon (C) content per leaf dry mass',
    'Leaf area (in case of compound leaves: leaflet, petiole excluded)',
    'Leaf carbon/nitrogen (C/N) ratio',
    'Leaf phenols content per leaf dry mass',
    'Leaf sugar content per leaf dry mass')) %>% 
  mutate(DataName = str_c(DataName, ' (', OrigUnitStr, ')')) %>% 
  group_by(DataName, AccSpeciesName) %>% 
  summarize(meanValue = mean(as.numeric(OrigValueStr), na.rm = T)) %>% 
  pivot_wider(
    names_from = DataName,
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
    values_from = OrigValueStr,
    values_fn = ~str_flatten(.x,collapse = '_'))

write_csv(try_categorical, 'data/TRY/TRY_categorical.csv')


# summarize TRY stats for selected CC species -----------------------------

cc_species <- cc_raw %>% 
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  unique() %>% 
  filter(
    ObservationMethod == 'Visual',
    Year %in% c(2017:2019,2021:2022),
    julianday >= 150,
    julianday <= 192,
    between(Latitude, 35.5, 36.5),
    between(Longitude, -79.5, -78.5)) %>% 
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName')) %>% 
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    n_surveys = length(unique(ID))) %>% 
  filter(n_branches > 5, n_surveys > 50, !is.na(sciName)) %>% 
  mutate(sciName = if_else(
    sciName == 'Lindera', 
    true = 'Lindera benzoin', 
    false = sciName)) %>% 
  pull(sciName)

propNotNA <- function(x){length(x[!is.na(x)])/length(x)}

traits <- try_means %>% 
  full_join(try_categorical, by = 'AccSpeciesName') %>%
  filter(AccSpeciesName %in% cc_species) %>% 
  summarize_all(.funs = propNotNA) %>%
  pivot_longer(cols = everything()) %>% 
  filter(value > 0, name != 'AccSpeciesName') %>% 
  pull(name)

local_traits <- try_means %>%
  as_tibble() %>% 
  filter(AccSpeciesName %in% cc_species) %>% 
  select(AccSpeciesName,all_of(traits[traits %in% names(try_means)]))

# write as a csv for manual processing - doing it in R is proving way more complicated than it needs to be
write_csv(local_traits, 'data/cc_plant_traits.csv')

# read in that csv to add categoricals, then do it again

local_traits2 <- read_csv('data/cc_plant_traits.csv') %>% 
  select(1:4)

local_traits2 %>% 
  left_join(try_categorical, by = 'AccSpeciesName') %>% 
  write_csv('data/cc_plant_traits.csv')
  
