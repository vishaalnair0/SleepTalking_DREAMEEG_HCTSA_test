%% deGennaro Sleep Talking data - Preprocessing script for 1 participant only

clear;
clc;

addpath 'D:\DREAMEEG_hctsa' %% custom file location where data is stored in local device

% File directory for the cases
file_dir = 'D:\DREAMEEG_hctsa\Sleep Talking\Sleep Talking\Data\PSG';

% Load one file

edf_file = fullfile(file_dir, 'LV02.edf'); % change to choose file

one_subject = edfread(edf_file);

%% Obtain last six 60-second epoch

data_last6min = one_subject(end-359:end,:); % 359 because 6 epochs x 60 seconds = 360

%% Convert the EDF table into a data matrix

labels = data_last6min.Properties.VariableNames;

nChannels = width(data_last6min);
nSamples  = height(data_last6min) * 250; % multiply by 250 because every cell has 250 x 1 double

data_continuous = zeros(nChannels, nSamples);

for ch = 1:nChannels
    data_continuous(ch,:) = cell2mat(data_last6min{:,ch})';
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

nCases = 6;

sixcases_onesubject = zeros(nChannels, epochLength, nCases);

for ep = 1:nCases
    startIdx = (ep-1)*epochLength + 1;
    stopIdx  = ep*epochLength;

    sixcases_onesubject(:,:,ep) = data_resampled(:,startIdx:stopIdx);
end

%% Save

save('data_LV02.mat',"sixcases_onesubject"); % change file name if different participant






