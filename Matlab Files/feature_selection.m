clear ; close all; clc
addpath(genpath('Matlab Files'));
load("AFLData.mat");

%% Feature Selection

data = [train; test];
running_average = zeros(18,25);
feature_vector = [];
match_result = [];

for season = 1:7
    % initialise the running average to the values after round 1
    % 9 matches in a round so the first 18 lines represent round 1
    season
    
    for t = 1:18
       team = data(t, 2, season);
       running_average(team, :) = data( t, 5:29, season); 
    end

    % training the models
    % matches are stat pairs i.e 1&2 make match 1 and so on
    for match = 19:2:414
        team_a_real = data(match, :, season);
        team_b_real = data(match + 1, :, season);
        
        team_a_pred = running_average(team_a_real(2), :);
        team_b_pred = running_average(team_b_real(2), :);
        
        % find the recorded winner of the match
        % 1 = team_a wins, 0 = team_b wins. 0.5 = draw
        if team_a_real(30) == 1
            match_result = [match_result; 1];
        elseif team_b_real(30) == 1
            match_result = [match_result; 0];
        else
            match_result = [match_result; 0];
        end

        % make the feature vector x = xa - xb
        features =  team_a_pred(1,:) - team_b_pred(1,:);
        feature_vector = [feature_vector; features];


        % update averages
        running_totals_a = running_average(team_a_real(2), :) * (team_a_real(1) - 1);
        running_average(team_a_real(2), :) = (running_totals_a + team_a_real(5:29)) ./ team_a_real(1);

        running_totals_b = running_average(team_b_real(2), :) * (team_b_real(1) - 1);
        running_average(team_b_real(2), :) = (running_totals_b + team_b_real(5:29)) ./ team_b_real(1);
    end

    % linear regression
    warning off   
    opt = statset('display','iter','TolTypeFun','abs');

    lin_model = sequentialfs(@critfun,feature_vector,match_result,...
                           'cv','none',...
                           'nullmodel',true,...
                           'options',opt,...
                           'direction','forward');

    % logistic regression
    log_model = sequentialfs(@logfun,feature_vector,match_result,'cv','none','options',opt);

    % svm
    svm_model = sequentialfs(@svmfun,feature_vector,match_result,'cv','none','options',opt);
    
    feature_vector = [];
    running_average = zeros(18,25);
    match_result = [];
end
function error = svmfun(X, Y)
    Xtr = X(1:144, :);
    Ytr = Y(1:144);
    Xte = X(145:198, :);
    Yte = Y(145:198);
    model = fitclinear(Xtr, Ytr,'Learner','svm');
    pred = predict(model, Xte);
    error = mean( (Yte - pred).^2 );
end

function error = logfun(X, Y)
    Xtr = X(1:144, :);
    Ytr = Y(1:144);
    Xte = X(145:198, :);
    Yte = Y(145:198);
    model = fitclinear(Xtr, Ytr,'Learner','logistic');
    pred = predict(model, Xte);
    error = mean( (Yte - pred).^2 );
end    
               
function error = critfun(X,Y)
    Xtr = X(1:144, :);
    Ytr = Y(1:144);
    Xte = X(145:198, :);
    Yte = Y(145:198);
    model = fitglm(Xtr, Ytr, 'quadratic', 'Distribution','binomial');
    pred = predict(model, Xte);
    error = mean( (Yte - pred).^2 );
end