
# public data -------------------------------------------------------------


## setup -------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)
library(stringr)

try_raw <- read.delim('data/TRY/24551.txt', quote = "") %>% 
  as_tibble()

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')

## create and write means of stats by species ------------------------------

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


## summarize TRY stats for selected CC species -----------------------------

# get a list of the scientific names of species to sample
focal_spp <- cc_raw %>% 
  # select down to survey-specific traits
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  # select individual surveys
  unique() %>% 
  filter(
    # only include visual surveys - more total samples than beat sheets
    ObservationMethod == 'Visual',
    # limit to recent years
    Year %in% c(2017:2019,2021:2022),
    # limit to surveys within ~21 days of the summer solstice
    julianday >= 150,
    julianday <= 192,
    # limit to surveys at sites in a local bounding box - roughly the Triangle
    between(Latitude, 35.5, 36.5),
    between(Longitude, -79.5, -78.5)) %>% 
  # join in plant scientific names using Colleen's list
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName'))%>% 
  # calculate number of surveys per plant
  group_by(PlantFK,sciName) %>% 
  summarize(n_surveys = length(unique(ID))) %>% 
  # only include plants with more than 9 surveys
  filter(n_surveys > 9) %>% 
  # calculate summary survey statistics for each plant species
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    num_surveys = sum(n_surveys, na.rm = T),
    min_surveys = min(n_surveys, na.rm = T)) %>% 
  # cut down to species with more than 5 branches (more than 9 surveys each) and more than 50 total surveys
  filter(n_branches > 5, num_surveys > 50, !is.na(sciName)) %>% 
  mutate(sciName = str_replace(sciName, 'Lindera', 'Lindera benzoin')) %>% 
  pull(sciName)

propNotNA <- function(x){length(x[!is.na(x)])/length(x)}

try_means <- read_csv('data/TRY/TRY_means.csv')

try_categorical <- read_csv('data/TRY/TRY_categorical.csv')

traits <- try_means %>% 
  full_join(try_categorical, by = 'AccSpeciesName') %>%
  filter(AccSpeciesName %in% focal_spp) %>% 
  summarize_all(.funs = propNotNA) %>%
  pivot_longer(cols = everything()) %>% 
  filter(value > 0, name != 'AccSpeciesName') %>% 
  pull(name)

local_traits <- try_means %>%
  as_tibble() %>% 
  filter(AccSpeciesName %in% focal_spp) %>% 
  select(AccSpeciesName,all_of(traits[traits %in% names(try_means)]))

# write as a csv for manual processing - doing it in R is proving way more complicated than it needs to be
write_csv(local_traits, 'data/cc_plant_traits.csv')

# read in that csv to add categoricals, then do it again

local_traits2 <- read_csv('data/cc_plant_traits.csv') %>% 
  select(1:4)

try_categorical %>%
  as_tibble() %>% 
  filter(AccSpeciesName %in% focal_spp) %>% 
  full_join(local_traits2) %>% 
  write_csv('data/cc_plant_traits.csv')





# all data ----------------------------------------------------------------


## setup -------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# this file is too large for github, so it's stored permanently in the lab drive
try_raw <- read.delim('data/TRY/all/24998.txt', quote = "") %>% 
  as_tibble()

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')



## writing csvs ------------------------------------------------------------


