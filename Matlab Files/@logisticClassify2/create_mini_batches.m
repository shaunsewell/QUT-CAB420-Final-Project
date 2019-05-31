function mini_batches = create_mini_batches(obj, X,y, batch_size )

%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

data_values = [X,y];

data_values = shuffleData(data_values); %TODO  shuffle your data
[n,d] = size(data_values);
n_mini_batches = floor(n/batch_size); %TODO  based on your data and the batch size compute the number of batches
mini_batches = zeros(batch_size,d,n_mini_batches);

for i = 1:n_mini_batches
   %TODO extract the minibatch values
   mini_batches(:, :, i) = data_values((i-1)*batch_size +1:i*batch_size,:);
end

end