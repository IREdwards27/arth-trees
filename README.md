# arth-trees

This project focused on identifying differences in arthropod abundance and diversity across several common tree species in central NC.

data/

CC_fullDataset_2022-11-30.csv: Compiled data from Caterpillars Count! (CC) surveys, updated 2022-11-30.
  ID: the unique identifier of a CC survey.
  UserFKOfObserver: the unique identifier of the CC user who performed the survey.
  PlantFK: the unique identifier of the individual tree where the survey was performed.
  LocalDate: the date on which the survey was conducted.
  julianday: the ordinal date of the year corresponding to the LocalDate.
  julianweek: appears to be deprecated.
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

species_summary: information on branches at sites sampled by Indigo Roper-Edwards and/or the Hurlbert Lab in 2022
  Species: the Latin binomial of a tree species found at one or more of the following sites: Duke Forest Korstian Division, Eno River State Park, Johnston Mill Nature Preserve, NC State University Campus, NC Botanical Garden, Prairie Ridge Ecostation, UNC Campus.
  n_sites: the number of the above sites at which one or more trees of the species are tagged for Caterpillars Count! sampling.
  n_branches: the total number of trees of the species found across all seven sites.
  n_surveys: the total number of surveys conducted on trees of the species from 2017-2022.
  
summer2022/

beat_sheets_2022-12-02.csv: data on beat sheet surveys performed by Indigo Roper-Edwards or assistants in summer of 2022.
  BeatSheetID: the unique identifier for an individual survey.
  TreeFK: the unique identifier for the tree on which the survey was performed.
  Observer: the first name of the surveyor.
  WetLeaves - Notes: see descriptions for CC_fullDataset.
  Checks: the number of times the vial of arthropods collected was checked for correct identifications. NA if no arthropods were observed.
  
circles_2022-12-02.csv: data on the Caterpillars Count! circles where beat sheet surveys were performed.
  CircleID: the unique identifier for the circle, composed of the site initials and the circle number.
  SiteFK: the unique identifier of the site where the circle is located.
  LitterDepth: the depth of the litter layer at the circle, measured in millimeters.
  PercentCanopyCover: an estimate of the canopy cover at the circle.
  HerbCover: an estimate of the herbaceous plant cover at the circle, as classes 1 (0-25%), 2 (26-50%), 3 (51-75%), or 4 (76-100%).
  DistanceToEdgem: the distance from the center of the circle to the nearest paved road, measured in meters.
  
foliage_arths_2022-12-02.csv: data on arthropods collected via beat sheets.
  FoliageArthID: the unique identifier for one or more arthropods of the same type on a survey.
  BeatSheetFK: the unique identifier for the beat sheet on which arthropods were collected.
  CCGroup - CCNotes: see descriptions for CC_fullDataset.
  TaxonLevel: the taxonomic level to which arthropods were identified.
  TotalMass: the mass of all arthropods in the observations, measured in milligrams.
  NumberWeighed: the number of arthropods weighed to determine TotalMass, differing from Number if some were not successfully collected.
  TaxonID: the unique identifier from ITIS or individually generated for the taxon observed.
  
sites_2022-09-19.csv: data on sites where beat sheets were performed
  SiteID: the unique identifier for the site used for analysis.
  CCID: the unique identifier for the site used in the Caterpillars Count! system.

taxa_2022-12-02.csv: data on taxa observed on beat sheets
  TaxonID: see foliage_arths.
  taxon: the taxon name used to search ITIS for further taxonomic information.

trees_2022-08-16.csv: data on the trees where beat sheets were performed
  TreeID: the unique identifier of the tree used for analysis, corresponding to its physical Caterpillars Count! tag code.
  CCID: the unique identifier of the tree used in the Caterpillars Count! system.
  CircleFK: the unique identifier of the circle where the tree was located.

TRY/: data downloaded from the TRY database of plant traits. Data have been processed as categorical or mean values by species, but column names come from the TRY database.
  public/: data open for public use.
  all/: all data available from TRY, some with limited use.

scripts/

cc_resampling.R: code to analyze and visualize differences in arthropod abundance and diversity from CC across tree species at sites in central NC

cc_species_by_scale.R: code to assess the number of surveys conducted by tree species across several geographic scales

summer2023_resampling.R: code to analyze and visualize differences in arthropod abundance and diversity across tree species in central NC based on samples collected from May-July 2022 by Indigo Roper-Edwards.

TRY_analysis.R: code to analyze relationships between plant traits from the TRY database and arthropod abundance and diversity.
