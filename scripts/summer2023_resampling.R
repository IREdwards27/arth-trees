
# setup -------------------------------------------------------------------

library(tidyverse)

surveys <- read_csv('data/summer2022/beat_sheets_2022-12-02.csv')

trees <- read_csv('data/summer2022/trees_2022-08-16.csv')

taxa <- read_csv('data/summer2022/taxa_2022-12-02.csv')

arths <- read_csv('data/summer2022/foliage_arths_2022-12-02.csv') %>% 
  left_join(
    taxa %>% 
      select(TaxonID, family),
    by = 'TaxonID')

surveytrees <- surveys %>% 
  left_join(
    trees,
    by = c('TreeFK' = 'TreeID'))


# sample checking ---------------------------------------------------------

# generate a list of the tree species over the summer with 5 or more branches
focal_species <- surveytrees %>% 
  group_by(Species) %>% 
  summarize(
    nbranches = length(unique(TreeFK)),
    nsurveys = length(unique(BeatSheetID))) %>% 
  arrange(desc(nbranches)) %>% 
  filter(nbranches > 5) %>% 
  pull(Species)


# resampling --------------------------------------------------------------

sampleBranches <- function(){
  sheets <- map(
    .x = focal_species,
    # generate a random sample of 6 of the branches for each species and pull the branch IDs
    .f = ~ sample(
      surveytrees %>% 
        filter(Species == .x) %>% 
        pull(TreeFK),
      size = 6,
      replace = T)) %>% 
    # smush all the branch IDs into a single vector
    c(recursive = T)
  
  surveytrees %>% 
        filter(TreeFK %in% sheets) %>% 
        left_join(
          arths,
          by = c('BeatSheetID' = 'BeatSheetFK')) %>%
        # get family diversity per branch
        group_by(TreeFK) %>% 
        summarize(n_families = length(unique(family))) %>% 
    # join back in tree info
    left_join(
      trees,
      by = c('TreeFK' = 'TreeID'))
}

# generate statistics for 100 sets of 30(?) branches (6 per species)
div_stats <- replicate(100, sampleBranches(), simplify = F) %>% 
  # glue all the sample summaries together
  bind_rows()

# run an ANOVA - each branch is treated as a sample, 

div_anova <- aov(
  mean_families ~ Species,
  data = div_stats)

TukeyHSD(div_anova)

biomass_raw <- surveytrees %>% 
  # pull out the surveys on branches from the chosen sample
  filter(Species %in% focal_species) %>% 
  # join to arthropod observations
  left_join(
    arths,
    by = c('BeatSheetID' = 'BeatSheetFK')) %>% 
  # get total mass of arthropods collected in each survey
  group_by(BeatSheetID, TreeFK) %>% 
  summarize(
    total_survey_mass = sum(TotalMass, na.rm = T)) %>% 
  # join back in tree info
  left_join(
    trees,
    by = c('TreeFK' = 'TreeID'))

biomass_stats <- surveytrees %>% 
  # pull out the surveys on branches from the chosen sample
  filter(Species %in% focal_species) %>% 
  # join to arthropod observations
  left_join(
    arths,
    by = c('BeatSheetID' = 'BeatSheetFK')) %>% 
  # get total mass of arthropods collected in each survey
  group_by(BeatSheetID, TreeFK) %>% 
  summarize(
    total_survey_mass = sum(TotalMass, na.rm = T)) %>% 
  # get mean mass per survey for each branch
  group_by(TreeFK) %>% 
  summarize(
    mean_survey_mass = mean(total_survey_mass)) %>% 
    # join back in tree info
  left_join(
    trees,
    by = c('TreeFK' = 'TreeID'))

kruskal.test(
  mean_survey_mass ~ Species,
  data = biomass_stats)

# plotting ----------------------------------------------------------------

biomass_err <- biomass_stats %>% 
  group_by(Species) %>% 
  summarize(
    mean_biomass = mean(mean_survey_mass),
    stdv_biomass = sd(mean_survey_mass))

ggplot(biomass_stats) + 
  geom_point(
    mapping = aes(
      x = Species,
      y = mean_survey_mass,
      color = Species),
    stat = 'summary',
    fun = 'mean',
    size = 3) +
  geom_errorbar(
    data = biomass_err,
    mapping = aes(
      x = Species,
      ymin = mean_biomass - stdv_biomass,
      ymax = mean_biomass + stdv_biomass)) +
  labs(
    color = 'Tree Species',
    y = 'Mean mass observed per survey (mg)') +
  theme(axis.text.x = element_blank())

div_err <- div_stats %>% 
  group_by(Species) %>% 
  summarize(
    mean_families = mean(n_families),
    stdv_families = sd(n_families))

ggplot(div_stats) + 
  geom_point(
    mapping = aes(
      x = Species,
      y = n_families,
      color = Species),
    stat = 'summary',
    fun = 'mean',
    size = 3) +
  geom_errorbar(
    data = div_err,
    mapping = aes(
      x = Species,
      ymin = mean_families - stdv_families,
      ymax = mean_families + stdv_families)) +
  scale_y_continuous(
    limits = c(0,12),
    expand = c(0,0)) +
  labs(
    color = 'Tree Species',
    y = 'Number of Families Observed per Branch') +
  theme(axis.text.x = element_blank())
