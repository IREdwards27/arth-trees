library(tidyverse)

# read in full Caterpillars Count! dataset
cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

# read in tree species data
plant_species <- read_csv('data/plantNames_2023-02-01.csv')

# create a data frame with the number of branches, total surveys on plants of that species, and minimum number of surveys on a branch for each plant species in the Triangle area
local_stats <- cc_raw %>% 
  # select only survey or coarser information columns and remove duplicates
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  unique() %>% 
  # filter to surveys conducted from 2017-2022 within 3 weeks of the summer solstice in the Triangle area
  filter(
    ObservationMethod == 'Visual',
    Year %in% c(2017:2019,2021:2022),
    julianday >= 150,
    julianday <= 192,
    between(Latitude, 35.5, 36.5),
    between(Longitude, -79.5, -78.5)) %>% 
  # join in plant species information
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName')) %>% 
  # group and calculate the number of surveys conducted on each plant
  group_by(PlantFK,sciName) %>% 
  summarize(n_surveys = length(unique(ID))) %>% 
  # remove any plants with fewer than 9 total surveys
  filter(n_surveys > 9) %>% 
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    num_surveys = sum(n_surveys, na.rm = T),
    min_surveys = min(n_surveys, na.rm = T))

# view the statistics for species with more than 5 total branches and more than 50 total surveys
local_stats %>% 
  filter(n_branches > 5, num_surveys > 50)

# perform the same calculations as above, but for the entirety of North Carolina
NC_stats <- cc_raw %>% 
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  unique() %>% 
  filter(
    ObservationMethod == 'Visual',
    Year %in% c(2017:2019,2021:2022),
    julianday >= 150,
    julianday <= 192,
    Region == 'NC') %>% 
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName')) %>% 
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    n_surveys = length(unique(ID)))

NC_stats %>% 
  filter(n_branches > 10, n_surveys > 100)

# same calculations but for NC and bordering states
fivestate_stats <- cc_raw %>% 
  select(ID, LocalDate, julianday, Year, ObservationMethod, WetLeaves, PlantSpecies, NumberOfLeaves, SiteFK, Name, Latitude, Longitude, Region, PlantFK) %>% 
  unique() %>% 
  filter(
    ObservationMethod == 'Visual',
    Year %in% c(2017:2019,2021:2022),
    julianday >= 150,
    julianday <= 192,
    Region %in% c('NC','VA','GA','SC','TN')) %>% 
  left_join(
    plant_species %>% 
      select(cleanedName, sciName),
    by = c('PlantSpecies' = 'cleanedName')) %>% 
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    n_surveys = length(unique(ID)))

fivestate_stats %>% 
  filter(n_branches > 10, n_surveys > 100)
