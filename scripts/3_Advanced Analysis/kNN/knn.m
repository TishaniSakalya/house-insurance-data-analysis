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
% Store original dataset before transformation 
originalData = trainingSet;
%%

%Check for outliers

% Boxplot for visualizing outliers
numericalData = trainingSet{:, {'income', 'claim_amount', 'coverage','deductible','age','policy_duration','occu_duration'}}; 
figure;
boxplot(numericalData, 'Labels', {'Income', 'Claim Amount', 'Coverage','Deductible','Age','Polcy Duration','Occupancy Duration'});  % Adjust based on your variables
title('Boxplot for Numerical Variables');

%%

% Initialize a figure for the boxplots
figure;

% List of variable names corresponding to the columns in numericalData
variableNames = {'income', 'claim_amount', 'coverage', 'deductible', 'age', 'policy_duration', 'occu_duration'};

% Loop over each variable in the numerical data
for i = 1:size(numericalData, 2)
    % Apply Box-Cox transformation (add 1 to handle zeros)
    [numericalData(:, i), lambda] = boxcox(numericalData(:, i) + 1);  % Box-Cox works on positive values

    % Plot the boxplot for the transformed data
    subplot(2, 4, i);  % 2x4 grid for plots
    boxplot(numericalData(:, i));
    title([variableNames{i}, ' (Box-Cox)']);
end

% Adjust layout for better visualization
suptitle('Box-Cox Transformed Numerical Variables');

% Now, replace the transformed data back into the trainingSet
for i = 1:length(variableNames)
    trainingSet.(variableNames{i}) = numericalData(:, i);
end
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
