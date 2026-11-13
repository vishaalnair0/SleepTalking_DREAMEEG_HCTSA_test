%% deGennaro Sleep Talking data - Preprocessing script for 1 participant only

clear;
clc;

addpath 'D:\DREAMEEG_hctsa' %% custom file location where data is stored in local device

% File directory for the cases
file_dir = 'D:\DREAMEEG_hctsa\Sleep Talking\Sleep Talking\Data\PSG';

% Load one file

edf_file = fullfile(file_dir, 'MB02.edf'); % change to choose file

one_subject = edfread(edf_file);

%% Obtain last three 60-second epochs

data_last3min = one_subject(end-179:end,:); % 179 because 3 epochs x 60 seconds = 180; assumes one-minute EDF records

%% Convert the EDF table into a data matrix

labels = data_last3min.Properties.VariableNames;

nChannels = width(data_last3min);
nSamples  = height(data_last3min) * 250; % multiply by 250 because every cell has 250 x 1 double

data_continuous = zeros(nChannels, nSamples);

for ch = 1:nChannels
    data_continuous(ch,:) = cell2mat(data_last3min{:,ch})';
end

%% Bandpass filter, range 0.75Hz to 30Hz 

fs_original = 250;

data_filtered = zeros(size(data_continuous));

for ch = 1:nChannels
    data_filtered(ch,:) = bandpass( ...
        data_continuous(ch,:), ...
        [0.75 30], ...
        fs_original);
end

%% Downsample to 128Hz 

fs_target = 128;

nSamples_new = floor(size(data_filtered,2) * fs_target / fs_original);

data_resampled = zeros(nChannels, nSamples_new);

for ch = 1:nChannels
    data_resampled(ch,:) = resample( ...
        data_filtered(ch,:), ...
        fs_target, ...
        fs_original);
end

%% Epoching 60-s segments

epochLength = 60 * fs_target;   % 7680 samples

nCases = 3;

threecases_onesubject = zeros(nChannels, epochLength, nCases);

for ep = 1:nCases
    startIdx = (ep-1)*epochLength + 1;
    stopIdx  = ep*epochLength;

    threecases_onesubject(:,:,ep) = data_resampled(:,startIdx:stopIdx);
end

%% Save

save('data_MB02.mat',"threecases_onesubject"); % change file name if different participant






