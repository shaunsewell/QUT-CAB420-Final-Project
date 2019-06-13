function [Train_MSE, Test_MSE] = cross_validate(X, Y, linf, logf, svmf)
% Performs cross validation training and testing. X is the feature vectors
% and Y is the result from a match. linf, logf and svmf are the vectors of
% features selected to use to create each model. 
% 
% Returns Train_MSE and Test_MSE which contain the MSE for each iteration. 
% 
    Train_MSE = zeros(100,3);
    Test_MSE = zeros(100,3);

    for cv=1:100
        % Randomise
        idx = randperm(1386);
        tr_idx = idx(1:970);
        te_idx = idx(971:1386);

        % Split the data into training and testing sets
        Xtr = X(tr_idx, :);
        Ytr = Y(tr_idx);
        Xte = X(te_idx, :);
        Yte = Y(te_idx);

        % Build models
        lin_model = fitglm(Xtr(:,linf), Ytr, 'quadratic', 'Distribution','binomial');
        log_model = fitclinear(Xtr(:,logf), Ytr,'Learner','logistic');
        svm_model = fitclinear(Xtr(:,svmf), Ytr,'Learner','svm');

        % Predict and measure errors
        pred_tr_lin = round(predict(lin_model, Xtr(:,linf)));
        Train_MSE(cv,1) = mean( (Ytr - pred_tr_lin).^2 );
        pred_te_lin = round(predict(lin_model, Xte(:,linf)));
        Test_MSE(cv,1) = mean( (Yte - pred_te_lin).^2 );

        pred_tr_log = round(predict(log_model, Xtr(:,logf)));
        Train_MSE(cv,2) = mean( (Ytr - pred_tr_log).^2 );
        pred_te_log = round(predict(log_model, Xte(:,logf)));
        Test_MSE(cv,2) = mean( (Yte - pred_te_log).^2 );

        pred_tr_svm = round(predict(svm_model, Xtr(:,svmf)));
        Train_MSE(cv,3) = mean( (Ytr - pred_tr_svm).^2 );
        pred_te_svm = round(predict(svm_model, Xte(:,svmf)));
        Test_MSE(cv,3) = mean( (Yte - pred_te_svm).^2 );
    end

end