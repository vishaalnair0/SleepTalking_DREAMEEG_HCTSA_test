%% deGennaro Sleep Talking data - Preprocessing script for 1 participant only

clear;
clc;

addpath 'D:\DREAMEEG_hctsa' %% custom file location where data is stored in local device

% File directory for the cases
file_dir = 'D:\DREAMEEG_hctsa\Sleep Talking\Sleep Talking\Data\PSG';

% Load one file

edf_file = fullfile(file_dir, 'LV03.edf'); % change to choose file

subject_one = edfread(edf_file);

%% Convert the EDF channels into data matrix

labels = subject_one.Properties.VariableNames;

nChannels = width(subject_one);
nSamples  = height(subject_one) * 250;

data_continuous = zeros(nChannels, nSamples);

for ch = 1:nChannels
    data_continuous(ch,:) = cell2mat(subject_one{:,ch})';
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

%% Segment 60-second epochs, for the last 6 epochs prior to awakening

epochLength = 60 * fs_target;   % 7680 samples

nCases = 6;

data_one_subject = zeros(nChannels, epochLength, nCases);

for c = 1:nCases
    startIdx = (c-1)*epochLength + 1;
    stopIdx  = c*epochLength;

    data_one_subject(:,:,c) = data_resampled(:,startIdx:stopIdx);
end

%% Save

save('data_LV03.mat',"data_one_subject"); % change file name if different participant




