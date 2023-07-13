# arth-trees

data/
CC_fullDataset_2022-11-30.csv: Compiled data from Caterpillars Count! (CC) surveys, updated 2022-11-30.
  ID: the unique identifier of a CC survey.
  UserFKOfObserver: the unique identifier of the CC user who performed the survey.
  PlantFK: the unique identifier of the individual tree where the survey was performed.
  LocalDate: the date on which the survey was conducted.
  julianday: the ordinal date of the year corresponding to the LocalDate.
  julianweek: appears to be deprecated.
  Year: the year during which the survey was conducted, extracted from the LocalDate.
  ObservationMethod: indicates whether the survey was a visual or beat sheet survey.
  surveyNotes: notes for the survey entered into CC by the user.
  WetLeaves: binary, indicating whether leaves surveyed were wet (1) or not (0).
  PlantSpecies: the genus or species of the plant surveyed.
  NumberOfLeaves: the number of leaves included in the survey. Note that for visual surveys this will always be 50.
  AverageLeafLength: the average length of the leaves surveyed, measured in centimeters.
  HerbivoryScore: a number from 0 to 4, indicating the amount of leaf tissue removed as 0%, 1-5%, 6-10%, 11-25%, or >25%.
  arthID: the unique identifier of an arthropod or set of arthropods observed on a CC survey. Multiple arthIDs may correspond to the same ID, but never the opposite.
  OriginalGroup: the arthropod group entered by the CC user for the observed arthropod.
  Group: the arthropod group based on identifications from photos uploaded to iNaturalist.
  Length: the length of the body of the arthropod, not including legs or antennae, measured in millimeters.
  Quantity: the number of arthropods of the same kind included in the observation.
  bugNotes: notes about the arthropod(s) entered by the CC user.
  Pupa: binary, indicating whether the observed arthropod was pupating (1) or not (0). Can only be marked 1 by CC users for moths/butterflies.
  Hairy: binary, indicating whether the observed arthropod was hairy or spiny (1) or not (0). Can only be marked 1 by CC users for caterpillars.
  Rolled: binary, indicating whether the observed arthropod was inside a leaf roll (1) or not (0). Can only be marked 1 by CC users for caterpillars.
  Tented: binary, indicating whether the observed arthropod was found in a silk tent containing multiple caterpillars. (1) or not (0). Can only be marked 1 by CC users for caterpillars.
  OriginalSawfly: binary, indicating whether the CC user identified the arthropod as a sawfly larva (1) or not (0). Can only be marked 1 by CC users for bees/wasps/sawflies.
  Sawfly: binary, indicating whether the observation was identified as a sawfly larva by iNat users based on photos (1) or not (0).
  OriginalBeetleLarva and BeetleLarva: similar to previous two columns, but indicating whether the arthropod was identified as a beetle larva (1) or not (0).
  Biomass_mg: the estimated biomass of the arthropod(s) in the observation, estimated using allometric equations based on Length and Quantity.
  Photo: binary, indicating whether a photo of the arthropod was taken (1) or not (0).
  SiteFK: the unique identifier of the site where the sampled tree is located.
  Circle: the circle at the site where the sampled tree is located.
  Orientation: largely deprecated.
  Code: the three-letter code used to mark the sampled tree.
  Species: the name of the surveyed tree as entered by the CC user.
  IsConifer: binary, indicating whether the sampled tree is coniferous (1) or not (0).
  Name: the name of the site where the surveyed plant is located, set by the CC user and corresponding to SiteFK.
  Latitude and Longitude: the coordinates of the approximate center of the site.
  Region: the region where the survey is located, listed as the two-letter state code for sites in the United States.
  medianGreenup: the median ordinal date when greenup of vegetation occurs each year.
  ebirdCounty: largely deprecated
  cell: largely deprecated
plantName_2023-02-01.csv: Data on the tree species sampled across all Caterpillars Count! sites, updated 2023-02-01.
  cleanedName: the common name of the tree species, retrieved from Caterpillars Count! and corrected to remove typos, extra spaces, or other formatting issues. Multiple common names may refer to the same species.
  sciName: the Latin binomial or genus that corresponds to the common name, determined by Colleen Whitener.
  itis_id: the unique identifier from the Integrated Taxonomic Information System (ITIS) for the tree species.
  rank: either "species" or "genus" depending on the taxonomic rank of sciName.

scripts/
cc_resampling.R: code to analyze and visualize differences in arthropod abundance and diversity from CC across tree species at sites in central NC.
