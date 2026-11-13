%% HCTSA matrix visualization - feature values from 128Hz resampled and 0.75-30Hz bandpass filtered data

clear;clc;

load('D:\DREAMEEG_hctsa\Sleep Talking\Filtered_output_and_operations.mat');

main_matrix = BF_NormalizeMatrix(filtered_output,'mixedSigmoid');
check_constvalues = find(std(main_matrix)==0);
main_matrix(:,check_constvalues) = [];
Operations_postfilter(check_constvalues,:) = [];

%% Variables List

% load('channels_excluded.mat');
load('Variable_list.mat');
load('channel_names.mat');

assert(isequal(dream_status(:), [1;1;1;0;0;0;1;1;1;0;0;0]), ...
    'Expected LV02 DR, LV03 NR, MB01 DR, MB02 NR: three cases each.');
assert(size(main_matrix,1) == 384, 'Expected 12 cases x 32 channels = 384 rows.');

dreamstate_list = repelem(dream_status(:), 32, 1); % LV followed by MB dream conditions

channel_list = repmat((1:32)', 12, 1);

channels_to_keep = load("master_channel_names.mat");

%% Match the 19 master names to their ORIGINAL 32-channel positions.
% All four recordings must use the same original channel order.
original_channel_names = channel_names(:,1);
master_names = channels_to_keep.master_channel_names(:,1);
assert(numel(original_channel_names) == 32, 'Expected 32 original channel names.');
assert(numel(master_names) == 19, 'Expected 19 master channel names.');

% Rename labels only; the data rows stay in their original positions.
original_channel_names(strcmp(original_channel_names,'T7')) = {'T3'};
original_channel_names(strcmp(original_channel_names,'T8')) = {'T4'};
original_channel_names(strcmp(original_channel_names,'P7')) = {'T5'};
original_channel_names(strcmp(original_channel_names,'P8')) = {'T6'};
original_channel_names(strcmp(original_channel_names,'x01')) = {'O1'}; % Confirmed typo

[found, source_channel_indices] = ismember(master_names, original_channel_names);
if ~all(found)
    disp('Missing master channel names:');
    disp(master_names(~found));
end
assert(all(found), 'Some of the 19 master channels could not be found.');
assert(numel(unique(original_channel_names)) == 32, ...
    'Duplicate source labels after renaming. Check the channel list.');
assert(numel(unique(source_channel_indices)) == 19, ...
    'Master channels must map to 19 distinct source channels.');
channel_names = master_names; % Plot labels now follow the 19-channel master order.

%% Sort by Dream Condition

df_idx = find(dreamstate_list);
dl_idx = find(~dreamstate_list);

df_main_matrix = main_matrix(df_idx,:);
dl_main_matrix = main_matrix(dl_idx,:);


%% Channel-sorted Data Matrix

% Indices refer to rows AFTER selecting the dream condition.
channels_df = channel_list(df_idx);
channels_dl = channel_list(dl_idx);
assert(isequal(channels_df,channels_dl), 'DR and NR channel orders must match.');
rows_perblock = numel(df_idx) / 32; % Six cases per channel per condition
rows_per_condition_plot = 19 * rows_perblock; % 114 rows
chanIdx_list = cell(19,1);
for channel = 1:19
    chanID_idx = find(channels_df == source_channel_indices(channel));
    assert(numel(chanID_idx) == rows_perblock, 'Unexpected case count for channel.');
    chanIdx_list{channel} = chanID_idx;
end
chanIdx_list = vertcat(chanIdx_list{:});

% Each channel now contains three LV cases followed by three MB cases.


%% Sort Matrix by both Channel and Dream Condition

df_matrix_chansorted = df_main_matrix(chanIdx_list,:);
dl_matrix_chansorted = dl_main_matrix(chanIdx_list,:);

%% Omit channels that will not be included
% Already done by selecting the 19 source_channel_indices above.

matrix_sortedfinal = [df_matrix_chansorted;dl_matrix_chansorted];

%% Compute correlation distance matrix

corr_dist = 1 - corr(matrix_sortedfinal,'type','Spearman');

check_Diag = diag(corr_dist);
NaN_idx = ~isfinite(check_Diag); % Remove undefined correlations

NaN_cols = find(NaN_idx);

matrix_sortedfinal(:,NaN_cols) = [];
Operations_postfilter(NaN_cols,:) = [];

corr_dist = 1 - corr(matrix_sortedfinal,'type','Spearman');

assert(size(matrix_sortedfinal,2) >= 2, 'At least two valid features are required.');
assert(all(isfinite(corr_dist(:))), 'Undefined correlations remain.');

%% Cluster tree

tree = linkage(squareform(corr_dist), 'average');
[h, T, order] = dendrogram(tree, 0);

%% HCTSA feature matrix final visualization - sorted by dream cond., chan, corr. clustering order
% 
% channel_names(channels_to_not_included,:) = [];
% channel_names = channel_names(ismember(channel_names, channels_to_keep.master_channel_names(:,1)));

figure('Color','white');
imagesc(matrix_sortedfinal(:, order));
cb = colorbar();
ylabel(cb,"Feature Value");
ylabelHandle = ylabel("Time-Series Sorted by Channel and Dream Condition",FontWeight="bold");
xlabel("Features sorted by Hier. Clustering");
yline(rows_per_condition_plot + 0.5,Color="red",LineWidth=2.5);

% Combine the tick positions
% Tick at the center of each six-case channel block.
channel_centers = (0:18) * rows_perblock + (rows_perblock + 1)/2;
ytick_positions = [channel_centers, channel_centers + rows_per_condition_plot];

% Repeat the channel names for both halves
ytick_labels = repmat(channel_names(:,1), 2, 1);

% Set the combined tick positions and labels
set(gca, 'YTick', ytick_positions);
set(gca, 'YTickLabel', ytick_labels);

%set(gca,'YTick',(1:27:513));
%set(gca,'YTickLabel',channel_names(:,1));

% Adjust position of the ylabel
ylabelPosition = get(ylabelHandle, 'Position');
ylabelPosition(1) = ylabelPosition(1); % Move the y-label further to the left
set(ylabelHandle, 'Position', ylabelPosition);

%% HCTSA feature matrix final visualization - alternative y-axis labelling and order

ch_names_toReorder_idx = [1;2;3;4;5;6;17;7;8;9;10;18;11;12;13;14;19;15;16];
channel_names_reordered = channel_names(ch_names_toReorder_idx);

matrix_sortedfinal_df = matrix_sortedfinal(1:rows_per_condition_plot,:);
matrix_sortedfinal_dl = matrix_sortedfinal(rows_per_condition_plot+1:end,:);

% rows_perblock = 6, set above (three cases per participant per condition).
blocks_df = mat2cell(matrix_sortedfinal_df, repmat(rows_perblock,19,1),size(matrix_sortedfinal_df,2));
blocks_dl = mat2cell(matrix_sortedfinal_dl, repmat(rows_perblock,19,1),size(matrix_sortedfinal_dl,2));

reordered_blocks_df = blocks_df(ch_names_toReorder_idx);
reordered_blocks_dl = blocks_dl(ch_names_toReorder_idx);

reordered_df_matrix = vertcat(reordered_blocks_df{:});
reordered_dl_matrix = vertcat(reordered_blocks_dl{:});

matrix_sortedfinal_newsort = [reordered_df_matrix;reordered_dl_matrix];

% Plot
figure('Color','white');
imagesc(matrix_sortedfinal_newsort(:, order));
cb = colorbar();
ylabel(cb,"Feature Value");
ylabelHandle = ylabel("Time-Series Sorted by Channel and Dream Condition",FontWeight="bold");
xlabel("Features sorted by Hier. Clustering");
yline(rows_per_condition_plot + 0.5,Color="red",LineWidth=2.5);

% Y-ticks
tick1_blocks = [1:6 7];     % Blocks 1-6 and 17 are now in positions 1-6 and 7
tick2_blocks = [8:11 12];   % Blocks 7-10 and 18 are now in positions 8-11 and 12
tick3_blocks = 13:19;       % Posterior: T5, T6, P3, P4, Pz, O1, O2


% Compute region centers within one condition (114 rows).
tick1_start = ((min(tick1_blocks)-1) * rows_perblock + 1 ...
    + max(tick1_blocks) * rows_perblock) / 2;
tick2_start = ((min(tick2_blocks)-1) * rows_perblock + 1 ...
    + max(tick2_blocks) * rows_perblock) / 2;
tick3_start = ((min(tick3_blocks)-1) * rows_perblock + 1 ...
    + max(tick3_blocks) * rows_perblock) / 2;

tick_half = [tick1_start; tick2_start; tick3_start];

ytick_positions = [tick_half; tick_half + rows_per_condition_plot];
ytick_labels = {'Frontal', 'Central', 'Posterior', 'Frontal', 'Central', 'Posterior'};

yticks(ytick_positions);
yticklabels(ytick_labels);
set(gca,'FontSize',12);

% Bold all tick labels and set font size
ax = gca;
set(ax, 'FontSize', 12, 'FontWeight', 'bold');
set(cb, 'FontSize', 12, 'FontWeight', 'bold');

% STEP 1: Create sufficient space on the left
ax.Units = 'normalized';
ax.Position = [0.17 0.12 0.72 0.80]; % left, bottom, width, height]

