clc; clear;
rng(1)
data = readtable('insurence_claims.csv');
size(data)
%%
%remove duplicates
data = unique(data);
size(data)

%%
%remove missing values
missing= ismissing(data);

for i = 1:4415
    for j = 1:21
        if missing(i,j) == 1
            data(i,:) = [];
        end
    end
end
size(data)
%%
%remove claim id and policy id
data.claimid=[];
data.policyid=[];
size(data)
%%
%update the format of data
data.policy_date = datetime(data.policy_date, 'InputFormat', 'MM/dd/yyyy');
data.incident_date = datetime(data.incident_date, 'InputFormat', 'MM/dd/yyyy');
data.dob = datetime(data.dob, 'InputFormat', 'MM/dd/yyyy');
data.occupancy_date = datetime(data.dob, 'InputFormat', 'MM/dd/yyyy');
%%
%create new variable age up to incident date
data.age = fix(years(data.incident_date-data.dob));
%remove dof variable
data.dob = [];
%%
%creating a new variable of policy duraion - valid durationn of policy
%until the incident date
data.policy_duration = days(data.incident_date-data.policy_date);
%duration of occupancy 
date.occu_duration = days(data.incident_date-data.occupancy_date);
%remove variables
data.incident_date = [];
data.policy_date = [];
data.occupancy_date = [];
data.job_start_date = [];
%%
%(ii)	Create a new data set which includes records with all fraudulence 
%claims and 500 randomly selected non-fraudulence claims
idf = data.fraudulent == 1;
idnf = data.fraudulent == 0;

fruad = data(idf,:);
nonfruad = data(idnf,:);
n = 500;
rand = datasample(nonfruad, n, 'Replace', false);
newdata = vertcat(fruad, rand);
%%
%suffle the newdata table
newdata = newdata(randperm(height(newdata)), :);
% Create a random partition
cv = cvpartition(height(newdata), 'HoldOut', 0.2);
% Extract training and test sets
trainingSet = newdata(cv.training, :);
testSet = newdata(cv.test, :);
%%
% Select the important variables identified through decision tree
%X = [trainingSet.claim_type, trainingSet.claim_amount, trainingSet.income, trainingSet.age,trainingSet.policy_duration];
X=trainingSet;
X = table2array(X);
%%
% Set range of k values
kValues = 2:10;
meanSilhouetteScores = zeros(length(kValues), 1);
%%
% Compute silhouette scores for each value of k
for i = 1:length(kValues)
    k = kValues(i);  % Get current k value
    idx = kmeans(X, k, 'Distance', 'cityblock', 'Replicates', 10);  % Run k-means clustering
    
    % Compute silhouette scores
    s = silhouette(X, idx, 'cityblock');
    meanSilhouetteScores(i) = mean(s);  % Store the mean silhouette score
end
%%
% Plot the silhouette scores against the number of clusters
figure(1)
plot(kValues, meanSilhouetteScores, 'bo-', 'LineWidth', 2);
xlabel('Number of Clusters');
ylabel('Average Silhouette Score');
title('Silhouette Analysis for Optimal k');
grid on;
%%
% Find the best number of clusters
[bestScore, bestIndex] = max(meanSilhouetteScores);
bestK = kValues(bestIndex);
fprintf('Best number of clusters = %d, Silhouette Score = %.4f\n', bestK, bestScore);
%%
rng(1)
idx = kmeans(X,2,'distance','cityblock', 'display','iter');
[silh2,h] = silhouette(X,idx,'cityblock');
xlabel('Silhouette Value')
ylabel('Cluster')
%%
cluster1_mask = (idx == 1);
cluster2_mask = (idx == 2);
% Extract observations for each cluster
cluster1_data = trainingSet(cluster1_mask, :);
cluster2_data = trainingSet(cluster2_mask, :);

% Display sizes of each cluster
fprintf('Number of observations in Cluster 1: %d\n', height(cluster1_data));
fprintf('Number of observations in Cluster 2: %d\n', height(cluster2_data));

%%
k=2
cluster_stats = zeros(k, 2);  % k=2, and 2 columns for fraudulent/non-fraudulent
for i = 1:k
    cluster_mask = (idx == i);
    cluster_data = trainingSet(cluster_mask, :);
    
    % Calculate percentages
    total_claims = height(cluster_data);
    fraudulent_claims = sum(cluster_data.fraudulent == 1);
    non_fraudulent_claims = sum(cluster_data.fraudulent == 0);
    
    cluster_stats(i, 1) = (fraudulent_claims / total_claims) * 100;    % Fraudulent percentage
    cluster_stats(i, 2) = (non_fraudulent_claims / total_claims) * 100; % Non-fraudulent percentage
end
%%
% Create the stacked bar graph
figure('Position', [100 100 800 400]);
subplot(1,2,1);
b = bar(cluster_stats, 'stacked');
b(1).FaceColor = [0 0 0.5];  % Dark blue for fraudulent
b(2).FaceColor = [1 1 0];    % Yellow for non-fraudulent

% Customize the graph
title('Fraudulent and Non-Fraudulent Claims by Cluster');
xlabel('Cluster');
ylabel('% Count');
ylim([0 100]);
legend('Fraudulent', 'Non-Fraudulent', 'Location', 'eastoutside');
xticklabels({'Cluster 1', 'Cluster 2'});
%%
figure('Position', [100 100 1200 800]);
% 1. Claim Amount Boxplot
subplot(2,3,1);
boxplot(trainingSet.claim_amount, idx);
title('Claim Amount by Cluster');
xlabel('Cluster');
ylabel('Claim Amount');
grid on;

% 2. Income Boxplot
subplot(2,3,2);
boxplot(trainingSet.income, idx);
title('Income by Cluster');
xlabel('Cluster');
ylabel('Income');
grid on;

% 3. Age Boxplot
subplot(2,3,3);
boxplot(trainingSet.age, idx);
title('Age by Cluster');
xlabel('Cluster');
ylabel('Age');
grid on;

% 4. Policy Duration Boxplot
subplot(2,3,4);
boxplot(trainingSet.policy_duration, idx);
title('Policy Duration by Cluster');
xlabel('Cluster');
ylabel('Policy Duration (days)');
grid on;

% 5. Claim Type Distribution
subplot(2,3,5);
claim_type_counts = crosstab(idx, trainingSet.claim_type);
bar(claim_type_counts, 'stacked');
title('Claim Types by Cluster');
xlabel('Cluster');
ylabel('Count');
legend('Location', 'eastoutside');

% Calculate and display summary statistics
fprintf('\nSummary Statistics by Cluster:\n');
fprintf('----------------------------\n');

vars = {'claim_amount', 'income', 'age', 'policy_duration'};
stats_table = table();

for i = 1:2  % for each cluster
    cluster_data = trainingSet(idx == i, :);
    
    for j = 1:length(vars)
        var_name = vars{j};
        stats_table.([var_name '_median_cluster' num2str(i)]) = median(cluster_data.(var_name));
        stats_table.([var_name '_mean_cluster' num2str(i)]) = mean(cluster_data.(var_name));
        stats_table.([var_name '_std_cluster' num2str(i)]) = std(cluster_data.(var_name));
    end
end

% Display statistics
disp(stats_table);

