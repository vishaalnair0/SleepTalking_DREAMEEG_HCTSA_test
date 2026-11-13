%% Computing Direction Consistency - LV and MB
% EEG: 0.75-30 Hz, 128 Hz. Two participants, three DR and three NR cases each.
% Descriptive analysis: the classification directions were fitted on these data.
clear;
clc;

%% Load feature values and classification directions

load('D:\DREAMEEG_hctsa\Sleep Talking\Filtered_output_and_operations.mat');


% FIRST save these variables at the END of the amended classification script:
% save('D:\DREAMEEG_hctsa\Sleep Talking\directions_and_thresholds.mat', ...
%     'direction_matrix','channel_names','Operations_postfilter');
% channel_names must be the 19 retained labels aligned with direction_matrix.
D = load('Variables_for_consistencyanalysis.mat');

assert(all(isfield(D,{'direction_matrix','channel_names','Operations_postfilter'})), ...
    'Re-save classification directions with channel_names and Operations_postfilter (see above).');
assert(isequal(D.Operations_postfilter,Operations_postfilter), ...
    'Classification and consistency feature lists/order differ. Use the same HCTSA output.');

%% Variable List - AMENDED for LV02, LV03, MB01, MB02
S = load('channel_names.mat','channel_names');
M = load('master_channel_names.mat','master_channel_names');
original_channel_names = S.channel_names(:,1);
master_names = M.master_channel_names(:,1); % The master file is 19 x 2.

