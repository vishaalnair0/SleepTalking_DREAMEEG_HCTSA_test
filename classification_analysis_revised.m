%% Median Classification for All Channels All Features with 2 leave-one-participant-out Cross-validations - 128Hz FS, 0.75-30Hz Bandpass
clear;
clc;

load('D:\DREAMEEG_hctsa\Sleep Talking\Filtered_output_and_operations.mat');

main_matrix = filtered_output;

%% Dream Status, Channels and Participants

% *IMPORTANT NOTE*: Each of the variable files are specific to each dataset being analyzed, hence this will very from script to script.
% Therefore, this section for the classification_analysis script needs be custom coded

load('Variable_list.mat');

% Input cases are LV02 DR, LV03 NR, MB01 DR, MB02 NR (3 each).
channels = channels(:);
assert(numel(channels) == 32 && numel(unique(channels)) == 32, ...
    'Expected 32 unique original channel IDs in input channel order.');
channel_list = repmat(channels,12,1);
dream_status = [1;1;1;0;0;0;1;1;1;0;0;0];

nCases = 1:2; % Two participant-level CV 
subject_ID = [ones(6,1); 2*ones(6,1)]; % LV = participant 1; MB = participant 2

% Use the 32 x 1 channel-name list, not the older 29 x 2 list.
% Keep your original filename if it already contains the correct version.
if isfile('channel_names.mat')
    load('channel_names.mat');
else
    load('channel_names(2).mat');
end
if ~isequal(size(channel_names), [numel(channels), 1]) && isfile('channel_names(2).mat')
    load('channel_names(2).mat'); % the verified 32 x 1 uploaded file
end
assert(isequal(size(channel_names), [numel(channels), 1]), ...
    'Expected a 32 x 1 channel_names cell array matching original channels.');
assert(size(main_matrix,1) == numel(channel_list) && numel(dream_status) == 12, ...
    'Matrix rows / dream_status do not match 32 channels x 12 observations.');

% Invalid feature values must not silently become incorrect predictions.
assert(isreal(main_matrix) && all(isfinite(main_matrix(:))), ...
    'filtered_output must contain real, finite values before classification.');

%% Loop through all channels to retrieve trainrows and testrows
for channel = 1:length(channels)
    channel_ID = find(channel_list == channels(channel));
    chandata = main_matrix(channel_ID,:);
    
    for feature = 1:size(chandata,2) 
        for test_case = 1: length(nCases)
            
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
            % Do not store a CV threshold as the final classifier.
            
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
                    if test_value >= threshold
                        prediction = 1;
                    else %test_value < threshold
                        prediction = 0;
                    end
                else % median_dreamful <= median_dreamless
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

        % Final classifier uses participant medians, then group medians.
        % CV above trains on the single remaining participant's three epochs
        % per condition and tests all six epochs of the held-out participant.
        for participant = nCases
            participant_median_df(participant,1) = median(chandata( ...
                subject_ID == participant & dream_status == 1,feature));
            participant_median_dl(participant,1) = median(chandata( ...
                subject_ID == participant & dream_status == 0,feature));
        end
        all_median_dreamful = median(participant_median_df);
        all_median_dreamless = median(participant_median_dl);
        threshold_vector{channel,feature} = (all_median_dreamful + all_median_dreamless)/2;
        if all_median_dreamful > all_median_dreamless
            direction{channel,feature} = 1;
        else
            direction{channel,feature} = -1;
        end
    end
    chan_feat_accuracies(channel,:) = feature_accuracies;
end

%% Obtain direction and threshold matrices

threshold_matrix = cell2mat(threshold_vector);
direction_matrix = cell2mat(direction);

% save("Direction&Thresholds.mat","direction_matrix","threshold_matrix"); - comment out if already saved in past run

%% Best Feature Accuracy for each channel

[m,idx] = max(chan_feat_accuracies,[],2);

chan_bestacc_withFeatureID = [m idx];

% save("classification_accuracies_trial.mat","chan_feat_accuracies");
% save("Direction&Thresholds.mat","direction_matrix","threshold_matrix");

%% Visualize the feature values of feature column Y (best-performing) at channel X for each case

% ------------- Identify channels to keep and exclude -------------

load("master_channel_names.mat");

% Rename equivalent labels; data order is unchanged.
channel_names(strcmp(channel_names,'T7')) = {'T3'};
channel_names(strcmp(channel_names,'T8')) = {'T4'};
channel_names(strcmp(channel_names,'P7')) = {'T5'};
channel_names(strcmp(channel_names,'P8')) = {'T6'};
channel_names(strcmp(channel_names,'x01')) = {'O1'}; % Confirmed typo
assert(numel(master_channel_names(:,1)) == 19, 'Expected 19 master channels.');
assert(numel(unique(channel_names)) == 32, 'Duplicate source channel labels.');
assert(all(ismember(master_channel_names(:,1),channel_names)), ...
    'Some master channel names are missing from the original channel list.');

