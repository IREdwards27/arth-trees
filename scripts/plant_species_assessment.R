library(tidyverse)

cc <- read_csv('data/CC_fullDataset_2022-11-30.csv')

summer <- read_csv('data/summer2022/trees_2022-08-16.csv')

cc %>% 
  filter(Year == 2022) %>% 
  group_by(Name, Code, Species) %>% 
  summarize(n_surveys = length(unique(ID))) %>% 
  filter(
    Name %in% c(
      'NC State University',
      'UNC Chapel Hill Campus',
      'Prairie Ridge Ecostation',
      'NC Botanical Garden',
      'Triangle Land Conservancy - Johnston Mill Nature Preserve',
      'Eno River State Park',
      'Duke Forest - Korstian Division'),
    n_surveys > 5) %>% 
  group_by(Species) %>% 
  summarize(
    n_sites = length(unique(Name)),
    n_branches = n(),
    n_surveys = sum(n_surveys)) %>% 
  arrange(
    desc(n_sites),
    desc(n_branches)) %>% 
  write_csv('data/species_summary.csv')
