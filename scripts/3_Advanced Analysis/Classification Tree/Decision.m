clc; clear;
rng(3)
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
data.occupancy_date = datetime(data.occupancy_date, 'InputFormat', 'MM/dd/yyyy');
%%
%create new variable age up to incident date
data.age = fix(years(data.incident_date-data.dob));
%remove dof variable
data.dob = [];
%%
%creating a new variable of policy duraion - valid durationn of policy
%until the incident date
data.policy_duration = years(data.incident_date-data.policy_date);
%duration of occupancy 
data.occu_duration = years(data.incident_date-data.occupancy_date);
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
newdata = table2array(newdata);
% Extract training and test sets
trainingSet = newdata(cv.training, :);
testSet = newdata(cv.test, :);
%%


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
%%
%%
% List of numerical variables
numericalVars = {'claim_amount', 'coverage', 'income', 'deductible', ...
                 'age', 'policy_duration', 'occu_duration'};

% Loop through each numerical variable and create a boxplot
for i = 1:length(numericalVars)
    figure; % Create a new figure for each plot
    boxplot(trainingSet.(numericalVars{i}), trainingSet.fraudulent);
    
    % Formatting
    xlabel('Fraudulent (0 = No, 1 = Yes)'); % Adjust if more categories exist
    ylabel(strrep(numericalVars{i}, '_', ' ')); % Replace underscores with spaces for readability
    title(['Boxplot of ', strrep(numericalVars{i}, '_', ' '), ' by Fraudulent Status']);
    grid on;
end

%%

% Count occurrences directly (no need for categorical conversion)
ctData = [
    sum(trainingSet.claim_type == 1 & trainingSet.fraudulent == 0), sum(trainingSet.claim_type == 1 & trainingSet.fraudulent == 1);
    sum(trainingSet.claim_type == 2 & trainingSet.fraudulent == 0), sum(trainingSet.claim_type == 2 & trainingSet.fraudulent == 1);
    sum(trainingSet.claim_type == 3 & trainingSet.fraudulent == 0), sum(trainingSet.claim_type == 3 & trainingSet.fraudulent == 1);
    sum(trainingSet.claim_type == 4 & trainingSet.fraudulent == 0), sum(trainingSet.claim_type == 4 & trainingSet.fraudulent == 1);
    sum(trainingSet.claim_type == 5 & trainingSet.fraudulent == 0), sum(trainingSet.claim_type == 5 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(ctData, 2);
ctPct = 100 * ctData ./ repmat(totalCounts, 1, 2);
ctPct(isnan(ctPct)) = 0;

% Plot as stacked bar chart with percentages on the y-axis
figure;
b = bar(1:5, ctPct, 'stacked'); % Store bar handles for text placement
title('Stacked Bar Chart of Claim Type by Fraudulent Status');
xlabel('Claim Type');
ylabel('Percentage (%)');
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'best');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:5, 'XTickLabel', {'Wind/Hail', 'Water Damage', 'Fire/Smoke', 'Contamination', 'Theft/Vandalism'});

