function [Train_Percent, trainACCList, Test_Percent, testACCList] = BP_ORL(prototypeFACE)
    % only need to train and test total 100 records
    % prototypeFACE = prototypeFACE(1:length(prototypeFACE) / 4, :);

    %最低分80分softmax就有90分以上

    % value-min/max-min in all vlaue prototypeFACE (正規化)
    minNum = inf; maxNum = -inf;

    for i = 1:length(prototypeFACE)

        for j = 1:length(prototypeFACE(i))

            if minNum > prototypeFACE(i, j)
                minNum = prototypeFACE(i, j);
            end

            if maxNum < prototypeFACE(i, j)
                maxNum = prototypeFACE(i, j);
            end

        end

    end

    for i = 1:length(prototypeFACE)

        for j = 1:length(prototypeFACE(i))

            prototypeFACE(i, j) = (prototypeFACE(i, j) - minNum) / (maxNum - minNum);

        end

    end

    input = prototypeFACE(1:2:end, :);

    targetNum = 40; % tag num = 40 (個分類)
    tmpNUM = 30; % node num 30 is enough
    length_i = length(input);
    length_j = 20; % data 寬度 = ldanum

    % epochMax = 2000;
    % learningRate = 0.65;
    epochMax = 5000;
    learningRate = 0.65;

    % tag of the dataset
    target = [];

    % 40 * 5 = 200
    for i = 1:targetNum

        for j = 1:5
            temp = zeros(targetNum, 1);
            temp(i) = 1;
            target = cat(3, target, temp);
        end

    end

    % size(target) = 40 1 200

    % initialize the weight matrix
    outputmatrix = [];

    for k = 1:1:targetNum
        tempM = zeros(tmpNUM, 1);

        for i = 1:1:tmpNUM

            for j = 1:1:1
                tempM(i, j) = rand;
            end

        end

        outputmatrix = cat(3, outputmatrix, tempM);
    end

    % size(outputmatrix) = 30 1 40

    hiddenmatrix = zeros(length_j, tmpNUM);

    for i = 1:1:length_j

        for j = 1:1:tmpNUM
            hiddenmatrix(i, j) = rand;
        end

    end

    % size(hiddenmatrix) = 20 30

    RMSE = zeros(epochMax, 1);

    % Training
    for epoch = 1:1:epochMax
        t = [];

        for iter = 1:1:length_i

            % 前傳部分
            % size(input(iter, :)) = 1 20
            % size(hiddenmatrix) = 20 30
            hiddensigma = input(iter, :) * hiddenmatrix;
            hiddennet = logsig(hiddensigma);
            % size(hiddensigma) = 1 30

            outputsigma = [];
            outputnet = [];

            for i = 1:targetNum
                tempNum1 = hiddennet * outputmatrix(:, :, i);
                % size(tempNum1) = 1 1
                outputsigma = [outputsigma; tempNum1];
                % outputnet = [outputnet; purelin(tempNum1)];
                outputnet = [outputnet; tansig(tempNum1)];
            end

            % size(outputsigma) = 40 1
            % size(outputnet) = 40 1

            % 倒傳部分
            % 輸出層的 delta
            % doutputnet = [];
            deltaoutput = [];
            tempError = 0; %error

            for i = 1:targetNum
                tempNum2 = dpurelin(outputsigma(i, :));
                % tempNum1 = hiddennet * outputmatrix(:, :, i);
                % tempNum2 = dtansig(tempNum1, tansig(tempNum1));
                % doutputnet = [doutputnet; tempNum2];
                temp_ = target(:, :, iter) - outputnet(i, :);
                deltaoutput = [deltaoutput; temp_ * tempNum2];
                tempError = tempError + temp_;
            end

            tempError = tempError / targetNum;
            t = [t; tempError.^2];

            % 隱藏層的 delta
            index = ceil(iter / 5);
            tempdelta = deltaoutput(index, :) * outputmatrix(:, :, index);

            % tempdelta = zeros(tmpNUM, 1);
            % for i = 1:targetNum
            %     % tempdelta = [tempdelta; deltaoutput(i, :) * outputmatrix(:, :, i)];
            %     tempdelta = tempdelta + deltaoutput(i, :) * outputmatrix(:, :, i);
            % end
            % tempdelta = tempdelta / targetNum;
            % size(tempdelta) = 30 1
            transfer = dlogsig(hiddensigma, logsig(hiddensigma));
            deltahidden = [];

            for i = 1:1:tmpNUM
                deltahidden = [deltahidden; tempdelta(i) * transfer(i)];
            end

            % 輸出層權重更新
            for i = 1:targetNum
                outputmatrix(:, :, i) = outputmatrix(:, :, i) + learningRate * (deltaoutput(i, :) * hiddennet)';
            end

            % 隱藏層權重更新
            newhiddenmatrix = hiddenmatrix;

            for i = 1:1:tmpNUM

                for j = 1:1:length_j
                    newhiddenmatrix(j, i) = hiddenmatrix(j, i) + learningRate * deltahidden(i, :) * input(j);
                    % maybe can change the weight of deltahidden
                end

            end

            if learningRate > 0.005 %& epoch > 50
                learningRate = learningRate - 0.005;
            end

            hiddenmatrix = newhiddenmatrix;
        end

        RMSE(epoch) = sqrt(sum(t) / length_i);
        fprintf('epoch %.0f:  RMSE = %.3f\n', epoch, RMSE(epoch));
    end

    fprintf('\nTotal number of epochs: %g\n', epoch);
    fprintf('Final RMSE: %g\n', RMSE(epoch));
    plot(1:epoch, RMSE(1:epoch));
    legend('Training');
    ylabel('RMSE'); xlabel('Epoch');

    % train
    Train_Correct = 0;
    trainACCList = [];

    for i = 1:length_i
        hiddensigma = input(i, :) * hiddenmatrix;
        hiddennet = logsig(hiddensigma);

        outputsigma = [];
        outputnet = [];
        maxNum = -inf; maxNumIdx = 0;

        for j = 1:targetNum
            outputsigma = [outputsigma, hiddennet * outputmatrix(:, :, j)];
            outputnet = [outputnet, purelin(outputsigma(j))];
        end

        for j = 1:targetNum

            if maxNum < outputnet(j)
                maxNum = outputnet(j);
                maxNumIdx = j;
            end

        end

        maxNum = -inf; correctIdx = 0;

        for j = 1:targetNum

            if maxNum < target(j, :, i)
                maxNum = target(j, :, i);
                correctIdx = j;
            end

        end

        if maxNumIdx ~= correctIdx
            Train_Correct = Train_Correct + 1;
            % ansList = [i, correctIdx];
            ansList = [i, maxNumIdx, correctIdx];
            trainACCList = [trainACCList; ansList];
        end

    end

    Train_Percent = Train_Correct / length_i;

    % test
    input = prototypeFACE(2:2:end, :);

    Test_Correct = 0;
    testACCList = [];

    for i = 1:length(input)
        hiddensigma = input(i, :) * hiddenmatrix;
        hiddennet = logsig(hiddensigma);

        outputsigma = [];
        outputnet = [];
        maxNum = -inf; maxNumIdx = 0;

        for j = 1:targetNum
            outputsigma = [outputsigma, hiddennet * outputmatrix(:, :, j)];
            outputnet = [outputnet, purelin(outputsigma(j))];
        end

        for j = 1:targetNum

            if maxNum < outputnet(j)
                maxNum = outputnet(j);
                maxNumIdx = j;
            end

        end

        maxNum = -inf; correctIdx = 0;

        for j = 1:targetNum

            if maxNum < target(j, :, i)
                maxNum = target(j, :, i);
                correctIdx = j;
            end

        end

        if maxNumIdx ~= correctIdx
            Test_Correct = Test_Correct + 1;
            % ansList = [i, correctIdx];
            ansList = [i, maxNumIdx, correctIdx];
            testACCList = [testACCList; ansList];
        end

    end

    Test_Percent = Test_Correct / length(input);

    % acc > 0.9
end
