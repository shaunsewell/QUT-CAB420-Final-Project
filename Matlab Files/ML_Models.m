%% initialise
clear ; close all; clc
addpath(genpath('Matlab Files'));
load("FeatureVectors.mat");

% Unfold the vectors. No longer need to worry about seasons
RA = []; HA = []; PCAC = []; DA = []; Y = [];
for s=1:7
   RA = [RA; RA_feature_vectors(:,:,s)];
   HA = [HA; HA_feature_vectors(:,:,s)];
   DA = [DA; DA_feature_vectors(:,:,:,s)];
   PCAC = [PCAC; PCAC_feature_vectors(:,:,:,:,s)];
   Y = [Y; winner(:,:,s)];
end

%% Running Average
% select the best features to minimise the MSE
[linf, logf, svmf] = feature_selection(RA,Y);
[Train_MSE, Test_MSE] = cross_validate(RA,Y,linf,logf,svmf);
mean(Train_MSE)
mean(Test_MSE)

%% Home and Away Average
[linf, logf, svmf] = feature_selection(HA,Y);
[Train_MSE, Test_MSE] = cross_validate(HA,Y,linf,logf,svmf);
mean(Train_MSE)
mean(Test_MSE)

%% Decaying Average
alpha = 0.09:0.1:0.99;
DA_Train_MSE = zeros(100,3,10);
DA_Test_MSE = zeros(100,3,10);

for d=1:10
    [linf, logf, svmf] = feature_selection(DA(:,:,d),Y);
    [Train_MSE, Test_MSE] = cross_validate(DA(:,:,d),Y,linf,logf,svmf);
    DA_Train_MSE(:,:,d) = Train_MSE;
    DA_Test_MSE(:,:,d) = Test_MSE;
end

DA_Train_Mean = mean(DA_Train_MSE);
DA_Test_Mean = mean(DA_Test_MSE);

lin_train = DA_Train_Mean(:,1,:);
lin_test = DA_Test_Mean(:,1,:);
log_train = DA_Train_Mean(:,2,:);
log_test = DA_Test_Mean(:,2,:);
svm_train = DA_Train_Mean(:,3,:);
svm_test = DA_Test_Mean(:,3,:);

figure();
hold on;
scatter(alpha, lin_train,'filled','db');
scatter(alpha, lin_test,'filled','dg');
scatter(alpha, log_train,'filled','*b');
scatter(alpha, log_test,'filled','*g');
scatter(alpha, svm_train,'filled','xb');
scatter(alpha, svm_test,'filled','xg');

xlabel('Alpha');
ylabel('Error');
legend('Linear Training', 'Linear Testing', 'Logistic Training', 'Logistic Testing', 'SVM Training', 'SVM Testing');
hold off;



%% PCA Clustering
PCAC_Train_MSE = zeros(100,3,3,4);
PCAC_Test_MSE = zeros(100,3,3,4);
pca = [4,10,15];
K = [2,3,5,10];
for p=1:3
    for k=1:4
        [linf, logf, svmf] = feature_selection(PCAC(:,:,p,k),Y);
        [Train_MSE, Test_MSE] = cross_validate(PCAC(:,:,p,k),Y,linf,logf,svmf);
        PCAC_Train_MSE(:,:,p,k) = Train_MSE;
        PCAC_Test_MSE(:,:,p,k) = Test_MSE;
    end
end
PCAC_Train_Mean = mean(PCAC_Train_MSE);
PCAC_Test_Mean = mean(PCAC_Test_MSE);

for i=1:3
    figure();
    hold on;
    scatter(PCAC_Train_Mean(:,1,i,:),alpha,'filled','db');
    scatter(PCAC_Train_Mean(:,1,i,:),alpha,'filled','dg');
    scatter(PCAC_Train_Mean(:,2,i,:),alpha,'filled','*b');
    scatter(PCAC_Train_Mean(:,2,i,:),alpha,'filled','*g');
    scatter(PCAC_Train_Mean(:,3,i,:),alpha,'filled','xb');
    scatter(PCAC_Train_Mean(:,3,i,:),alpha,'filled','xg');
    xlabel('Clusters');
    ylabel('Error');
    legend('Linear Training', 'Linear Testing', 'Logistic Training', 'Logistic Testing', 'SVM Training', 'SVM Testing');
    hold off;
end