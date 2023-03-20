
# setup -------------------------------------------------------------------

library(tidyverse)

summer_surveys <- read_csv('data/summer2022/beat_sheets_2022-12-02.csv')

summer_trees <- read_csv('data/summer2022/trees_2022-08-16.csv')

summer_taxa <- read_csv('data/summer2022/taxa_2022-12-02.csv')

summer_arths <- read_csv('data/summer2022/foliage_arths_2022-12-02.csv') %>% 
  left_join(
    taxa %>% 
      select(TaxonID, family),
    by = 'TaxonID')

surveytrees <- surveys %>% 
  left_join(
    trees,
    by = c('TreeFK' = 'TreeID'))

try_traits <- read_csv('data/TRY/all/TRY_means.csv') %>% 
  full_join(
    read_csv('data/TRY/all/TRY_categorical.csv'),
    by = 'AccSpeciesName')

set.seed(44)

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')

# get a list of the scientific names of species to sample
cc_species <- cc_raw %>% 
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
  mutate(
    sciName = if_else(
      sciName == 'Lindera',
      true = 'Lindera benzoin',
      false = sciName)) %>% 
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
  pull(sciName)

# create a dataframe of just the surveys from the species above
cc_surveys <- cc_raw %>% 
  # apply the same filters
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
  mutate(
    sciName = if_else(
      sciName == 'Lindera',
      'Lindera benzoin',
      sciName)) %>% 
  # select surveys only on species within the list
  filter(
    sciName %in% cc_species,
    !is.na(sciName)) %>% 
  # bring data frame down to just the survey ID, plant species, plant code, and summary statistics by survey
  group_by(ID, sciName, PlantFK) %>% 
  summarize(
    survey_mass = sum(Biomass_mg, na.rm = T),
    n_orders = length(unique(Group[!is.na(Group)])))

# generate a list of the tree species over the summer with 5 or more branches
summer_species <- surveytrees %>% 
  group_by(Species) %>% 
  summarize(
    nbranches = length(unique(TreeFK)),
    nsurveys = length(unique(BeatSheetID))) %>% 
  arrange(desc(nbranches)) %>% 
  filter(nbranches > 5) %>% 
  pull(Species)


# summer analysis --------------------------------------------------------------


summer_traits <- surveytrees %>% 
  filter(Species %in% summer_species) %>% 
  left_join(
    arths,
    by = c('BeatSheetID' = 'BeatSheetFK'),
    multiple = "all") %>%
  group_by(TreeFK, BeatSheetID) %>% 
  summarize(biomass = sum(TotalMass, na.rm = T)) %>% 
  group_by(TreeFK) %>% 
  summarize(mean_biomass = mean(biomass)) %>% 
  left_join(
    surveytrees %>% 
      filter(Species %in% summer_species) %>% 
      left_join(
        arths,
        by = c('BeatSheetID' = 'BeatSheetFK'),
        multiple = "all") %>% 
      group_by(TreeFK) %>% 
      summarize(n_families = length(unique(family))),
    by = 'TreeFK') %>% 
  # join back in tree info
  left_join(
    trees,
    by = c('TreeFK' = 'TreeID')) %>% 
  group_by(Species) %>% 
  summarize(
    mean_biomass = mean(mean_biomass),
    mean_n_families = mean(n_families)) %>% 
  left_join(
    try_traits,
    by = c('Species' = 'AccSpeciesName'))

ggplot(summer_traits) +
  geom_point(
    aes(
      x = `Leaf carbon content per dry mass (percent)`,
      y = mean_n_families))

ggplot(summer_traits) +
  geom_point(
    aes(
      x = `Leaf carbon/nitrogen (C/N) ratio (g/g)`,
      y = mean_n_families))

ggplot(summer_traits) +
  geom_point(
    aes(
      x = `Leaf force to punch, force required for a punch rod to penetrate a leaf per circumference of the punch (FP) (kN m-1)`,
      y = mean_biomass,
      color = mean_n_families))


# cc analysis -------------------------------------------------------------

getSamples <- function(){
  
  sample_surveys <- map(
    # internal map function generates a random sample of 7 branches from each species
    .x = map(
      # run the code below for x == each species
      .x = cc_species,
      .f = function(x){ 
        
        # pull a vector of all the branches with more than 9 surveys for species x
        branches <- cc_surveys %>% 
          filter(sciName == x) %>% 
          group_by(sciName, PlantFK) %>% 
          summarize(n_surveys = length(unique(ID))) %>% 
          filter(n_surveys > 9) %>% 
          pull(PlantFK)
        
        # take a random sample of 7 from the set above
        sample(x = branches, size = 7, replace = T)
      }) %>% 
      # combine the outputs from internal map into a single vector of branch IDs
      c(recursive = T),
    .f = function(y){
      
      # get all the surveys from the branches selected in the internal map random sample
      surveys <- cc_surveys %>% 
        filter(PlantFK == y) %>% 
        pull(ID)
      
      # take a random sample of 9 surveys from the set generated above
      sample(x = surveys, size = 9, replace = T)
    }) %>% c(recursive = T)
  
  # filter to the selected surveys and calculate summary statistics by species
  cc_surveys %>% 
    filter(ID %in% sample_surveys) %>% 
    group_by(sciName) %>% 
    summarize(
      mean_n_orders = mean(n_orders))
}

# get 100 random samples of 54 branches (9 surveys each for 7 branches)
sampled_trees <- replicate(100, getSamples(), simplify = F) %>% 
  bind_rows()

cc_traits <- cc_surveys %>% 
  group_by(sciName) %>% 
  summarize(mean_survey_mass = mean(survey_mass)) %>% 
  left_join(
    sampled_trees %>% 
      group_by(sciName) %>% 
      summarize(mean_n_orders = mean(mean_n_orders)),
    by = 'sciName') %>% 
  left_join(
    try_traits,
    by = c('sciName' = 'AccSpeciesName'))

ggplot(cc_traits) +
  geom_point(
    aes(
      x = `Leaf physical strength / toughness: tensile strength (N/m) and sclerophylly (categorical) (kg)`,
      y = mean_survey_mass,
      color = mean_n_orders))
