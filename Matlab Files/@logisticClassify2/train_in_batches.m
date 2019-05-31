function obj = train_in_batches(obj, X, Y, batch_size, varargin)
% obj = train(obj, Xtrain, Ytrain [, option,val, ...])  : train logistic classifier
%     Xtrain = [n x d] training data features (constant feature not included)
%     Ytrain = [n x 1] training data classes 
%     'stepsize', val  => step size for gradient descent [default 1]
%     'stopTol',  val  => tolerance for stopping criterion [0.0]
%     'stopIter', val  => maximum number of iterations through data before stopping [1000]
%     'reg', val       => L2 regularization value [0.0]
%     'init', method   => 0: init to all zeros;  1: init to random weights;  
% Output:
%   obj.wts = [1 x d+1] vector of weights; wts(1) + wts(2)*X(:,1) + wts(3)*X(:,2) + ...


  [n,d] = size(X);            % d = dimension of data; n = number of training data

  % default options:
  plotFlag = true; 
  init     = []; 
  stopIter = 1000;
  stopTol  = -1;
  reg      = 0.0;
  stepsize = 1;

  i=1;                                       % parse through various options
  while (i<=length(varargin)),
    switch(lower(varargin{i}))
    case 'plot',      plotFlag = varargin{i+1}; i=i+1;   % plots on (true/false)
    case 'init',      init     = varargin{i+1}; i=i+1;   % init method
    case 'stopiter',  stopIter = varargin{i+1}; i=i+1;   % max # of iterations
    case 'stoptol',   stopTol  = varargin{i+1}; i=i+1;   % stopping tolerance on surrogate loss
    case 'reg',       reg      = varargin{i+1}; i=i+1;   % L2 regularization
    case 'stepsize',  stepsize = varargin{i+1}; i=i+1;   % initial stepsize
    end;
    i=i+1;
  end;

  X1    = [ones(n,1), X];     % make a version of training data with the constant feature

  Yin = Y;                              % save original Y in case needed later
  obj.classes = unique(Yin);
  if (length(obj.classes) ~= 2) error('This logistic classifier requires a binary classification problem.'); end;
  Y(Yin==obj.classes(1)) = 0;
  Y(Yin==obj.classes(2)) = 1;           % convert to classic binary labels (0/1)

  if (~isempty(init) || isempty(obj.wts))   % initialize weights and check for correct size
    obj.wts = randn(1,d+1);
  end;
  if (any( size(obj.wts) ~= [1 d+1]) ) error('Weights are not sized correctly for these data'); end;
  wtsold = 0*obj.wts+inf;

% Training loop (SGD):
iter=1; Jsur=zeros(1,stopIter); J01=zeros(1,stopIter); done=0; 
while (~done) 
  step = stepsize/iter;               % update step-size and evaluate current loss values
  sig = logistic(obj, X);   % compute outputs: sigma( Xtrain * wts' )
  Jsur(iter) = mean([-log(sig(Y==1)); -log(1-sig(Y==0))]) + reg*sum(obj.wts.^2);   %%% TODO: compute surrogate (neg log likelihood) loss
  J01(iter) = err(obj,X,Yin);

  if (plotFlag), switch d,            % Plots to help with visualization
    case 1, fig(2); plot1DLinear(obj,X,Yin);  %  for 1D data we can display the data and the function
    case 2, fig(2); plot2DLinear(obj,X,Yin);  %  for 2D data, just the data and decision boundary
    otherwise, % no plot for higher dimensions... %  higher dimensions visualization is hard
  end; end;
  fig(1); semilogx(1:iter, Jsur(1:iter),'b-',1:iter,J01(1:iter),'g-'); drawnow;
  mini_batches = create_mini_batches(obj, X, Y, 11);%%% TODO call your create_mini_batches function with batchsize = 11
  [batch_size, dim, number_of_batches] = size(mini_batches);
  for j=1:number_of_batches,
    % Compute linear responses and activation for minibatch j
    %%% TODO ^^^
    mini_X = mini_batches(:, 1:dim-1, j);
    mini_Y = mini_batches(:, dim, j);
    sigx = logistic(obj,mini_X); % compute output for example j
    % Compute gradient:
    %%% TODO ^^^
    mini_X1 = [ones(batch_size,1) mini_X];
    grad = mean(-mini_Y.*(1-sigx).*mini_X1 + (1-mini_Y).*sigx.*mini_X1, 1) + reg*obj.wts;
    obj.wts = obj.wts - step * grad;      % take a step down the gradient
  end;

  done = false;
  %%% TODO: Check for stopping conditions
  done = (iter>stopIter) || ((iter>1) && abs(Jsur(iter)-Jsur(iter-1))<stopTol);
  wtsold = obj.wts;
  iter = iter + 1;
end;


