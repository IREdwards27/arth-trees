
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

surveytrees %>% 
  group_by(Species) %>% 
  summarize(
    nbranches = length(unique(TreeFK)),
    nsurveys = length(unique(BeatSheetID))) %>% 
  arrange(desc(nbranches)) %>% 
  filter(nbranches > 5)


# resampling --------------------------------------------------------------

sampleBranches <- function(){
  sheets <- map(
    # generate a list of the tree species over the summer with 5 or more branches
    .x = surveytrees %>% 
      group_by(Species) %>% 
      summarize(
        nbranches = length(unique(TreeFK))) %>%
      filter(nbranches > 5) %>% 
      pull(Species),
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
    # pull out the surveys on branches from the chosen sample
    filter(TreeFK %in% sheets) %>% 
    # join to arthropod observations
    left_join(
      arths,
      by = c('BeatSheetID' = 'BeatSheetFK')) %>% 
    # get total mass of arthropods collected in each survey
    group_by(BeatSheetID, TreeFK) %>% 
    summarize(total_survey_mass = sum(TotalMass, na.rm = T)) %>% 
    # get mean mass per survey for each branch
    group_by(TreeFK) %>% 
    summarize(mean_survey_mass = mean(total_survey_mass)) %>% 
    # join in family diversity per branch
    left_join(
      surveytrees %>% 
        filter(TreeFK %in% sheets) %>% 
        left_join(
          arths,
          by = c('BeatSheetID' = 'BeatSheetFK')) %>%
        # get family diversity per branch
        group_by(TreeFK) %>% 
        summarize(n_families = length(unique(family))),
      by = 'TreeFK') %>% 
    # join back in tree info
    left_join(
      trees,
      by = c('TreeFK' = 'TreeID'))
}

# generate statistics for 100 sets of 30(?) branches (6 per species)
bulk_stats <- replicate(100, sampleBranches(), simplify = F) %>% 
  # glue all the sample summaries together
  bind_rows()

# run an ANOVA - each branch is treated as a sample, 
mass_anova <- aov(
  mean_survey_mass ~ Species,
  data = bulk_stats)

TukeyHSD(mass_anova)

div_anova <- aov(
  n_families ~ Species,
  data = bulk_stats)

TukeyHSD(div_anova)
