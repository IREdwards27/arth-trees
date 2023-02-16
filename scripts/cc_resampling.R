# setup -------------------------------------------------------------------

library(tidyverse)

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')

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
all_surveys <- cc_raw %>% 
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
  # select surveys only on species within the list
  filter(
    sciName %in% focal_spp,
    !is.na(sciName)) %>% 
  # bring data frame down to just the survey ID, plant species, plant code, and summary statistics by survey
  group_by(ID, sciName, PlantFK) %>% 
  summarize(
    survey_mass = sum(Biomass_mg, na.rm = T),
    n_orders = length(unique(Group[!is.na(Group)])))

# a function to get a random sample of 9 surveys from a randomly selected 7 branches for each species
getSamples <- function(){
  
  sample_surveys <- map(
    # internal map function generates a random sample of 7 branches from each species
    .x = map(
      # run the code below for x == each species
      .x = focal_spp,
      .f = function(x){ 
        
        # pull a vector of all the branches with more than 9 surveys for species x
        branches <- all_surveys %>% 
          filter(sciName == x) %>% 
          group_by(PlantFK) %>% 
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
      surveys <- all_surveys %>% 
        filter(PlantFK == y) %>% 
        pull(ID)
      
      # take a random sample of 9 surveys from the set generated above
      sample(x = surveys, size = 9, replace = T)
    }) %>% c(recursive = T)
  
  # filter to the selected surveys and calculate summary statistics by species
  all_surveys %>% 
    filter(ID %in% sample_surveys) %>% 
    group_by(sciName) %>% 
    summarize(
      mean_n_orders = mean(n_orders))
}

# get 100 random samples of 54 branches (9 surveys each for 7 branches)
sampled_trees <- replicate(100, getSamples(), simplify = F) %>% 
  bind_rows()

div_anova <- aov(
  mean_n_orders ~ sciName,
  data = sampled_trees)

TukeyHSD(div_anova)

# use the data generated above to run an ANOVA - each species summary statistics from a given sample is treated as an individual observation
# ANOVA not necessary - go directly to comparison - Tukey's works, but are several functions (explore)

mass_stats <- all_surveys %>% 
  filter(sciName %in% focal_spp) %>% 
  group_by(PlantFK, sciName) %>% 
  summarize(
    n_surveys = length(unique(ID)),
    mean_survey_mass = mean(survey_mass, na.rm = T)) %>% 
  filter(n_surveys > 9)

mass_anova <- aov(
  log(mean_survey_mass) ~ sciName,
  data = mass_stats)

TukeyHSD(mass_anova)


# plotting ----------------------------------------------------------------

# ggbreak may be worth using for the final version of this plot - those outliers could use some assessment, too, though

ggplot(mass_stats) + 
  geom_boxplot(
    mapping = aes(
      x = sciName, 
      y = mean_survey_mass,
      color = sciName)) +
  labs(
    x = NULL,
    y = 'Mean biomass per survey (mg)',
    color = 'Tree species') +
  theme(
    axis.text.x = element_blank())

ggplot(sampled_trees) + 
  geom_boxplot(
    mapping = aes(
      x = sciName,
      y = mean_n_orders,
      color = sciName)) +
  labs(
    x = NULL,
    y = 'Mean number of CC groups per survey',
    color = 'Tree species') +
  theme(
    axis.text.x = element_blank())
