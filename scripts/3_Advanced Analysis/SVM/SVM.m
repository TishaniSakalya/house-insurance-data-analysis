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