% Identify channels to keep
keep_idx = ismember(channel_names, master_channel_names(:,1));
assert(nnz(keep_idx) == 19, 'Expected exactly 19 retained channels.');

% Preserve the link between filtered row positions and original channel numbers (the latter remain in channel_list).
kept_original_channel_IDs = channels(keep_idx);

% Identify original row numbers to omit
omitted_rows = find(~keep_idx);

% Store omitted channel names
omitted_channels = channel_names(~keep_idx);

% Filter channel_names
channel_names = channel_names(keep_idx);

%% Remove the unused channels from the data matrices

chan_feat_accuracies(omitted_rows,:) = [];
threshold_matrix(omitted_rows,:) = [];
direction_matrix(omitted_rows,:) = [];        % Keep all channel-indexed results aligned
chan_bestacc_withFeatureID(omitted_rows,:) = [];

rows_to_remove = ismember(channel_list, channels(omitted_rows)); % Original IDs, not positions
main_matrix(rows_to_remove,:) = [];
channel_list(rows_to_remove) = [];

%% Plot - edit rows 213 & 214 to change channel and feature of interest

channel_of_interest = find(strcmp(channel_names,'F4')); % locate F4 by name
featurecolumn_of_interest = 4372; % change to feature column of interest

assert(isscalar(channel_of_interest), 'Expected exactly one retained F4 channel.');
assert(featurecolumn_of_interest <= size(main_matrix,2), ...
    'Requested feature column exceeds the available feature count.');
original_channel_ID = kept_original_channel_IDs(channel_of_interest);
onechannel_idx = find(channel_list == original_channel_ID);
assert(numel(onechannel_idx) == numel(dream_status), ...
    'Expected 12 observations for the selected channel. Check matrix row order.'); 

onechannel_featurevalues = main_matrix(onechannel_idx,featurecolumn_of_interest); 
df_idx_onechannel = find(dream_status);
dl_idx_onechannel = find(~dream_status);
onechannel_featurevalues_df = onechannel_featurevalues(df_idx_onechannel);
onechannel_featurevalues_dl = onechannel_featurevalues(dl_idx_onechannel);

figure('Color','White');

% Preserve original positions: LV02, LV03, MB01, MB02
scatter(df_idx_onechannel,onechannel_featurevalues_df', ...
    'DisplayName','Dreamful Condition','MarkerFaceColor','flat');
hold on
scatter(dl_idx_onechannel,onechannel_featurevalues_dl', ...
    'DisplayName','Dreamless Condition','MarkerFaceColor','flat');

% Final threshold uses all participants; it is not either CV threshold.
yline(threshold_matrix(channel_of_interest,featurecolumn_of_interest),'r', ...
    'DisplayName',"Full-data Threshold (descriptive)");

% Separate the two participants
xline(6.5,'k--','HandleVisibility','off');

% Label the center of each three-case recording block
xticks([2 5 8 11]);
xticklabels({'LV02 (DR)','LV03 (NR)','MB01 (DR)','MB02 (NR)'});
xlim([0.5 12.5]);

title("Values for Feature 4372 at Channel F4");
fprintf('F4 (retained channel %d, original channel %d), feature %d: Participant-wise CV accuracy = %.2f%%\n', ...
    channel_of_interest, original_channel_ID, featurecolumn_of_interest, ...
    chan_feat_accuracies(channel_of_interest,featurecolumn_of_interest));

xlabel("Recording (Participant 1: LV | Participant 2: MB)","FontWeight","bold");
ylabel("Feature Value","FontWeight","bold");
legend("Dreamful Condition","Dreamless Condition","Full-data Threshold (descriptive)");
set(gca,'FontSize',12,FontWeight="bold");

