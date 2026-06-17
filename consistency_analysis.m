%% Computing Consistency - All Channels. Includes statistical testing (EEG param.: 0.75-30Hz, 128Hz Fs)

clear;
clc;

% addpath('D:\DREAMEEG_hctsa\plot_topography');  Lines 6 and 7 are for stats testing, which is not done for this trial
% load('custom_locations.mat'); 

load('D:\DREAMEEG_hctsa\Sleep Talking\Filtered_output_and_operations.mat'); % custom location on local device
load('D:\DREAMEEG_hctsa\Sleep Talking\Direction&Thresholds.mat'); % custom location on local device

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

direction_matrix(:,check_constvalues) = [];
threshold_matrix(:,check_constvalues) = [];

%% Variable List

load("Variable_list.mat");

channel_list = repmat(channels',12,1);

nCases = 1:6;
subject_ID = repmat(nCases, 1,2)';

load("channels_excluded.mat");

load("channel_names.mat");

%% Filter custom_locations 

% ch_indexing = ismember(custom_locations.Number,channels_to_exclude);
% check = find(ch_indexing);

% custom_locations(check,:) = [];

%% Channel Iterations

for channel = 1:length(channels)  % to examine specific channels at line 187, we specify channel number in this line
    channel_data = find(channel_list == channels(channel));
    chandata = main_matrix(channel_data,:);

    for cases = 1:length(nCases)

        rows = find(subject_ID == cases);
        
        rowdata = chandata(rows,:);
        
        rows_condition = dream_status(rows);
        
        rows_dreamful = find(rows_condition);
        rows_dreamless = find(~rows_condition);
        
        rowdata_dreamful = rowdata(rows_dreamful,:);  % we can change to specific feature columns to continue at line 219, otherwise set to :
        rowdata_dreamless = rowdata(rows_dreamless,:); % same comment as above

        rowdata_dreamful_allsubj{cases} = rowdata_dreamful;
        rowdata_dreamless_allsubj{cases} = rowdata_dreamless; %comment this two lines out after completing line 219

        % Compute actual DNV
        DNV_persubject = getDNV(rowdata_dreamful,rowdata_dreamless);
        differences_all{cases} = DNV_persubject;
    end
    
    DNV_allsubjects = vertcat(differences_all{:});
    DNV_allsubjects_allchan{channel} = DNV_allsubjects;
    
    % Compute direction consistencies for one channel each iteration
    clear consistencies_allfeatures;

    for real_f = 1:size(DNV_allsubjects,2)
        count1 = 1;
        for DNV = 1:9:size(DNV_allsubjects,1)
            DNV_vector = DNV_allsubjects(DNV:DNV+8,real_f);
            direction1 = direction_matrix(channel,real_f); 
    
            consistency = getConsistency2r(DNV_vector,direction1); %getConsistency2 computes consistency from DNV values
            consistency_persubject(count1) = consistency;
            count1 = count1 + 1;
        end
        consistencies_allfeatures{:,real_f} = consistency_persubject';
    end

    consistencies_allfeatures = horzcat(consistencies_allfeatures{:});

    mConsistency_allfeatures = mean(consistencies_allfeatures);
    mConsistency_allf_allchan{channel,:} = mConsistency_allfeatures;
end

%% Mean consistency for each features each channel

mConsistency_allf_allchan = vertcat(mConsistency_allf_allchan{:}); % actual consistency

