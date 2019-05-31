%% *CAB420 Final Project*
% *Predicting the result of AFL matches*
% Shaun Sewell
%
% N9509623


clear ; close all; clc
addpath(genpath('Matlab Files'));
load("AFLData.mat");

%% Running average

running_average = zeros(18,25);
feature_vector = zeros(1,24);
winner = 0;
for season = 1:7
   
% initialise the running average to the values after round 1
% 9 matches in a round so the first 18 lines represent round 1
    for t = 1:18
       team = train(t, 2, season);
       running_average(team, :) = train( t, 5:29, season); 
    end
    
    % training the models
    % matches are stat pairs i.e 1&2 make match 1 and so on
    for match = 19:2:288
        team_a = train(match, :, season);
        team_b = train(match + 1, :, season);
        
        % find the recorded winner of the match
        % 1 = team_a wins, 0 = team_b wins. ignoring draws for simplicity
        if team_a(30) == 1
            winner = 1;
        elseif team_b(30) == 1
            winner = 0;
        end
        
        % make the feature vector x = xa - xb
        feature_vector = team_a(5:29) - team_b(5:29);
        
        % do ml stuff
        
        
        % update averages
        running_totals_a = running_average(team_a(2), :) * (team_a(1) - 1);
        running_average(team_a(2), :) = (running_totals_a + team_a(5:29)) ./ team_a(1);
        
        running_totals_b = running_average(team_b(2), :) * (team_b(1) - 1);
        running_average(team_b(2), :) = (running_totals_b + team_b(5:29)) ./ team_b(1);
    end
end