% Add percentage labels inside correct bar segments
for i = 1:5
    cumulativeHeight = 0; % Track the top of each section
    for j = 1:2
        if ctData(i, j) > 0
            % Compute the middle of the segment
            yPos = cumulativeHeight + (ctPct(i, j) / 2);
            text(i, yPos, sprintf('%.1f%%', ctPct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
            % Update cumulative height for next section
            cumulativeHeight = cumulativeHeight + ctPct(i, j);
        end
    end
end


%%

% Count occurrences directly (no need for categorical conversion)
townsizeData = [
    sum(trainingSet.townsize == 1 & trainingSet.fraudulent == 0), sum(trainingSet.townsize == 1 & trainingSet.fraudulent == 1);
    sum(trainingSet.townsize == 2 & trainingSet.fraudulent == 0), sum(trainingSet.townsize == 2 & trainingSet.fraudulent == 1);
    sum(trainingSet.townsize == 3 & trainingSet.fraudulent == 0), sum(trainingSet.townsize == 3 & trainingSet.fraudulent == 1);
    sum(trainingSet.townsize == 4 & trainingSet.fraudulent == 0), sum(trainingSet.townsize == 4 & trainingSet.fraudulent == 1);
    sum(trainingSet.townsize == 5 & trainingSet.fraudulent == 0), sum(trainingSet.townsize == 5 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(townsizeData, 2);
townsizePct = 100 * townsizeData ./ repmat(totalCounts, 1, 2);
townsizePct(isnan(townsizePct)) = 0;

% Plot as stacked bar chart with percentages on the y-axis
figure;
b = bar(1:5, townsizePct, 'stacked'); % Store bar handles for text placement
title('Stacked Bar Chart of Town Size by Fraudulent Status');
xlabel('Town Size');
ylabel('Percentage (%)');
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'best');
grid on;

% Add percentage labels inside correct bar segments
for i = 1:5
    cumulativeHeight = 0; % Track the top of each section
    for j = 1:2
        if townsizeData(i, j) > 0
            % Compute the middle of the segment
            yPos = cumulativeHeight + (townsizePct(i, j) / 2);
            text(i, yPos, sprintf('%.1f%%', townsizePct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
            % Update cumulative height for next section
            cumulativeHeight = cumulativeHeight + townsizePct(i, j);
        end
    end
end


%%

% Count occurrences directly (no need for categorical conversion)
edcatData = [
    sum(trainingSet.edcat == 1 & trainingSet.fraudulent == 0), sum(trainingSet.edcat == 1 & trainingSet.fraudulent == 1);
    sum(trainingSet.edcat == 2 & trainingSet.fraudulent == 0), sum(trainingSet.edcat == 2 & trainingSet.fraudulent == 1);
    sum(trainingSet.edcat == 3 & trainingSet.fraudulent == 0), sum(trainingSet.edcat == 3 & trainingSet.fraudulent == 1);
    sum(trainingSet.edcat == 4 & trainingSet.fraudulent == 0), sum(trainingSet.edcat == 4 & trainingSet.fraudulent == 1);
    sum(trainingSet.edcat == 5 & trainingSet.fraudulent == 0), sum(trainingSet.edcat == 5 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(edcatData, 2);
edcatPct = 100 * edcatData ./ repmat(totalCounts, 1, 2);
edcatPct(isnan(edcatPct)) = 0;

% Plot as stacked bar chart with percentages on the y-axis
figure;
b = bar(1:5, edcatPct, 'stacked'); % Store bar handles for text placement
title('Stacked Bar Chart of Education Category by Fraudulent Status');
xlabel('Education Category');
ylabel('Percentage (%)');
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'best');
grid on;

% Add percentage labels inside correct bar segments
for i = 1:5
    cumulativeHeight = 0; % Track the top of each section
    for j = 1:2
        if edcatData(i, j) > 0
            % Compute the middle of the segment
            yPos = cumulativeHeight + (edcatPct(i, j) / 2);
            text(i, yPos, sprintf('%.1f%%', edcatPct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
            % Update cumulative height for next section
            cumulativeHeight = cumulativeHeight + edcatPct(i, j);
        end
    end
end

%%

% Count occurrences directly (no need for categorical conversion)
resideData = [
    sum(trainingSet.reside == 1 & trainingSet.fraudulent == 0), sum(trainingSet.reside == 1 & trainingSet.fraudulent == 1);
    sum(trainingSet.reside == 2 & trainingSet.fraudulent == 0), sum(trainingSet.reside == 2 & trainingSet.fraudulent == 1);
    sum(trainingSet.reside == 3 & trainingSet.fraudulent == 0), sum(trainingSet.reside == 3 & trainingSet.fraudulent == 1);
    sum(trainingSet.reside == 4 & trainingSet.fraudulent == 0), sum(trainingSet.reside == 4 & trainingSet.fraudulent == 1);
    sum(trainingSet.reside == 5 & trainingSet.fraudulent == 0), sum(trainingSet.reside == 5 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(resideData, 2);
residePct = 100 * resideData ./ repmat(totalCounts, 1, 2);
residePct(isnan(residePct)) = 0;

% Plot as stacked bar chart with percentages on the y-axis
figure;
b = bar(1:5, residePct, 'stacked'); % Store bar handles for text placement
title('Stacked Bar Chart of Residence Type by Fraudulent Status');
xlabel('Residence Type');
ylabel('Percentage (%)');
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'best');
grid on;

% Add percentage labels inside correct bar segments
for i = 1:5
    cumulativeHeight = 0; % Track the top of each section
    for j = 1:2
        if resideData(i, j) > 0
            % Compute the middle of the segment
            yPos = cumulativeHeight + (residePct(i, j) / 2);
            text(i, yPos, sprintf('%.1f%%', residePct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
            % Update cumulative height for next section
            cumulativeHeight = cumulativeHeight + residePct(i, j);
        end
    end
end


%%

% Count occurrences directly for uninhabitable
uninhabitableData = [
    sum(trainingSet.uninhabitable == 0 & trainingSet.fraudulent == 0), sum(trainingSet.uninhabitable == 0 & trainingSet.fraudulent == 1);
    sum(trainingSet.uninhabitable == 1 & trainingSet.fraudulent == 0), sum(trainingSet.uninhabitable == 1 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(uninhabitableData, 2);
uninhabitablePct = 100 * uninhabitableData ./ repmat(totalCounts, 1, 2);
uninhabitablePct(isnan(uninhabitablePct)) = 0;

% Plot as grouped bar chart with percentages on the y-axis
figure;
b = bar(1:2, uninhabitablePct, 'grouped'); % Store bar handles for text placement
title('Grouped Bar Chart of Uninhabitable by Fraudulent Status');
xlabel('Uninhabitable Status');
ylabel('Percentage (%)');
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'best');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:2, 'XTickLabel', {'Not Uninhabitable', 'Uninhabitable'});

% Add percentage labels inside correct bar segments
for i = 1:2
    for j = 1:2
        if uninhabitableData(i, j) > 0
            % Compute the middle of the segment
            yPos = uninhabitablePct(i, j) / 2;
            text(i + (j-1)*0.25 - 0.125, yPos, sprintf('%.1f%%', uninhabitablePct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

% Change legend position to avoid overlap (adjust the legend location)
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'northeast');


%%

% Count occurrences directly for gender
genderData = [
    sum(trainingSet.gender == 0 & trainingSet.fraudulent == 0), sum(trainingSet.gender == 0 & trainingSet.fraudulent == 1);
    sum(trainingSet.gender == 1 & trainingSet.fraudulent == 0), sum(trainingSet.gender == 1 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(genderData, 2);
genderPct = 100 * genderData ./ repmat(totalCounts, 1, 2);
genderPct(isnan(genderPct)) = 0;

% Plot as grouped bar chart with percentages on the y-axis
figure;
b = bar(1:2, genderPct, 'grouped'); % Store bar handles for text placement
title('Grouped Bar Chart of Gender by Fraudulent Status');
xlabel('Gender');
ylabel('Percentage (%)');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:2, 'XTickLabel', {'Male', 'Female'});

% Add percentage labels inside correct bar segments
for i = 1:2
    for j = 1:2
        if genderData(i, j) > 0
            % Compute the middle of the segment
            yPos = genderPct(i, j) / 2;
            text(i + (j-1)*0.25 - 0.125, yPos, sprintf('%.1f%%', genderPct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

% Change legend position to avoid overlap (adjust the legend location)
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'northeast');

%%

% Count occurrences directly for marital status
maritalData = [
    sum(trainingSet.marital == 0 & trainingSet.fraudulent == 0), sum(trainingSet.marital == 0 & trainingSet.fraudulent == 1);
    sum(trainingSet.marital == 1 & trainingSet.fraudulent == 0), sum(trainingSet.marital == 1 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(maritalData, 2);
maritalPct = 100 * maritalData ./ repmat(totalCounts, 1, 2);
maritalPct(isnan(maritalPct)) = 0;

% Plot as grouped bar chart with percentages on the y-axis
figure;
b = bar(1:2, maritalPct, 'grouped'); % Store bar handles for text placement
title('Grouped Bar Chart of Marital Status by Fraudulent Status');
xlabel('Marital Status');
ylabel('Percentage (%)');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:2, 'XTickLabel', {'Unmarried', 'Married'});

% Add percentage labels inside correct bar segments
for i = 1:2
    for j = 1:2
        if maritalData(i, j) > 0
            % Compute the middle of the segment
            yPos = maritalPct(i, j) / 2;
            text(i + (j-1)*0.25 - 0.125, yPos, sprintf('%.1f%%', maritalPct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

% Change legend position to avoid overlap (adjust the legend location)
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'northeast');
%%
% Count occurrences directly for retirement status
retireData = [
    sum(trainingSet.retire == 0 & trainingSet.fraudulent == 0), sum(trainingSet.retire == 0 & trainingSet.fraudulent == 1);
    sum(trainingSet.retire == 1 & trainingSet.fraudulent == 0), sum(trainingSet.retire == 1 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(retireData, 2);
retirePct = 100 * retireData ./ repmat(totalCounts, 1, 2);
retirePct(isnan(retirePct)) = 0;

% Plot as grouped bar chart with percentages on the y-axis
figure;
b = bar(1:2, retirePct, 'grouped'); % Store bar handles for text placement
title('Grouped Bar Chart of Retirement Status by Fraudulent Status');
xlabel('Retirement Status');
ylabel('Percentage (%)');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:2, 'XTickLabel', {'Not Retired', 'Retired'});

% Add percentage labels inside correct bar segments
for i = 1:2
    for j = 1:2
        if retireData(i, j) > 0
            % Compute the middle of the segment
            yPos = retirePct(i, j) / 2;
            text(i + (j-1)*0.25 - 0.125, yPos, sprintf('%.1f%%', retirePct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

% Change legend position to avoid overlap (adjust the legend location)
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'northeast');

%%

% Count occurrences directly for primary residence status
primaryResidenceData = [
    sum(trainingSet.primary_residence == 0 & trainingSet.fraudulent == 0), sum(trainingSet.primary_residence == 0 & trainingSet.fraudulent == 1);
    sum(trainingSet.primary_residence == 1 & trainingSet.fraudulent == 0), sum(trainingSet.primary_residence == 1 & trainingSet.fraudulent == 1);
];

% Convert to percentages
totalCounts = sum(primaryResidenceData, 2);
primaryResidencePct = 100 * primaryResidenceData ./ repmat(totalCounts, 1, 2);
primaryResidencePct(isnan(primaryResidencePct)) = 0;

% Plot as grouped bar chart with percentages on the y-axis
figure;
b = bar(1:2, primaryResidencePct, 'grouped'); % Store bar handles for text placement
title('Grouped Bar Chart of Primary Residence Status by Fraudulent Status');
xlabel('Primary Residence');
ylabel('Percentage (%)');
grid on;

% Set x-axis labels (MATLAB 2015 compatible)
set(gca, 'XTick', 1:2, 'XTickLabel', {'No', 'Yes'});

% Add percentage labels inside correct bar segments
for i = 1:2
    for j = 1:2
        if primaryResidenceData(i, j) > 0
            % Compute the middle of the segment
            yPos = primaryResidencePct(i, j) / 2;
            text(i + (j-1)*0.25 - 0.125, yPos, sprintf('%.1f%%', primaryResidencePct(i, j)), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

% Change legend position to avoid overlap (adjust the legend location)
legend({'Not Fraudulent', 'Fraudulent'}, 'Location', 'northeast');

%%
figure;

% Normal Probability Plot for coverage
subplot(3,3,1);
qqplot(trainingSet.coverage);
title('Coverage');

% Normal Probability Plot for income
subplot(3,3,2);
qqplot(trainingSet.income);
title('Income');

% Normal Probability Plot for claim amount
subplot(3,3,3);
qqplot(trainingSet.claim_amount);
title('Claim Amount');

% Normal Probability Plot for deductible
subplot(3,3,4);
qqplot(trainingSet.deductible);
title('Deductible');

% Normal Probability Plot for age
subplot(3,3,5);
qqplot(trainingSet.age);
title('Age');

% Normal Probability Plot for policy duration
subplot(3,3,6);
qqplot(trainingSet.policy_duration);
title('Policy Duration');

% Normal Probability Plot for occupation duration
subplot(3,3,7);
qqplot(trainingSet.occu_duration);
title('Occupation Duration');

% Adjust layout for better readability
suptitle('Normal Probability Plots'); % Super title for all subplots


%%

% Mann-Whitney U Test for coverage
[p_coverage, h_coverage] = ranksum(trainingSet.coverage(trainingSet.fraudulent == 0), trainingSet.coverage(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Coverage: ', num2str(p_coverage)]);

% Mann-Whitney U Test for income
[p_income, h_income] = ranksum(trainingSet.income(trainingSet.fraudulent == 0), trainingSet.income(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Income: ', num2str(p_income)]);

% Mann-Whitney U Test for claim amount
[p_claim_amount, h_claim_amount] = ranksum(trainingSet.claim_amount(trainingSet.fraudulent == 0), trainingSet.claim_amount(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Claim Amount: ', num2str(p_claim_amount)]);

% Mann-Whitney U Test for deductible
[p_deductible, h_deductible] = ranksum(trainingSet.deductible(trainingSet.fraudulent == 0), trainingSet.deductible(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Deductible: ', num2str(p_deductible)]);

% Mann-Whitney U Test for age
[p_age, h_age] = ranksum(trainingSet.age(trainingSet.fraudulent == 0), trainingSet.age(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Age: ', num2str(p_age)]);

% Mann-Whitney U Test for policy duration
[p_policy_duration, h_policy_duration] = ranksum(trainingSet.policy_duration(trainingSet.fraudulent == 0), trainingSet.policy_duration(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Policy Duration: ', num2str(p_policy_duration)]);

% Mann-Whitney U Test for occupation duration
[p_occu_duration, h_occu_duration] = ranksum(trainingSet.occu_duration(trainingSet.fraudulent == 0), trainingSet.occu_duration(trainingSet.fraudulent == 1));
disp(['Mann-Whitney U Test p-value for Occupation Duration: ', num2str(p_occu_duration)]);

%%

% Scatter plot for Income vs Claim Amount with red regression line
figure;
scatter(trainingSet.income, trainingSet.claim_amount, 'filled');
hold on;
lsline;  % Add regression line
h = findobj(gca, 'Type', 'Line'); % Find the regression line object
set(h, 'Color', 'r'); % Change the color of the line to red
title('Income vs Claim Amount');
xlabel('Income');
ylabel('Claim Amount');
grid on;
hold off;

% Scatter plot for Coverage vs Claim Amount with red regression line
figure;
scatter(trainingSet.coverage, trainingSet.claim_amount, 'filled');
hold on;
lsline;  % Add regression line
h = findobj(gca, 'Type', 'Line'); % Find the regression line object
set(h, 'Color', 'r'); % Change the color of the line to red
title('Coverage vs Claim Amount');
xlabel('Coverage');
ylabel('Claim Amount');
grid on;
hold off;


%%

% Scatter plot for Claim Amount vs Age with red regression line
figure;
scatter(trainingSet.age, trainingSet.claim_amount, 'filled');
hold on;
lsline;  % Add regression line
h = findobj(gca, 'Type', 'Line'); % Find the regression line object
set(h, 'Color', 'r'); % Change the color of the line to red
title('Age vs Claim Amount');
xlabel('Age');
ylabel('Claim Amount');
grid on;
hold off;

% Scatter plot for Claim Amount vs Policy Duration with red regression line
figure;
scatter(trainingSet.policy_duration, trainingSet.claim_amount, 'filled');
hold on;
lsline;  
h = findobj(gca, 'Type', 'Line'); 
set(h, 'Color', 'r');  
title('Policy Duration vs Claim Amount');
xlabel('Policy Duration');
ylabel('Claim Amount');
grid on;
hold off;

% Scatter plot for Claim Amount vs Occupation Duration with red regression line
figure;
scatter(trainingSet.occu_duration, trainingSet.claim_amount, 'filled');
hold on;
lsline;  
h = findobj(gca, 'Type', 'Line'); 
set(h, 'Color', 'r');  
title('Occupation Duration vs Claim Amount');
xlabel('Occupation Duration');
ylabel('Claim Amount');
grid on;
hold off;
%%
x_train = trainingSet(:, [1:3, 5:17]);
y_train = trainingSet(:, 4);
x_test = testSet(:, [1:3, 5:17]);
y_test = testSet(:, 4);
%% Cross-validation setup
cp = cvpartition(y_train, 'KFold', 10); % 10-fold cross-validation

%% Train decision tree model

t = fitctree(x_train, y_train, 'PredictorNames', {'claim_type', 'uninhabitable', 'claim_amount', 'coverage', 'deductible', 'townsize', 'gender', 'edcat', 'retire', 'income', 'marital', 'reside', 'primary_residence','age','policy_duration','occupy_duration'});
view(t, 'Mode', 'graph'); % Visualize the tree

numTerminalNodes = size(t.PruneList, 1);
disp(['Number of terminal nodes: ', num2str(numTerminalNodes)]);


%% Evaluate model performance

ResubErr = resubLoss(t); % Resubstitution error
cvt = crossval(t, 'CVPartition', cp); % Cross-validate the model
dtCVErr = kfoldLoss(cvt); % Cross-validation error

%% Prune the tree to avoid overfitting
resubcost = resubLoss(t, 'Subtrees', 'all'); % Resubstitution cost for all subtrees
[cost, secost, ntermnodes, bestlevel] = cvloss(t, 'Subtrees', 'all'); % Cross-validation cost for all subtrees

% Plot resubstitution and cross-validation errors
figure;
plot(ntermnodes, cost, 'b-', ntermnodes, resubcost, 'r--');
xlabel('Number of terminal nodes');
ylabel('Cost (misclassification error)');
legend('Cross-validation', 'Resubstitution');
title('Tree Pruning Analysis');

% Find the best pruning level
[mincost, minloc] = min(cost);
cutoff = mincost + secost(minloc);
hold on;
plot([0 100], [cutoff cutoff], 'k:'); % Plot cutoff line
plot(ntermnodes(bestlevel + 1), cost(bestlevel + 1), 'mo'); % Highlight best choice
legend('Cross-validation', 'Resubstitution', 'Min + 1 std. err.', 'Best choice');
hold off;

%% Prune the tree to the optimal level
pt = prune(t, 'Level', bestlevel); % Prune the tree
view(pt, 'Mode', 'graph'); % Visualize the pruned tree

%% Evaluate the pruned tree
prunedResubErr = resubLoss(pt); % Resubstitution error for pruned tree
cvt_pruned = crossval(pt, 'CVPartition', cp);
prunedCVErr = kfoldLoss(cvt_pruned); % Cross-validation error for pruned tree

disp(['Resubstitution Error (Original): ', num2str(ResubErr)]);
disp(['Cross-Validation Error (Original): ', num2str(dtCVErr)]);
disp(['Resubstitution Error (Pruned): ', num2str(prunedResubErr)]);
disp(['Cross-Validation Error (Pruned): ', num2str(prunedCVErr)]);

%%
vip = predictorImportance(pt); % Calculate predictor importance
PredictorNames = {'claim type', 'uninhabitable', 'claim amount', 'coverage', 'deductible', ...
                  'townsize', 'gender', 'edcat', 'retire', 'income', 'marital', 'reside', ...
                  'primary residence', 'age', 'policy duration', 'occupy duration'}; 

figure;
bar(vip); % Bar plot of predictor importance
title('Predictor Importance Estimates');
ylabel('Importance Estimates');
xlabel('Predictors');

% Ensure the number of labels matches the number of predictors
if length(vip) == length(PredictorNames)
    set(gca, 'XTick', 1:length(PredictorNames)); % Set tick positions correctly
    set(gca, 'XTickLabel', PredictorNames); % Set tick labels to predictor names
else
    warning('Number of predictors does not match the number of importance values!');
end

set(gca, 'XTickLabelRotation', 45); % Rotate labels manually
grid on; % Add grid for better visualization
set(gca, 'FontSize', 12); % Adjust font size for readability
%%
% Evaluate model on test set
testErr = loss(t,x_test,y_test);
prunedtestErr = loss(pt,x_test,y_test);

disp(['Test Error for Optimal Tree: ', num2str(testErr)]);
disp(['Test Error for Default Tree: ', num2str(testErr2)]);

Error_Type = {'Training Error'; 'Testing Error'; 'Accuracy'};
Default_Tree = [ResubErr; testErr; 1-testErr];
Optimal_Tree = [prunedResubErr; prunedtestErr;1-prunedtestErr];

T = table(Error_Type, Default_Tree, Optimal_Tree)
disp(T)

%%


x_train = trainingSet(:, [1:3, 5:17]); % Features
y_train = trainingSet(:, 4); % Target variable (fraudulent)
x_test = testSet(:, [1:3, 5:17]);
y_test = testSet(:, 4);

%% Cross-Validation to Find the Optimal Number of Trees
rng(3);
errR = [];
folds = 10; % Number of folds for cross-validation
num_of_trees = 50:10:500; % Range of trees to evaluate

% Perform k-fold cross-validation
for i = 1:length(num_of_trees)
    cvModel = fitctree(x_train, y_train, 'CrossVal', 'on', 'KFold', folds);
    cvError = kfoldLoss(cvModel);
    errR(i) = cvError;
end

% Plot the cross-validation error vs. number of trees
figure;
plot(num_of_trees, errR, 'bo-');
title('Cross-Validation Error vs. Number of Trees');
xlabel('Number of Trees');
ylabel('Cross-Validation Error');
grid on;

% Find the optimal number of trees
[~, optimalIdx] = min(errR);
optimalNumTrees = num_of_trees(optimalIdx);
disp(['Optimal Number of Trees: ', num2str(optimalNumTrees)]);

%% Train the Final Random Forest Model with the Optimal Number of Trees
rng(3)
finalModel = TreeBagger(optimalNumTrees, x_train, y_train, ...
    'Method', 'classification', ...
    'MinLeafSize', 50);

% Predict on the test set
y_pred = predict(finalModel, x_test);
y_pred = str2double(y_pred); % Convert cell array to numeric

% Compute accuracy
accuracy = sum(y_pred == y_test) / numel(y_test);
disp(['Test Accuracy: ', num2str(accuracy)]);

% Confusion matrix
confMat = confusionmat(y_test, y_pred);
disp('Confusion Matrix:');
disp(confMat);


%% Feature Importance
% Compute feature importance
importance = varimportance(finalModel); % Use varimportance for older MATLAB versions

% Plot feature importance
figure;
bar(importance);
title('Feature Importance');
xlabel('Features');
ylabel('Importance Score');

% Add feature names
featureNames = {'claim_type', 'uninhabitable', 'claim_amount', 'coverage', 'deductible', ...
                'townsize', 'gender', 'edcat', 'retire', 'income', 'marital', 'reside', ...
                'primary_residence', 'age', 'policy_duration', 'occupy_duration'};
set(gca, 'XTick', 1:length(featureNames));
set(gca, 'XTickLabel', featureNames, 'XTickLabelRotation', 45);
grid on;

%%

x_train = trainingSet(:, [1:3, 5:17]); % Features
y_train = trainingSet(:, 4); % Target variable (fraudulent)
x_test = testSet(:, [1:3, 5:17]);
y_test = testSet(:, 4);

%% Train SVM Model
% Define hyperparameter grid for tuning
boxConstraints = [0.1, 1, 10, 100]; % Range of BoxConstraint values
kernelScales = [0.1, 1, 10, 100]; % Range of KernelScale values

% Initialize variables to store results
bestAccuracy = 0;
bestBoxConstraint = [];
bestKernelScale = [];

% Perform grid search for hyperparameter tuning
for boxConstraint = boxConstraints
    for kernelScale = kernelScales
        % Train SVM model with current hyperparameters
        svmModel = fitcsvm(x_train, y_train, ...
            'KernelFunction', 'rbf', ... % Radial Basis Function (RBF) kernel
            'BoxConstraint', boxConstraint, ... % Regularization parameter
            'KernelScale', kernelScale, ... % Kernel scale
            'Standardize', true); % Standardize features

        % Perform cross-validation
        cvModel = crossval(svmModel, 'KFold', 5); % 5-fold cross-validation
        cvAccuracy = 1 - kfoldLoss(cvModel); % Cross-validation accuracy

        % Update best hyperparameters if current model is better
        if cvAccuracy > bestAccuracy
            bestAccuracy = cvAccuracy;
            bestBoxConstraint = boxConstraint;
            bestKernelScale = kernelScale;
        end
    end
end

% Display best hyperparameters
disp('Best Hyperparameters:');
disp(['BoxConstraint: ', num2str(bestBoxConstraint)]);
disp(['KernelScale: ', num2str(bestKernelScale)]);
disp(['Cross-Validation Accuracy: ', num2str(bestAccuracy)]);

% Train final SVM model with best hyperparameters
finalSvmModel = fitcsvm(x_train, y_train, ...
    'KernelFunction', 'rbf', ...
    'BoxConstraint', bestBoxConstraint, ...
    'KernelScale', bestKernelScale, ...
    'Standardize', true);

% Evaluate the final model on the test set
y_pred = predict(finalSvmModel, x_test);

% Compute accuracy
accuracy = sum(y_pred == y_test) / numel(y_test);
disp(['Test Accuracy: ', num2str(accuracy)]);

% Confusion matrix
confMat = confusionmat(y_test, y_pred);
disp('Confusion Matrix:');
disp(confMat);

% Plot confusion matrix manually
figure;
imagesc(confMat);
title('Confusion Matrix for SVM');
xlabel('Predicted Class');
ylabel('True Class');
colorbar;

% Add labels to the confusion matrix
classNames = {'Non-Fraudulent', 'Fraudulent'};
set(gca, 'XTick', 1:length(classNames));
set(gca, 'XTickLabel', classNames);
set(gca, 'YTick', 1:length(classNames));
set(gca, 'YTickLabel', classNames);

% Add text annotations
for i = 1:size(confMat, 1)
    for j = 1:size(confMat, 2)
        text(j, i, num2str(confMat(i, j)), ...
            'HorizontalAlignment', 'center', ...
            'Color', 'white');
    end
end

%%

%% 

%KNN 

% Define selected features
selectedFeatures = {'claim_type', 'claim_amount', 'income', 'age', 'policy_duration'};

% Extract data for training and testing
X_train = trainingSet{:, selectedFeatures}';
Y_train = trainingSet.fraudulent';
X_test = testSet{:, selectedFeatures}';
Y_test = testSet.fraudulent';

X_train = X_train';  % Convert to (771 × 5)
X_test = X_test';    % Convert to (192 × 5)

Y_train = Y_train(:);  % Convert to (771 × 1)
Y_test = Y_test(:);    % Convert to (192 × 1)

%%

% Encode Categorical Variable (`claim_type`)
claim_type_train = X_train(:, 1);  % The first column in X_train is claim_type
claim_type_test = X_test(:, 1);  % Same for X_test

% Get unique categories for the claim_type
categories = unique([claim_type_train; claim_type_test]);

% Initialize one-hot encoding matrices
X_train_encoded = zeros(size(X_train, 1), numel(categories));  
X_test_encoded = zeros(size(X_test, 1), numel(categories));  

% Encode categorical claim_type as one-hot
for i = 1:length(categories)
    X_train_encoded(:, i) = double(claim_type_train == categories(i));  % One-hot encoding for train
    X_test_encoded(:, i) = double(claim_type_test == categories(i));  % One-hot encoding for test
end

% Replace the original categorical column with the encoded one in X_train and X_test
X_train(:, 1) = [];  % Remove original claim_type column
X_test(:, 1) = [];   % Remove original claim_type column

% Concatenate the encoded columns
X_train = [X_train_encoded, X_train(:, 2:end)];
X_test = [X_test_encoded, X_test(:, 2:end)];
%%

% Convert to one-hot representation
for i = 1:numel(categories)
    X_train_encoded(:, i) = (X_train.claim_type == categories(i));
    X_test_encoded(:, i) = (X_test.claim_type == categories(i));
end

% Remove `claim_type` column and replace with encoded version
X_train.claim_type = [];
X_test.claim_type = [];
X_train = [X_train_encoded, X_train];  % Concatenate encoded columns with numeric features
X_test = [X_test_encoded, X_test];

% ---- Standardize Numerical Features (Z-score) ----
mu = mean(X_train);  % Compute mean of training set
sigma = std(X_train);  % Compute standard deviation of training set

X_train = (X_train - mu) ./ sigma;  % Apply standardization
X_test = (X_test - mu) ./ sigma;    % Use training mean/std to scale test set

% ---- Convert Response Variable to Categorical ----
Y_train = categorical(Y_train);  
Y_test = categorical(Y_test);

%% ---------------- Default KNN (k=1) ---------------- %%

mdl_default = fitcknn(X_train, Y_train, 'NumNeighbors', 1, 'Standardize', true);
Y_pred_default = predict(mdl_default, X_test);

% Compute Confusion Matrix for Default KNN
confMat_optimal = confusionmat(Y_test, Y_pred_default);

% Plot confusion matrix as heatmap for Default KNN (k=1) using imagesc
figure;
imagesc(confMat_optimal);  % Display the matrix as an image
colormap('parula');       % Set the color map
colorbar;                 % Show the color bar

% Formatting the plot
title('Confusion Matrix for Default KNN (k=1)');
xlabel('Predicted');
ylabel('Actual');
set(gca, 'XTick', 1:2, 'XTickLabel', {'No Fraud', 'Fraud'});
set(gca, 'YTick', 1:2, 'YTickLabel', {'No Fraud', 'Fraud'});
axis square;             % Make the plot square

% Add text labels inside the cells of the confusion matrix
for i = 1:size(confMat_optimal, 1)
    for j = 1:size(confMat_optimal, 2)
        % Get the value from the confusion matrix
        value = confMat_optimal(i, j);
        
        % Display the value inside the cell
        text(j, i, num2str(value), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');
    end
end


% Compute Accuracy for Default KNN
accuracy_optimal = sum(Y_pred_default == Y_test) / length(Y_test) * 100;

% Compute Metrics for Default KNN
TP_default = confMat_optimal(2,2);
FP_default = confMat_optimal(1,2);
FN_default = confMat_optimal(2,1);
TN_default = confMat_optimal(1,1);

precision_default = TP_default / (TP_default + FP_default);
recall_default = TP_default / (TP_default + FN_default);
F1_score_default = 2 * (precision_default * recall_default) / (precision_default + recall_default);

% Display Metrics including Accuracy
fprintf('Default KNN (k=1) Metrics:\n');
fprintf('Accuracy: %.2f%%\n', accuracy_optimal);
fprintf('Precision: %.2f\n', precision_default);
fprintf('Recall: %.2f\n', recall_default);
fprintf('F1 Score: %.2f\n\n', F1_score_default);

%%

% Define k values and distance metrics to tune

kFold=10;
kValues = 1:15; % Increase the range of k
distanceMetrics = {'euclidean', 'cosine', 'cityblock'};  % Try different distance metrics

% Initialize accuracy storage
bestAccuracy = 0;
bestK = 0;
bestMetric = '';

% Grid search for best k and distance metric
for k = kValues
    for metric = distanceMetrics
        metric = metric{1};  % Extract metric name from cell
        
        % Perform k-fold cross-validation for each (k, metric) combination
        cv = cvpartition(Y_train, 'KFold', kFold);
        fold_accuracies = zeros(kFold, 1);
        
        for fold = 1:kFold
            % Split the data for this fold
            trainIdx = cv.training(fold);
            testIdx = cv.test(fold);
            X_train_fold = X_train(trainIdx, :);
            Y_train_fold = Y_train(trainIdx);
            X_test_fold = X_train(testIdx, :);
            Y_test_fold = Y_train(testIdx);
            
            % Train KNN with the current k and metric
            mdl = fitcknn(X_train_fold, Y_train_fold, 'NumNeighbors', k, 'Distance', metric, 'Standardize', true);
            
            % Make predictions
            Y_pred = predict(mdl, X_test_fold);
            
            % Compute accuracy
            fold_accuracies(fold) = sum(Y_pred == Y_test_fold) / length(Y_test_fold) * 100;
        end
        
        % Compute mean accuracy for this combination
        meanAccuracy = mean(fold_accuracies);
        
        % Check if this is the best accuracy
        if meanAccuracy > bestAccuracy
            bestAccuracy = meanAccuracy;
            bestK = k;
            bestMetric = metric;
        end
    end
end

%% Define the best k and distance metric found during grid search
optimal_k = bestK;
optimal_metric = bestMetric;

% Train the final KNN model on the entire training set
mdl_optimal = fitcknn(X_train, Y_train, 'NumNeighbors', optimal_k, 'Distance', optimal_metric, 'Standardize', true);

% Make predictions on the test set
Y_pred_optimal = predict(mdl_optimal, X_test);

% Convert predictions and actual values to categorical
Y_pred_optimal = categorical(Y_pred_optimal);
Y_test = categorical(Y_test);

% Compute Confusion Matrix for Optimal KNN
confMat_optimal = confusionmat(Y_test, Y_pred_optimal);

% Plot confusion matrix as heatmap for Optimal KNN (best k and metric) using imagesc
figure;
imagesc(confMat_optimal);  % Display the matrix as an image
colormap('parula');       % Set the color map
colorbar;                 % Show the color bar

% Formatting the plot
title(['Confusion Matrix for Optimal KNN (k=' num2str(optimal_k) ')']);
xlabel('Predicted');
ylabel('Actual');
set(gca, 'XTick', 1:2, 'XTickLabel', {'No Fraud', 'Fraud'});
set(gca, 'YTick', 1:2, 'YTickLabel', {'No Fraud', 'Fraud'});
axis square;             % Make the plot square

% Add text labels inside the cells of the confusion matrix
for i = 1:size(confMat_optimal, 1)
    for j = 1:size(confMat_optimal, 2)
        % Get the value from the confusion matrix
        value = confMat_optimal(i, j);
        
        % Display the value inside the cell
        text(j, i, num2str(value), 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold');
    end
end

% Compute Accuracy for Optimal KNN
accuracy_optimal = sum(Y_pred_optimal == Y_test) / length(Y_test) * 100;

% Compute Metrics for Optimal KNN
TP_optimal = confMat_optimal(2,2);
FP_optimal = confMat_optimal(1,2);
FN_optimal = confMat_optimal(2,1);
TN_optimal = confMat_optimal(1,1);

precision_optimal = TP_optimal / (TP_optimal + FP_optimal);
recall_optimal = TP_optimal / (TP_optimal + FN_optimal);
F1_score_optimal = 2 * (precision_optimal * recall_optimal) / (precision_optimal + recall_optimal);

% Display Metrics including Accuracy
fprintf('Optimal KNN (k=%d) Metrics:\n', optimal_k);
fprintf('Accuracy: %.2f%%\n', accuracy_optimal);
fprintf('Precision: %.2f\n', precision_optimal);
fprintf('Recall: %.2f\n', recall_optimal);
fprintf('F1 Score: %.2f\n\n', F1_score_optimal);

%%

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

%%
