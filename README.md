# SleepTalking_DREAMEEG_HCTSA_test
This repository includes the script used for hctsa analyses. The test dataset is on deGennaro_SleepTalking dataset. The overarching purpose is to confirm if these scripts can be applied for other datasets with minimal changes in parameters.

# Dataset information:
- Name: DeGennaro_SleepTalking (from DREAM database)
- No. of subject: 12
- No. of samples: 22
- Samples used in this analysis: LV02.edf (dreamful condition) and LV03.edf (dreamless condition) 

All scripts are run on MATLAB 2022b, and hctsa v1.06.
-
The order in which to run the scripts is as follows:
-
  1. preprocessing_onecase.m
  2. run_hctsa_twosubjects
  3. TS_Init_specified_parameters.m
  4. TS_Compute_specified_parameters.m  (This will be ran on MASSIVE)
  5. Assigning_variables.m
  6. Filter_hctsa_output.m
  7. classification_analysis.m
  8. consistency_analysis.m

The final output for each script needs to be saved, to be used in the next script.
-
The repository also includes two functions that need to be used for the consistency_analysis.m script
  1. getDNV.m
  2. getConsistency2r.m 
