% 2012-2018.mat is just the csv files converted to matlab form using the
% importing tool.
addpath(genpath('Matlab Files'));
load("2012-2018.mat");

% create training and test splits

% 288 is 144 matches which is approx %70
train2012 = AFLStats2012(1:288,2:31);
test2012 = AFLStats2012(289:414,2:31);

train2013 = AFLStats2013(1:288,2:31);
test2013 = AFLStats2013(289:414,2:31);

train2014 = AFLStats2014(1:288,2:31);
test2014 = AFLStats2014(289:414,2:31);

train2015 = AFLStats2015(1:288,2:31);
test2015 = AFLStats2015(289:414,2:31);
% Correction for cancelled game.
test2015(125:126,:) = 1;

train2016 = AFLStats2016(1:288,2:31);
test2016 = AFLStats2016(289:414,2:31);

train2017 = AFLStats2017(1:288,2:31);
test2017 = AFLStats2017(289:414,2:31);

train2018 = AFLStats2018(1:288,2:31);
test2018 = AFLStats2018(289:414,2:31);

train = zeros(288, 30, 7);
test = zeros(126, 30, 7);

train(:, :, 1) = train2012;
train(:, :, 2) = train2013;
train(:, :, 3) = train2014;
train(:, :, 4) = train2015;
train(:, :, 5) = train2016;
train(:, :, 6) = train2017;
train(:, :, 7) = train2018;

test(:, :, 1) = test2012;
test(:, :, 2) = test2013;
test(:, :, 3) = test2014;
test(:, :, 4) = test2015;
test(:, :, 5) = test2016;
test(:, :, 6) = test2017;
test(:, :, 7) = test2018;

% Now the train and test variables can be saved.
save AFLData.mat train test
