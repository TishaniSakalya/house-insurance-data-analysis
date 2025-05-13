%%

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
% Extract training and test sets
trainingSet = newdata(cv.training, :);
testSet = newdata(cv.test, :);

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