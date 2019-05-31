function plot2DLinear(obj, X, Y)
% plot2DLinear(obj, X,Y)
%   plot a linear classifier (data and decision boundary) when features X are 2-dim
%   wts are 1x3,  wts(1)+wts(2)*X(1)+wts(3)*X(2)
%
  [n,d] = size(X);
  if(d~=2) 
      error('Sorry -- plot2DLogistic only works on 2D data...'); 
  end;

  %%% TODO: Fill in the rest of this function...  
  classes=unique(Y);
  if(length(classes)~=2) 
      error('Sorry -- plot2DLinear only works on binary data'); 
  end;
  c0 = find(Y==classes(1)); 
  c1=find(Y==classes(2));
  %Xplt = linspace(min(Xtrain(:,1)), max(Xtrain(:,1)), 200);
  Xplt = linspace(min(X(:,1)), max(X(:,1)), 200);
  % decision boundary is:
  % logistic( w2 x2 + w1 x1 + w0 ) =.5 <=> w2 x2 + w1 x1 + w0 = 0 <=> x2 = -w0 -w1/w2 x1;
  plot(X(c0,1),X(c0,2),'bo',... % class zero training data
       X(c1,1),X(c1,2),'rs',... % class one training data
       Xplt,-obj.wts(1)/obj.wts(3) - obj.wts(2)/obj.wts(3).*Xplt, 'k-'); % decision boundary
  drawnow;