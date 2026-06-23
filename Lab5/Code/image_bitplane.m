% 图像位平面处理
% 实现位平面提取、显示和操作
close all;
clc;

% 加载图像
disp('加载图像...');
imageFile = '../Picture/1.png';
img = imread(imageFile);

% 转换为灰度图像
if size(img, 3) > 1
    img = rgb2gray(img);
end

% 转换为双精度类型以便处理
img = double(img);
[m, n] = size(img);
disp(['图像大小: ', num2str(m), 'x', num2str(n)]);

% 显示原始图像
figure;
subplot(2, 2, 1);
imshow(uint8(img));
title('原始图像');

% 提取并显示任意位平面
function displayBitPlane(img, bit)
    bitPlane = bitget(uint8(img), bit);
    % 转换为0-255范围以便显示
    bitPlane = bitPlane * 255;
    
    figure;
    imshow(uint8(bitPlane));
    title(['第', num2str(bit), '位平面']);
end

% 显示1~n低位平面的图像
function displayLowerBitPlanes(img, n)
    lowerPlanes = 0;
    for i = 1:n
        lowerPlanes = lowerPlanes + bitget(uint8(img), i) * 2^(i-1);
    end
    
    figure;
    imshow(uint8(lowerPlanes));
    title(['1~', num2str(n), '低位平面']);
end

% 显示(n+1)~8高位平面的图像
function displayUpperBitPlanes(img, n)
    upperPlanes = 0;
    for i = n+1:8
        upperPlanes = upperPlanes + bitget(uint8(img), i) * 2^(i-1);  % 权重不变
    end
    
    figure;
    imshow(uint8(upperPlanes));
    title(['第', num2str(n+1), '~8位高位平面']);
end

% 显示去掉1~n位平面后的图像
function displayImageWithoutLowerPlanes(img, n)
    result = 0;
    for i = n+1:8
        result = result + bitget(uint8(img), i) * 2^(i-1);
    end
    
    figure;
    imshow(uint8(result));
    title(['去掉1~', num2str(n), '位平面后的图像']);
end

% 显示所有8个位平面
figure('Name', '所有位平面', 'Position', [100, 100, 1000, 800]);
for i = 1:8
    bitPlane = bitget(uint8(img), i) * 255;
    subplot(2, 4, i);
    imshow(uint8(bitPlane));
    title(['第', num2str(i), '位平面']);
end

% 测试低位平面显示
disp('测试低位平面显示...');
displayLowerBitPlanes(img, 3);
displayLowerBitPlanes(img, 5);

% 测试高位平面显示
disp('测试高位平面显示...');
displayUpperBitPlanes(img, 3);
displayUpperBitPlanes(img, 5);

% 测试去掉低位平面后的图像
disp('测试去掉低位平面后的图像...');
displayImageWithoutLowerPlanes(img, 3);
displayImageWithoutLowerPlanes(img, 5);

disp('测试完成！');
