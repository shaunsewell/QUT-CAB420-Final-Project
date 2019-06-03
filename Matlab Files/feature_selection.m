function [lin_mod,log_mod,svm_mod] = feature_selection(X,Y)
% linear regression
warning off   
opt = statset('display','iter','TolTypeFun','abs');

lin_mod = sequentialfs(@critfun,X,Y,...
                       'cv','none',...
                       'nullmodel',true,...
                       'options',opt,...
                       'direction','forward');

% logistic regression
log_mod = sequentialfs(@logfun,X,Y,'cv','none','options',opt);

% svm
svm_mod = sequentialfs(@svmfun,X,Y,'cv','none','options',opt);

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