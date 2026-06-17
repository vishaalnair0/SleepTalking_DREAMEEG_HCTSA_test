%% Median Classification for All Channels All Features with 9 Cross-Validations - 128Hz FS, 0.75-30Hz Bandpass
clear;
clc;

load('D:\DREAMEEG_hctsa\Sleep Talking\Filtered_output_and_operations.mat');

main_matrix = filtered_output;

%% Dream Status, Channels and Participants

% *IMPORTANT NOTE*: Each of the variable files are specific to each dataset being analyzed, hence this will very from script to script.
% Therefore, this section for the classification_analysis script needs be custom coded

load('Variable_list.mat');

channel_list = repmat(channels',12,1);

nCases = 1:6;
subject_ID = repmat(nCases, 1,2)';

load('channels_excluded.mat');

load('channel_names.mat');

%% Loop through all channels to retrieve trainrows and testrows
for channel = 1:length(channels)
    channel_ID = find(channel_list == channels(channel));
    chandata = main_matrix(channel_ID,:);
    
    for feature = 1:size(chandata,2) 
        for teqst_case = 1: length(nCases)
            
            trainrows = find(~(subject_ID == test_case));
            
            traindata = chandata(trainrows,feature);
            
            trainrows_condition = dream_status(trainrows);
            
            trainrows_dreamful = find(trainrows_condition);
            trainrows_dreamless = find(~trainrows_condition);
            
            traindata_dreamful = traindata(trainrows_dreamful);
            traindata_dreamless = traindata(trainrows_dreamless);
            
            median_dreamful = median(traindata_dreamful);
            median_dreamless = median(traindata_dreamless); 
            
            threshold = (median_dreamful + median_dreamless)/2;
            threshold_vector{channel,feature} = threshold;
            
            % Test Data here
            
            testrows = find(subject_ID == test_case);
            
            testdata = chandata(testrows,feature);
            
            testrows_condition = dream_status(testrows);
            
            testrows_dreamful = find(testrows_condition);
            testrows_dreamless = find(~testrows_condition);
            
            testdata_dreamful = testdata(testrows_dreamful);
            testdata_dreamless = testdata(testrows_dreamless);
            
            testvalues = [testdata_dreamful;testdata_dreamless];
            test_labels = sort(testrows_condition,"descend");
            
            %% loop through test data and save prediction
            row_counter = 1;
            clear prediction_list;
            
            for i = 1:size(testvalues,1)
                test_value = testvalues(i);
                if median_dreamful > median_dreamless
                    direction{channel,feature} = 1;
                    if test_value >= threshold
                        prediction = 1;
                    else %test_value < threshold
                        prediction = 0;
                    end
                else % median_dreamful <= median_dreamless
                    direction{channel,feature} = -1;
                    if test_value <= threshold
                        prediction = 1;
                    else %test_value > threshold
                        prediction = 0;
                    end
                end 
                prediction_list{row_counter} = prediction;
                row_counter = row_counter + 1;
            end
            
            prediction_list = cell2mat(prediction_list);
            
            %% Accuracy check
            
            accurate = 0; 
            
            for c = 1:size(prediction_list,2)
                if prediction_list(1,c) == test_labels(c,1)
                    accurate = accurate + 1;
                end
            end
            acc_percentage = (accurate/size(prediction_list,2))*100;
        
            acc_matrix(test_case,:) = acc_percentage;

        end
        mean_accuracy = mean(acc_matrix, 1);
        feature_accuracies(:,feature) = mean_accuracy;
    end
    chan_feat_accuracies(channel,:) = feature_accuracies;
end

%% Obtain direction and threshold matrices

threshold_matrix = cell2mat(threshold_vector);
direction_matrix = cell2mat(direction);

%% Best Feature Accuracy for each channel

[m,idx] = max(chan_feat_accuracies,[],2);

chan_bestacc_withFeatureID = [m idx];

save("classification_accuracies_trial.mat","chan_feat_accuracies");
save("Direction&Thresholds.mat","direction_matrix","threshold_matrix");
