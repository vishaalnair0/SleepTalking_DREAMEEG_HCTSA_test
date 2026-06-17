%% Run HCTSA on two participants -  6 cases per participant

clear;clc

addpath 'D:\DREAMEEG_hctsa\Sleep Talking' %% custom file location where data is stored in local device

load("data_LV02.mat"); % dreamful condition
data_P1 = data_one_subject;

load("data_LV03.mat") % dreamless condition
data_P2 = data_one_subject;

clear data_one_subject;

%% Collapse dimensions to get main data matrix

datapoints = 7680; 

P1_allcases = reshape(data_P1, datapoints, (32*6)); % (channels*cases)
P1_allcases = (P1_allcases)'; % transpose matrix

P2_allcases = reshape(data_P2, datapoints, (32*6));
P2_allcases = (P2_allcases)'; % transpose matrix

allP_allcases = [P1_allcases;P2_allcases]; % results in a matrix where top half is P1 and bottom half is P2 (DF followed by DL)

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
% However here, I have ordered them to be dreamful(DF) followed by dreamless(DL), so preparing the keyword variable is very straightfoward here

rows = 384; % no. of rows for allP_allcases

keyword_list = cell(rows, 1); 

keyword_list(1:192)   = repmat({'Dreamful'}, 192, 1);
keyword_list(193:384) = repmat({'Dreamless'}, 192, 1);

%% Assign input files for HCTSA
timeSeriesData = allP_allcases;
labels = label_names;
keywords = keyword_list;
    
% Save input files -MAT 
save('AllP_AllCases.mat','timeSeriesData','labels','keywords');


% ------------------------------------------------ TS_Initialize on a separate script -------------------------------------------------%














