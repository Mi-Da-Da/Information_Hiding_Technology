function Visual_Cryptography()
    % 读取图像
    img = imread("1.png");
    
    % 选择模式
    mode = input('请选择: 1-二值, 2-灰度, 3-彩色: ');
    
    switch mode
        case 1
            processBinary(img);
        case 2
            processGray(img);
        case 3
            processColor(img);
    end
end

% 二值图像处理
function processBinary(img)
    % 如果是彩色图像转换为二值图像
    if size(img,3)==3
        img = rgb2gray(img); 
    end
    img = imbinarize(img);
    % 获取原始图像的长宽
    [h,w] = size(img);
    % 初始化分享图
    s1 = zeros(2*h,2*w); 
    s2 = zeros(2*h,2*w);
    % 预定义像素块模式，第一种模式为白黑黑白，第二种模式为黑白白黑
    patterns = {
        [1 0;0 1], 
        [0 1;1 0]
    };
    
    % 编码
    for i=1:h
        for j=1:w
            r = randi(2); 
            p = patterns{r};
            % 如果像素为白色
            if img(i,j)==1
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = 1-p;
            % 像素为黑色
            else
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = p;
            end
        end 
    end
    
    % 恢复后的图像
    recover = xor(s1, s2);
    
    % 显示结果
    figure;
    subplot(221); imshow(img); title('原图');
    subplot(222); imshow(s1); title('分享1');
    subplot(223); imshow(s2); title('分享2');
    subplot(224); imshow(recover); title('恢复');
    
    imwrite(s1, "Binary Visual Secret Sharing_1.png");
    imwrite(s2, "Binary Visual Secret Sharing_2.png");
    imwrite(recover, "Binary Recovery.png");
end

% 灰度图像处理（使用误差扩散半色调）
function processGray(img)
    % 如果是彩色图像转换为二值图像
    if size(img,3)==3 
        img = rgb2gray(img); 
    end
    
    % 使用误差扩散半色调
    bw = errorDiffusionHalftone(img);
    
    [h,w] = size(bw);
    s1 = zeros(2*h,2*w); 
    s2 = zeros(2*h,2*w);
    patterns = {
        [1 0;0 1], 
        [0 1;1 0]
    };
    
    for i=1:h
        for j=1:w
            r = randi(2); 
            p = patterns{r};
            if bw(i,j)==1
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = 1-p;
            else
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = p;
            end
        end
    end
    
    recover = xor(s1,s2);
    
    figure;
    subplot(231); imshow(img); title('原图');
    subplot(232); imshow(bw); title('半色调');
    subplot(233); imshow(s1); title('分享1');
    subplot(234); imshow(s2); title('分享2');
    subplot(235); imshow(recover); title('恢复');

    imwrite(bw, "Halftone.png");
    imwrite(s1, "Grayscale Visual Secret Sharing_1.png");
    imwrite(s2, "Grayscale Visual Secret Sharing_2.png");
    imwrite(recover, "Grayscale Recovery.png");
end

% 彩色图像处理
function processColor(img)
    if size(img,3)~=3, error('需要彩色图'); end
    
    % 分离RGB通道
    R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
    
    % 分别处理每个通道（使用误差扩散）
    [s1R,s2R] = processColorChannel(R);
    [s1G,s2G] = processColorChannel(G);
    [s1B,s2B] = processColorChannel(B);
    
    % 合成彩色分享图
    s1 = cat(3, uint8(s1R*255), uint8(s1G*255), uint8(s1B*255));
    s2 = cat(3, uint8(s2R*255), uint8(s2G*255), uint8(s2B*255));
    
    % 叠加恢复
    restoredR = xor(s1R, s2R);
    restoredG = xor(s1G, s2G);
    restoredB = xor(s1B, s2B);
    
    % 转换为可显示的格式
    recover = cat(3, uint8(restoredR*255), ...
                      uint8(restoredG*255), ...
                      uint8(restoredB*255));
    
    figure;
    subplot(221); imshow(img); title('原图(彩色)');
    subplot(222); imshow(s1); title('分享1');
    subplot(223); imshow(s2); title('分享2');
    subplot(224); imshow(recover); title('恢复');

    imwrite(s1, "Color Visual Secret Sharing_1.png");
    imwrite(s2, "Color Visual Secret Sharing_2.png");
    imwrite(recover, "Color Recovery.png");
end

% 处理单个颜色通道（带误差扩散）
function [s1,s2] = processColorChannel(ch)
    % 使用误差扩散半色调
    bw = errorDiffusionHalftone(ch);
    
    [h,w] = size(bw);
    s1 = zeros(2*h,2*w);
    s2 = zeros(2*h,2*w);
    patterns = {[1 0;0 1], [0 1;1 0]};
    
    for i=1:h
        for j=1:w
            r = randi(2); p = patterns{r};
            if bw(i,j)==1
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = 1-p;
            else
                s1(2*i-1:2*i,2*j-1:2*j) = p;
                s2(2*i-1:2*i,2*j-1:2*j) = p;
            end
        end
    end
end

% Floyd-Steinberg 误差扩散半色调
function bw = errorDiffusionHalftone(img)
    % 转换为double便于计算
    img = double(img);
    [h,w] = size(img);
    bw = zeros(h,w);

    % 逐像素处理
    for i=1:h
        for j=1:w
            old = img(i,j);
            % 判断原像素是否大于127并将逻辑值存入数组
            if old > 127
                new = 255;
            else
                new = 0;
            end
            bw(i,j) = new > 128;
            
            % 计算误差
            error = old - new;
            
            % 扩散误差到相邻像素
            if j < w
                img(i, j+1) = img(i, j+1) + error * 7/16;
            end
            if i < h
                if j > 1
                    img(i+1, j-1) = img(i+1, j-1) + error * 3/16;
                end
                img(i+1, j) = img(i+1, j) + error * 5/16;
                if j < w
                    img(i+1, j+1) = img(i+1, j+1) + error * 1/16;
                end
            end
        end
    end
end