% STEP 2: Position ONLY the general y-axis label (NOTE: I move y-axis label to the left to create space for manual annotations)
yl = ax.YLabel;
yl.Units = 'normalized';
yl.Position = [-0.17 0.50 0]; %[how far the general y-axis label sits, vertically centered label, 0]

%% Delta matrix: Dreamful - Dreamless

delta_matrix = reordered_df_matrix - reordered_dl_matrix;

figure('Color','white');
imagesc(delta_matrix(:, order));

% Symmetrical colour limits around zero
maxVal = max(abs(delta_matrix(:)));
if maxVal > 0
    clim([-maxVal maxVal]);
end

% Blue = negative, white = zero, red = positive
n = 128;
cmap = [linspace(0,1,n)' linspace(0,1,n)' ones(n,1);
        ones(n,1) linspace(1,0,n)' linspace(1,0,n)'];
colormap(gca, cmap);

cb = colorbar();
ylabel(cb, 'DR - NR');

xlabel('Features sorted by Hier. Clustering');
ylabel('Time-Series Sorted by Channel', 'FontWeight','bold');

yticks(tick_half);
yticklabels({'Frontal','Central','Posterior'});
set(gca,'FontSize',12);

% Bold all tick labels and set font size
ax = gca;
set(ax, 'FontSize', 12, 'FontWeight', 'bold');
set(cb, 'FontSize', 12, 'FontWeight', 'bold');
