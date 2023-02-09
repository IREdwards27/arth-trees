library(tidyverse)

cc_raw <- read_csv('data/CC_fullDataset_2022-11-30.csv')

plant_species <- read_csv('data/plantNames_2023-02-01.csv')

focal_spp <- cc_raw %>% 
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
    by = c('PlantSpecies' = 'cleanedName'))%>% 
  group_by(PlantFK,sciName) %>% 
  summarize(n_surveys = length(unique(ID))) %>% 
  filter(n_surveys > 9) %>% 
  group_by(sciName) %>% 
  summarize(
    n_branches = length(unique(PlantFK)),
    num_surveys = sum(n_surveys, na.rm = T),
    min_surveys = min(n_surveys, na.rm = T)) %>% 
  filter(n_branches > 5, num_surveys > 50, !is.na(sciName)) %>% 
  pull(sciName)

all_surveys <- cc_raw %>% 
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
  filter(
    sciName %in% focal_spp,
    !is.na(sciName)) %>% 
  group_by(ID, sciName, PlantFK) %>% 
  summarize(
    survey_mass = sum(Biomass_mg, na.rm = T),
    n_orders = length(unique(Group[!is.na(Group)])))

sample_surveys <- map(
  .x = map(
    .x = focal_spp,
    .f = function(x){ 
      branches <- all_surveys %>% 
        filter(sciName == x) %>% 
        group_by(PlantFK) %>% 
        summarize(n_surveys = length(unique(ID))) %>% 
        filter(n_surveys > 9) %>% 
        pull(PlantFK)
      
      sample(x = branches, size = 7)
    }) %>% 
    c(recursive = T),
  .f = function(y){
    surveys <- all_surveys %>% 
      filter(PlantFK == y) %>% 
      pull(ID)
    
    sample(x = surveys, size = 9)
  }) %>% c(recursive = T)

bulk_data <- all_surveys %>% 
  filter(ID %in% sample_surveys)

mass_model <- lm(survey_mass ~ sciName,
                 data = bulk_data)

confint(mass_model, method = 'boot', nsim = 1000)

div_model <- lm(n_orders ~ sciName,
                data = bulk_data)

confint(div_model, method = 'boot', nsim = 1000)

div_model_2 <- lm(n_orders ~ sciName,
                  data = bulk_data %>% 
                    arrange(sciName))

confint(div_model_2)