nParticipants = 1:2;
subject_ID = [ones(6,1); 2*ones(6,1)];
dream_status = [1;1;1;0;0;0;1;1;1;0;0;0];
channel_list = repmat((1:32)',12,1);
participant_names = {'LV';'MB'};

assert(iscell(original_channel_names) && numel(original_channel_names)==32, ...
    'Expected 32 original channel labels in the input data order.');
assert(size(filtered_output,1)==384, 'Expected 12 cases x 32 channels = 384 rows.');
assert(numel(master_names)==19, 'Expected 19 master channel names.');
assert(isreal(filtered_output) && all(isfinite(filtered_output(:))), ...
    'Feature values must be real and finite before normalization.');
assert(size(D.direction_matrix,1)==numel(D.channel_names) && ...
    size(D.direction_matrix,2)==size(filtered_output,2), ...
    'Classification direction dimensions do not match the saved labels/features.');
assert(all(ismember(D.direction_matrix(:),[-1 1])), ...
    'Classification directions must be +1 (DR higher) or -1 (DR lower).');

%% Match channel labels - names change, original data positions do not
original_channel_names(strcmp(original_channel_names,'T7')) = {'T3'};
original_channel_names(strcmp(original_channel_names,'T8')) = {'T4'};
original_channel_names(strcmp(original_channel_names,'P7')) = {'T5'};
original_channel_names(strcmp(original_channel_names,'P8')) = {'T6'};
original_channel_names(strcmp(original_channel_names,'x01')) = {'O1'}; 

[found,source_channel_indices] = ismember(master_names,original_channel_names);
assert(all(found) && numel(unique(source_channel_indices))==19, ...
    'Could not match all 19 master channels to distinct source channels.');
assert(numel(unique(original_channel_names))==32, 'Duplicate original channel labels.');

% Match classifier rows by NAME, since classification retained source order.
[found_direction,direction_rows] = ismember(master_names,D.channel_names(:,1));
assert(all(found_direction) && numel(unique(D.channel_names(:,1)))==numel(D.channel_names), ...
    'Saved classifier channel labels are missing or duplicated.');
direction_matrix = D.direction_matrix(direction_rows,:);
channel_names = master_names;

%% Normalize and remove invalid/constant features
main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
assert(isequal(size(main_matrix),size(filtered_output)), ...
    'Normalization must preserve the original matrix dimensions.');

% Apply the SAME feature mask to values, operation metadata, and directions.
valid_features = all(isfinite(main_matrix),1) & std(main_matrix,0,1)>0;
feature_columns_original = find(valid_features); % Columns in filtered_output
main_matrix = main_matrix(:,valid_features);
Operations_postfilter = Operations_postfilter(valid_features,:);
direction_matrix = direction_matrix(:,valid_features);
assert(~isempty(main_matrix), 'No valid, nonconstant features remain.');

%% Channel Iterations
nFeatures = size(main_matrix,2);
% Dimensions: participant x feature x channel.
consistency_perparticipant = zeros(2,nFeatures,19);
DNV_allsubjects_allchan = cell(19,1);

for channel = 1:19
    channel_data = find(channel_list == source_channel_indices(channel));
    chandata = main_matrix(channel_data,:);
    differences_all = cell(2,1);

    for participant = nParticipants
        rows_dreamful = subject_ID == participant & dream_status == 1;
        rows_dreamless = subject_ID == participant & dream_status == 0;
        rowdata_dreamful = chandata(rows_dreamful,:);
        rowdata_dreamless = chandata(rows_dreamless,:);

        % All nine within-participant pairs: DR1-NR1, DR1-NR2, ... DR3-NR3.
        % Never compare LV epochs against MB epochs.
        DNV_persubject = zeros(9,nFeatures);
        pair = 0;
        for dr = 1:3
            for nr = 1:3
                pair = pair + 1;
                DNV_persubject(pair,:) = rowdata_dreamful(dr,:) - rowdata_dreamless(nr,:);
            end
        end
        differences_all{participant} = DNV_persubject;

        % Expected sign comes from the corresponding classification direction.
        % Match = 1, opposite = 0, exact tie = 0.5.
        expected_differences = bsxfun(@times,DNV_persubject,direction_matrix(channel,:));
        pair_scores = double(expected_differences > 0) + ...
            0.5 * double(expected_differences == 0);
        consistency_perparticipant(participant,:,channel) = mean(pair_scores,1);
    end
    DNV_allsubjects_allchan{channel} = vertcat(differences_all{:}); % 18 x features
end

%% Mean consistency for each feature and channel
mConsistency_allf_allchan = zeros(19,nFeatures);
for channel = 1:19
    mConsistency_allf_allchan(channel,:) = mean(consistency_perparticipant(:,:,channel),1);
end

%% Visualize descriptive consistency for each channel
% No old null distribution is reused. The 0.5 line is not a significance cutoff.
figure('Color','white');
for ch = 1:19
    subplot(5,4,ch);
    histogram(mConsistency_allf_allchan(ch,:),0:0.05:1, ...
        'DisplayStyle','stairs','LineWidth',0.75);
    hold on;
    xline(0.5,'k--');
    title(channel_names{ch});
    xlabel('Mean direction consistency');
    ylabel('Number of features');
    xlim([0 1]);
end

%% Find feature with highest consistency at each channel
[m,idx] = max(mConsistency_allf_allchan,[],2);
chan_bestconsistency_withFeatureID = [m idx]; % idx indexes the retained columns
best_feature_columns_original = reshape(feature_columns_original(idx),[],1);
% best_feature_columns_original maps back to the classification input columns.

% Optional save:
% save(fullfile(file_dir,'consistency_results_LV_MB.mat'), ...
%     'mConsistency_allf_allchan','consistency_perparticipant', ...
%     'channel_names','participant_names','direction_matrix', ...
%     'Operations_postfilter','feature_columns_original', ...
%     'chan_bestconsistency_withFeatureID','best_feature_columns_original');

%% Visualize feature values: P3, original feature column 4268 - make edits for different channel and feature of interest

channel_of_interest = find(strcmp(channel_names,'P3'));
featurecolumn_of_interest = 4268;

feature_idx = featurecolumn_of_interest;

assert(isscalar(channel_of_interest), ...
    'Expected exactly one retained P3 channel.');
assert(feature_idx >= 1 && feature_idx <= size(main_matrix,2), ...
    'Requested feature column is outside the retained feature matrix.');

% Retrieve all 12 cases in their original order
original_channel_ID = source_channel_indices(channel_of_interest);
onechannel_idx = find(channel_list == original_channel_ID);
onechannel_featurevalues = main_matrix(onechannel_idx,feature_idx);

df_idx = find(dream_status == 1);
dl_idx = find(dream_status == 0);

figure('Color','white');
scatter(df_idx,onechannel_featurevalues(df_idx), ...00
    60,[0 0.4470 0.7410],'filled', ...
    'DisplayName','Dreamful Condition');
hold on;
scatter(dl_idx,onechannel_featurevalues(dl_idx), ...
    60,[0.8500 0.3250 0.0980],'filled', ...
    'DisplayName','Dreamless Condition');

xline(6.5,'k--','HandleVisibility','off');

xticks([2 5 8 11]);
xticklabels({'LV02 (DR)','LV03 (NR)','MB01 (DR)','MB02 (NR)'});
xlim([0.5 12.5]);

% Classification-derived direction used for consistency scoring
expected_direction = direction_matrix(channel_of_interest,feature_idx);
if expected_direction == 1
    direction_text = 'Expected direction: DR > NR';
else
    direction_text = 'Expected direction: DR < NR';
end

scores = consistency_perparticipant(:,feature_idx,channel_of_interest);

title({sprintf('P3 | Feature column %d',featurecolumn_of_interest), ...
    direction_text, ...
    sprintf('Consistency: LV = %.1f%% | MB = %.1f%% | Mean = %.1f%%', ...
    100*scores(1),100*scores(2),100*mean(scores))});

xlabel('Recording (Participant 1: LV | Participant 2: MB)', ...
    'FontWeight','bold');
ylabel('Normalized Feature Value','FontWeight','bold');
legend('Location','best');
set(gca,'FontSize',12,'FontWeight','bold');





