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