try_means <- try_raw %>% 
  # filter out any rows with non-numeric values in the value column and any rows where the trait is undefined
  filter(
    !str_detect(OrigValueStr, "[A-Za-z]"),
    !TraitName == "") %>% 
  # mutates to generate consistent units - these were developed after reviewing a first pass of the data without them
  mutate(
    OrigValueStr = as.numeric(OrigValueStr),
    # format is consistent - uses an if_else and case_when statements to modify the value in each row to have consistent units for the trait, then sets the unit column for that trait equal to the chosen consistent unit
    OrigValueStr = if_else(
      TraitName == "Leaf iron (Fe) content per leaf dry mass",
      true = case_when(
        OrigUnitStr == "ln of (mg/kg)" ~ OrigValueStr,
        OrigUnitStr == "mg/g" ~ log((OrigValueStr*1000)),
        OrigUnitStr == "mg/kg" ~ log(OrigValueStr),
        OrigUnitStr == "microg/g" ~ log(OrigValueStr)),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf iron (Fe) content per leaf dry mass",
      true = "ln_mg/kg",
      false = OrigUnitStr),
    OrigValueStr = if_else(
      TraitName == "Leaf area (in case of compound leaves: leaflet, petiole included)",
      true = case_when(
        OrigUnitStr == 'cm2' ~ OrigValueStr,
        OrigUnitStr == 'mm2' ~ OrigValueStr/100),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf area (in case of compound leaves: leaflet, petiole included)",
      true = "cm2",
      false = OrigUnitStr),
    OrigValueStr = if_else(
      TraitName == "Leaf carbon (C) content per leaf dry mass",
      true = case_when(
        OrigUnitStr %in% c("%", "mg/mg *100", "percent") ~ OrigValueStr,
        OrigUnitStr == "g C g-1 DW" ~ OrigValueStr*100,
        OrigUnitStr %in% c("(mg g-1)", "mg g-1", "mg/g dry mass", "mg/g") ~ OrigValueStr/1000*100),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf carbon (C) content per leaf dry mass",
      true = "percent",
      false = OrigUnitStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf carbon/nitrogen (C/N) ratio",
      true = "g/g",
      false = OrigUnitStr),
    OrigValueStr = if_else(
      TraitName == "Leaf cellulose content per leaf dry mass",
      true = if_else(
        OrigUnitStr == "mg g-1",
        true = OrigValueStr/1000,
        false = OrigValueStr),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf cellulose content per leaf dry mass",
      true = "percent",
      false = OrigUnitStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf lignin content per leaf dry mass",
      true = "percent",
      false = OrigUnitStr),
    OrigValueStr = if_else(
      TraitName == "Leaf nitrogen (N) content per leaf dry mass",
      true = case_when(
        OrigUnitStr %in% c("%", "percent") ~ OrigValueStr,
        OrigUnitStr %in% c("g N g-1 DW", "kg/kg", "") ~ OrigValueStr*100,
        OrigUnitStr %in% c("(mg g-1)", "mg / g", "mg N g-1", "mg g-1", "mg/g dry mass", "mg/g") ~ OrigValueStr/1000*100),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf nitrogen (N) content per leaf dry mass",
      true = "percent",
      false = OrigUnitStr),
    OrigValueStr = if_else(
      TraitName == "Leaf sugar content per leaf dry mass",
      true = case_when(
        OrigUnitStr == "%" ~ OrigValueStr,
        OrigUnitStr == "g g-1 DW" ~ OrigValueStr*100),
      false = OrigValueStr),
    OrigUnitStr = if_else(
      TraitName == "Leaf sugar content per leaf dry mass",
      true = "percent",
      false = OrigUnitStr)) %>% 
  # stick together the name of the data and the units so means are only calculated for columns with the same units (should be all of them for each trait after above)
  mutate(DataName = str_c(DataName, ' (', OrigUnitStr, ')')) %>%  
  group_by(DataName, AccSpeciesName) %>% 
  summarize(meanValue = mean(OrigValueStr, na.rm = T)) %>% 
  pivot_wider(
    names_from = DataName,
    values_from = meanValue)

write_csv(try_means, 'data/TRY/all/TRY_means.csv')

try_categorical <- try_raw %>% 
  filter(
    str_detect(OrigValueStr, "[A-Za-z]"),
    !TraitName == "") %>%
  select(AccSpeciesName, DataName, OrigValueStr) %>% 
  pivot_wider(
    names_from = DataName,
    values_from = OrigValueStr,
    values_fn = ~str_flatten(.x,collapse = '_'))

write_csv(try_categorical, 'data/TRY/all/TRY_categorical.csv')




## checking focal species --------------------------------------------------

# get a list of the scientific names of species to sample
focal_spp <- cc_raw %>% 
  # select down to survey-specific traits
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  # select individual surveys
  unique() %>% 
  filter(
    # only include visual surveys - more total samples than beat sheets
    ObservationMethod == 'Visual',
    # limit to recent years
    Year %in% c(2017:2019,2021:2022),
    # limit to surveys within ~21 days of the summer solstice
    julianday >= 150,
    julianday <= 192,
    # limit to surveys at sites in a local bounding box - roughly the Triangle
    between(Latitude, 35.5, 36.5),
    between(Longitude, -79.5, -78.5)) %>% 
  # join in plant scientific names using Colleen's list
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName'))%>% 
  # calculate number of surveys per plant
  group_by(PlantFK,sciName) %>% 
  summarize(n_surveys = length(unique(ID))) %>% 
  # only include plants with more than 9 surveys
  filter(n_surveys > 9) %>% 
  # calculate summary survey statistics for each plant species
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    num_surveys = sum(n_surveys, na.rm = T),
    min_surveys = min(n_surveys, na.rm = T)) %>% 
  # cut down to species with more than 5 branches (more than 9 surveys each) and more than 50 total surveys
  filter(n_branches > 5, num_surveys > 50, !is.na(sciName)) %>% 
  mutate(sciName = str_replace(sciName, 'Lindera', 'Lindera benzoin')) %>% 
  pull(sciName)

propNotNA <- function(x){length(x[!is.na(x)])/length(x)}

try_means <- read_csv('data/TRY/all/TRY_means.csv')

try_categorical <- read_csv('data/TRY/all/TRY_categorical.csv')

traits <- try_means %>% 
  full_join(try_categorical, by = 'AccSpeciesName') %>%
  filter(AccSpeciesName %in% focal_spp) %>% 
  summarize_all(.funs = propNotNA) %>%
  pivot_longer(cols = everything()) %>% 
  filter(value > 0, name != 'AccSpeciesName') %>% 
  pull(name)

local_traits <- try_means %>%
  as_tibble() %>% 
  filter(AccSpeciesName %in% focal_spp) %>% 
  select(AccSpeciesName,all_of(traits[traits %in% names(try_means)]))