% figure('Color','White');
% scatter(1:6,onechannel_featurevalues_df','DisplayName','Dreamful Condition','MarkerFaceColor','flat');
% hold on
% scatter(7:12,onechannel_featurevalues_dl','DisplayName','Dreamless Condition','MarkerFaceColor','flat');
% % Final threshold uses all participants; it is not either CV threshold.
% yline(threshold_matrix(channel_of_interest,featurecolumn_of_interest),'r', ...
%     'DisplayName',"Full-data Threshold (descriptive)");
% title("Values for Feature 4372 at Channel F4");
% fprintf('F4 (retained channel %d, original channel %d), feature %d: Participant-wise CV accuracy = %.2f%%\n', ...
%     channel_of_interest, original_channel_ID, featurecolumn_of_interest, ...
%     chan_feat_accuracies(channel_of_interest,featurecolumn_of_interest));
% xlabel("Cases","FontWeight","bold");
% ylabel("Feature Value","FontWeight","bold");
% legend("Dreamful Condition","Dreamless Condition","Full-data Threshold (descriptive)");
% set(gca,'FontSize',12,FontWeight="bold");


%% Save files for subsequent consistency_analysis.m script (post-classification changes in data dimensions) - comment out if not needed

% save('D:\DREAMEEG_hctsa\Sleep Talking\Variables_for_consistencyanalysis.mat','direction_matrix','channel_names','Operations_postfilter');

%% [BELOW CODE IS SUPPLEMENTARY] Plot checks: participant-wise cross-validation - edit rows 285 & 286 to change channel and feature of interest

channel_of_interest = find(strcmp(channel_names,'F4'));
featurecolumn_of_interest = 4372;

assert(isscalar(channel_of_interest), ...
    'Expected exactly one retained F4 channel.');

original_channel_ID = kept_original_channel_IDs(channel_of_interest);
onechannel_idx = find(channel_list == original_channel_ID);

x = main_matrix(onechannel_idx, featurecolumn_of_interest);
y = dream_status(:);
participant = [ones(6,1); 2*ones(6,1)];

assert(numel(x) == 12, 'Expected 12 cases for this channel.');

% Panel 1: train LV, test MB. Panel 2: train MB, test LV.
test_participants = [2 1];
panel_names = {'Train LV → Test MB', 'Train MB → Test LV'};

fold_accuracy = zeros(2,1);

% Shared y-axis limits
padding = 0.1 * (max(x) - min(x));
if padding == 0
    padding = max(abs(x(1))*0.1, 0.01);
end
shared_ylim = [min(x)-padding, max(x)+padding];

figure('Color','white','Position',[100 100 1100 480]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for panel = 1:2

    held_out = test_participants(panel);
    train = participant ~= held_out;
    test = participant == held_out;

    % Learn the classifier using only the training participant
    median_DR = median(x(train & y == 1));
    median_NR = median(x(train & y == 0));
    fold_threshold = (median_DR + median_NR)/2;

    test_values = x(test);
    test_labels = y(test);

    if median_DR > median_NR
        predicted = test_values >= fold_threshold;
        rule_text = 'Above line = DR; below line = NR';
    else
        predicted = test_values <= fold_threshold;
        rule_text = 'Below line = DR; above line = NR';
    end

    correct = predicted == test_labels;
    fold_accuracy(panel) = 100 * mean(correct);

    % Arrange the held-out cases as DR first, then NR
    plot_order = [find(test_labels == 1); find(test_labels == 0)];
    plot_values = test_values(plot_order);
    plot_labels = test_labels(plot_order);
    plot_correct = correct(plot_order);
    positions = (1:numel(plot_values))';

    nexttile;
    hold on;

    hDR = scatter(positions(plot_labels == 1), ...
        plot_values(plot_labels == 1), 65, ...
        [0 0.4470 0.7410], 'filled');

    hNR = scatter(positions(plot_labels == 0), ...
        plot_values(plot_labels == 0), 65, ...
        [0.8500 0.3250 0.0980], 'filled');

    hThreshold = yline(fold_threshold,'r-', ...
        'LineWidth',1.2);

    % Black crosses identify incorrect held-out predictions
    hWrong = plot(positions(~plot_correct), ...
        plot_values(~plot_correct), 'kx', ...
        'MarkerSize',12,'LineWidth',1.8);

    xlim([0.5 6.5]);
    ylim(shared_ylim);
    xticks(1:6);
    xticklabels({'DR1','DR2','DR3','NR1','NR2','NR3'});

    xlabel('Held-out cases','FontWeight','bold');
    ylabel('Feature Value','FontWeight','bold');

    title({panel_names{panel}, ...
        sprintf('%d/6 correct (%.2f%%)', ...
        sum(correct), fold_accuracy(panel)), ...
        rule_text}, 'FontSize',11);

    legend([hDR hNR hThreshold hWrong], ...
        {'Actual DR','Actual NR','Training threshold','Incorrect'}, ...
        'Location','best');

    set(gca,'FontSize',11);
    box off;
end

sgtitle(sprintf( ...
    'F4 | Feature %d | Participant-wise CV accuracy = %.2f%%', ...
    featurecolumn_of_interest, mean(fold_accuracy)), ...
    'FontWeight','bold');

