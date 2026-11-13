%% Run HCTSA on two participants -  6 cases per participant

clear;clc

addpath 'D:\DREAMEEG_hctsa\Sleep Talking' %% custom file location where data is stored in local device

load("data_LV02.mat"); % LV02 DR
data_P1_DR = threecases_onesubject;

load("data_LV03.mat") % LV03 NR
data_P1_NR = threecases_onesubject;

load("data_MB01.mat"); % MB01 DR
data_P2_DR = threecases_onesubject;

load("data_MB02.mat") % Mb02 NR
data_P2_NR = threecases_onesubject;

clear threecases_onesubject;

%% Collapse dimensions to get main data matrix

datapoints = 7680; % expected no. of datapoints at fs = 128 Hz

P1_DR_allcases = reshape(permute(data_P1_DR,[2 1 3]), datapoints, 32*3)'; % (channels*cases)

P1_NR_allcases = reshape(permute(data_P1_NR,[2 1 3]), datapoints, 32*3)';

P2_DR_allcases = reshape(permute(data_P2_DR,[2 1 3]), datapoints, 32*3)';

P2_NR_allcases = reshape(permute(data_P2_NR,[2 1 3]), datapoints, 32*3)';

allP_allcases = [P1_DR_allcases;P1_NR_allcases; P2_DR_allcases; P2_NR_allcases]; % results in a matrix where top half is P1 and bottom half is P2 

%% Assign labels 

nCases = 12; % its 12 instead of 6 because we've combined P1 and P2 matrices in line 25
nChannels = 32;

label = cell(nCases*nChannels, 1);
row_counter = 01;
for cases = 1:nCases
    for ch = 1:nChannels
        names =  ['ID' num2str(cases) '_ch' num2str(ch)];
        label_names{row_counter} = names;
        row_counter = row_counter + 1;
    end
end

label_names = (label_names)';

%% Assign keywords

% NOTE:Preparing the keywords list usually requires us to use loops as there is no specific order to the labels for each case. 
% However for this test set, I have ordered them by participant and dream condition, so preparing the keyword variable is very straightfoward here

dream_status = [ones(3,1); zeros(3,1); ones(3,1); zeros(3,1)]; % participant order LV followed by MB, 3 cases per participant 

keywords = cell(size(dream_status));
keywords(dream_status == 1) = {'Dreamful'};
keywords(dream_status == 0) = {'Dreamless'};

keyword_list = repelem(keywords(:), 32, 1); % 32 = channels


%% Assign input files for HCTSA
timeSeriesData = allP_allcases;
labels = label_names;
keywords = keyword_list;
    
% Save input files -MAT 
save('AllP_AllCases.mat','timeSeriesData','labels','keywords');


% ------------------------------------------------ TS_Initialize on a separate script -------------------------------------------------%














