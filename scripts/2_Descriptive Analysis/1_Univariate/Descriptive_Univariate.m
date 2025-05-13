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
%% ================== UNIVARIATE PLOTS ==================

figure;

%% 1. Histogram of Claim Amount

histogram(trainingSet.claim_amount, 20);
xlabel('Claim Amount (in thousands)');
ylabel('Frequency');
title('Histogram of Claim Amount');
grid on;
%% 2. Boxplot of Claim Amount

boxplot(trainingSet.claim_amount);
ylabel('Claim Amount (in thousands)');
title('Boxplot of Claim Amount');
grid on;

%% 3. Histogram of Coverage 
histogram(trainingSet.coverage, 20);
xlabel('coverage Amount  (in thousands)');
ylabel('Frequency');
title('Histogram of coverage Amount');
grid on;



%% 7. Pie Chart of Claim Type Distribution

categories = {'Wind/Hail', 'Water Damage', 'Fire/Smoke', 'Contamination', 'Theft/Vandalism'};
claim_type_counts = histcounts(trainingSet.claim_type, 1:7);
pie(claim_type_counts);
legend(categories, 'Location', 'eastoutside');
title('Claim Type Distribution');

%% 8. Histogram of Policy Duration
histogram(trainingSet.policy_duration, 15);
xlabel('Policy Duration (days)');
ylabel('Frequency');
title('Histogram of Policy Duration');
grid on;

%% 9. Bar Chart of Education Level

education_levels = {'No HS', 'HS Degree', 'Some College', 'College Degree', 'Postgrad'};
education_counts = histcounts(trainingSet.edcat, 1:7);
bar(education_counts);
set(gca, 'XTickLabel', education_levels);
ylabel('Count');
title('Education Level Distribution');
grid on;

%% 10. Histogram of Income
histogram(trainingSet.income, 15);
xlabel('Income (in thousands)');
ylabel('Frequency');
title('Histogram of Income');
grid on;

%% 11. Boxplot of Income

boxplot(trainingSet.income);
ylabel('Income (in thousands)');
title('Boxplot of Income');
grid on;

%% 12. Pie Chart of Primary Residence Status

residence_counts = [sum(trainingSet.primary_residence == 0), sum(trainingSet.primary_residence == 1)];
pie(residence_counts);
legend({'Non-Primary', 'Primary'}, 'Location', 'eastoutside');
title('Primary Residence Status');

%% 13. Bar Chart of Town Size

town_sizes = {'>250,000', '50K-249K', '10K-49K', '2.5K-9K', '<2.5K'};
town_size_counts = histcounts(trainingSet.townsize, 1:7);
bar(town_size_counts);
set(gca, 'XTickLabel', town_sizes);
ylabel('Count');
title('Town Size Distribution');
grid on;



%% 14. ECDF Plot of Deductible

ecdf(trainingSet.deductible);
xlabel('Deductible Amount');
ylabel('Cumulative Probability');
title('ECDF of Deductible');
grid on;

disp('Data processing and visualizations completed.');

%% --------------------Correlation--------------------- 
%% Identify Numerical and Categorical Variables
vars = trainingSet.Properties.VariableNames;

% Define categorical and numerical variable names manually based on provided list
categorical_vars = {'claim_type','uninhabitable', 'fraudulent','townsize', 'gender', ...
                    'edcat', 'retire', 'marital', 'reside', 'primary_residence'};
numerical_vars = {'claim_amount', 'coverage', 'deductible', 'income'};

% Get indices of categorical and numerical variables
num_vars = find(ismember(vars, numerical_vars));
cat_vars = find(ismember(vars, categorical_vars));

%% 1. Pearson’s Correlation between Numerical Predictors
num_data = table2array(trainingSet(:, num_vars)); % Extract numerical data
pearson_corr = corr(num_data, 'Type', 'Pearson'); % Compute Pearson correlation
disp('Pearson Correlation Matrix (Numerical Predictors):');
disp(array2table(pearson_corr, 'VariableNames', numerical_vars, 'RowNames', numerical_vars));

%% 2. Spearman's Rank Correlation for Response with Numerical Variables
spearman_corr = zeros(1, length(num_vars));

for i = 1:length(num_vars)
    spearman_corr(i) = corr(trainingSet.fraudulent, trainingSet.(numerical_vars{i}), 'Type', 'Spearman');
end

disp('Spearman Correlation between Fraudulent Claims and Numerical Variables:');
disp(array2table(spearman_corr, 'VariableNames', numerical_vars));

%% 3. Pearson’s Chi-squared Test for Response with Categorical Variables
chi2_results = cell(length(cat_vars), 2);

for i = 1:length(cat_vars)
    tbl = crosstab(trainingSet.fraudulent, trainingSet.(categorical_vars{i}));  % Contingency table
    
    % Check for empty categories
    if any(sum(tbl, 2) == 0) || any(sum(tbl, 1) == 0)
        disp(['Skipping variable: ', categorical_vars{i}, ' (empty category)']);
        chi2_results{i, 1} = categorical_vars{i};
        chi2_results{i, 2} = NaN;
        continue;
    end
    
    % Compute Chi-squared test
    [h, chi2_p] = chi2gof(1:length(tbl(:)), 'Freq', tbl(:));
    chi2_results{i, 1} = categorical_vars{i};
    chi2_results{i, 2} = chi2_p;
end

% Convert to table
chi2_table = cell2table(chi2_results, 'VariableNames', {'CategoricalVariable', 'PValue'});

disp('Chi-squared Test Results for Fraudulent Claims with Categorical Variables:');
disp(chi2_table);