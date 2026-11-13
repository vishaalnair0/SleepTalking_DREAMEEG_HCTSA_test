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

% Number of channels
channels = 1:32;

% Dream condition for LV02, LV03, MB01, and MB02
% LV02 & MB01 = DR, LV03 & MB02 = NR

dream_status = [ones(3,1); zeros(3,1); ones(3,1); zeros(3,1)]; % participant order LV followed by MB, 3 cases per participant 

nParticipant = [1 2];

%% Creating channels_to_exclude lsit

channels_to_exclude = [4;8;9;12;13;16;17;21;28;29;30;31;32];

%% Save variables

% save("channel_names.mat","channel_names"); % !! Already done !!

save("Variable_list.mat","dream_status","nParticipant","channels");
save("channels_excluded.mat","channels_to_exclude");






