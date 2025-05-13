% Load and preprocess the data (use your existing preprocessing steps)
clc; clear;
rng(3); % Set random seed for reproducibility
data = readtable('insurence_claims.csv');

% Remove duplicates and missing values
data = unique(data);


% Remove unnecessary columns
data.claimid = [];
data.policyid = [];

% Convert dates to datetime format
data.policy_date = datetime(data.policy_date, 'InputFormat', 'MM/dd/yyyy');
data.incident_date = datetime(data.incident_date, 'InputFormat', 'MM/dd/yyyy');
data.dob = datetime(data.dob, 'InputFormat', 'MM/dd/yyyy');
data.occupancy_date = datetime(data.occupancy_date, 'InputFormat', 'MM/dd/yyyy');

% Create new variables
data.age = fix(years(data.incident_date - data.dob));
data.policy_duration = years(data.incident_date - data.policy_date);
data.occu_duration = years(data.incident_date - data.occupancy_date);

% Remove unnecessary columns
data.incident_date = [];
data.policy_date = [];
data.occupancy_date = [];
data.dob = [];
data.job_start_date = [];

% Create a new dataset with fraudulent claims and 500 randomly selected non-fraudulent claims
idf = data.fraudulent == 1;
idnf = data.fraudulent == 0;

fruad = data(idf, :);
nonfruad = data(idnf, :);
n = 500;
rand = datasample(nonfruad, n, 'Replace', false);
newdata = vertcat(fruad, rand);

% Shuffle the newdata table
newdata = newdata(randperm(height(newdata)), :);

% Split data into training and testing sets
cv = cvpartition(height(newdata), 'HoldOut', 0.2);
newdata = table2array(newdata);

trainingSet = newdata(cv.training, :);
testSet = newdata(cv.test, :);

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