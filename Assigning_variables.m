%% This script creates the variables list for the Sleep-talking EDF files

% This is only for a trial run, not the full dataset

clear;
clc;

% File directory for the cases
file_dir = 'D:\DREAMEEG_hctsa\Sleep Talking\Sleep Talking\Data\PSG';

% Load one file

edf_file = fullfile(file_dir, 'LV03.edf'); % change to choose file

subject_one = edfread(edf_file);

%% Creating channel_name variable

labels = subject_one.Properties.VariableNames;
labels = [labels; num2cell(1:32)];

channel_names = (labels)'; % I transpose so that it is easier to work with given the later data matrix is channel X features

%% Creating variables_list 

channels = 1:32;

dream_status = NaN(12,1); % 12 = number of cases - 6 cases per participant data

dream_status(1:6,1) = 1;
dream_status(7:12,1) = 0; % we label it this way because I've ordered DF condition at the first half of the matrix, and DL in the bottom half

nParticipant = [1 2];

%% Creating channels_to_exclude lsit

channels_to_exclude = [4;8;9;12;13;16;17;21;28;29;30;31;32];

%% Save variables

save("channel_names.mat","channel_names");
save("Variable_list.mat","dream_status","nParticipant","channels");
save("channels_excluded.mat","channels_to_exclude");






