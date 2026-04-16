clear; clc; close all;
% 读入图像并预处理
b = imread('../Picture/1.png');    
b = rgb2gray(b);            
I = im2double(b);    

figure(1);
imshow(b);
title('(a)原图像');

% 参数设置
discard_ratios = [15, 30, 50, 80];  
keep_ratios = 1 - discard_ratios/100;  

% 存储PSNR结果和重建图像
psnr_fft = zeros(1, length(keep_ratios));
psnr_dct = zeros(1, length(keep_ratios));
psnr_dwt = zeros(1, length(keep_ratios));

img_fft_all = cell(1, length(keep_ratios));
img_dct_all = cell(1, length(keep_ratios));
img_dwt_all = cell(1, length(keep_ratios));

% FFT原始幅度谱
fa = fft2(I);
ffa = fftshift(fa);
figure(2);
imshow(log(abs(ffa)+1), []);
title('(b)FFT原始幅度谱');

figure(3);
% 降采样减少数据点，显示更清晰
step = 4;  % 每4个点取1个
ffa_small = abs(ffa(1:step:end, 1:step:end));
surf(ffa_small, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
view(45, 30);
colormap("parula");
colorbar;
title('(c)FFT能量谱峰图');
xlabel('频率');
ylabel('频率');
zlabel('能量');
lighting phong;
light('Position', [1 1 1]);
grid on;

% FFT变换及压缩
for i = 1:length(keep_ratios)
    keep = keep_ratios(i);
    discard = discard_ratios(i);
    
    % 调用FFT压缩函数
    [img_recon, psnr_val] = fft_compress(I, keep);
    
    % 存储结果
    img_fft_all{i} = img_recon;
    psnr_fft(i) = psnr_val;
end

% DCT原始系数
c = dct2(I);
figure(4);
imshow(c);
title('(d)DCT原始变换系数');

figure(5);
% 使用对数尺度处理DCT系数
log_c = log(abs(c) + 1);
surf(log_c, 'EdgeColor', 'none', 'FaceAlpha', 0.9);
view(45, 30);
colormap(jet);
colorbar;
title('(e)DCT系数能量分布', 'FontSize', 12);
xlabel('水平频率', 'FontSize', 10);
ylabel('垂直频率', 'FontSize', 10);
zlabel('log(|DCT系数|)', 'FontSize', 10);
shading interp;
lighting gouraud;
light('Position', [1 1 1]);
grid on;

% DCT变换及压缩
for i = 1:length(keep_ratios)
    keep = keep_ratios(i);
    discard = discard_ratios(i);
    
    % 调用DCT压缩函数
    [img_recon, psnr_val] = dct_compress(I, keep);
    
    % 存储结果
    img_dct_all{i} = img_recon;
    psnr_dct(i) = psnr_val;
end

% DWT原始系数
[ca1, ch1, cv1, cd1] = dwt2(I, 'db4');
[ca2, ch2, cv2, cd2] = dwt2(ca1, 'db4');
nbcol = size(ca2,1);
nbc = size(ch1,1);
cod_ca2 = wcodemat(ca2, nbcol);
cod_ch2 = wcodemat(ch2, nbcol);
cod_cv2 = wcodemat(cv2, nbcol);
cod_cd2 = wcodemat(cd2, nbcol);
cod_ch1 = wcodemat(ch1, nbc);
cod_cv1 = wcodemat(cv1, nbc);
cod_cd1 = wcodemat(cd1, nbc);
tt = [cod_ca2, cod_ch2; cod_cv2, cod_cd2];
tt = imresize(tt, size(ch1));
figure(6)
image([tt, cod_ch1; cod_cv1, cod_cd1])
colormap(gray(255))
title('(f)二级DWT变换系数')

% DWT变换及压缩
for i = 1:length(keep_ratios)
    keep = keep_ratios(i);
    discard = discard_ratios(i);
    
    % 调用DWT压缩函数
    [img_recon, psnr_val] = dwt_compress(I, keep);
    
    % 存储结果
    img_dwt_all{i} = img_recon;
    psnr_dwt(i) = psnr_val;
end

% 显示FFT不同丢弃比例的重建图像
figure(7);
for i = 1:length(discard_ratios)
    subplot(1, 4, i);
    imshow(img_fft_all{i});
    title(sprintf('FFT 丢弃%d%%\nPSNR=%.2f dB', discard_ratios(i), psnr_fft(i)), 'FontSize', 10);
end
sgtitle('FFT 变换：不同丢弃比例下的重建图像对比', 'FontSize', 14);

% 显示DCT不同丢弃比例的重建图像
figure(8);
for i = 1:length(discard_ratios)
    subplot(1, 4, i);
    imshow(img_dct_all{i});
    title(sprintf('DCT 丢弃%d%%\nPSNR=%.2f dB', discard_ratios(i), psnr_dct(i)), 'FontSize', 10);
end
sgtitle('DCT 变换：不同丢弃比例下的重建图像对比', 'FontSize', 14);

% 显示DWT不同丢弃比例的重建图像
figure(9);
for i = 1:length(discard_ratios)
    subplot(1, 4, i);
    imshow(img_dwt_all{i});
    title(sprintf('DWT 丢弃%d%%\nPSNR=%.2f dB', discard_ratios(i), psnr_dwt(i)), 'FontSize', 10);
end
sgtitle('DWT 变换：不同丢弃比例下的重建图像对比', 'FontSize', 14);

% 显示PSNR对比曲线
figure(10);
plot(discard_ratios, psnr_fft, 'r-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r'); hold on;
plot(discard_ratios, psnr_dct, 'g-s', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(discard_ratios, psnr_dwt, 'b-^', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
grid on;
xlabel('高频成分丢弃比例 (%)', 'FontSize', 12);
ylabel('PSNR (dB)', 'FontSize', 12);
title('三种变换压缩性能对比曲线', 'FontSize', 14);
legend('FFT', 'DCT', 'DWT', 'Location', 'southwest');
set(gca, 'FontSize', 11);

% FFT压缩函数
function [img_recon, psnr_val] = fft_compress(I, keep_ratio)
    % FFT 变换，将零频移到中心
    fa = fft2(I);
    ffa = fftshift(fa);
    % 获取频谱尺寸
    [M, N] = size(ffa);
    % 计算保留的像素数量
    total_pixels = M * N;
    keep_pixels = round(total_pixels * keep_ratio);
    % 创建圆形掩膜，保留低频
    [X, Y] = meshgrid(1:N, 1:M);
    center_x = (N+1)/2;
    center_y = (M+1)/2;
    radius = sqrt((X - center_x).^2 + (Y - center_y).^2);
    radius_sorted = sort(radius(:));
    threshold_radius = radius_sorted(keep_pixels);
    mask = radius <= threshold_radius;
    % 应用掩膜，丢弃高频
    ffa_compressed = ffa .* mask;
    % 逆变换
    fa_recon = ifftshift(ffa_compressed);
    img_recon = real(ifft2(fa_recon));
    % 归一化
    img_min = min(img_recon(:));
    img_max = max(img_recon(:));
    if img_max > img_min
        img_gray = (img_recon - img_min) / (img_max - img_min);
    else
        img_gray = img_recon;
    end
    % 计算PSNR
    psnr_val = psnr_calc(I, img_gray);
    % 二值化
    img_recon = img_gray > 0.5;
end

% DCT压缩函数
function [img_recon, psnr_val] = dct_compress(I, keep_ratio)
    % DCT 变换
    c = dct2(I);
    % 获取DCT系数尺寸
    [M, N] = size(c);
    % 计算保留的系数数量
    total_coeffs = M * N;
    keep_coeffs = round(total_coeffs * keep_ratio);
    % 使用 Zigzag 扫描保留低频系数
    zigzag_idx = zigzag_order_full(M, N);
    coeffs_1d = c(zigzag_idx);
    coeffs_1d(keep_coeffs+1:end) = 0;
    c_compressed = zeros(size(c));
    c_compressed(zigzag_idx) = coeffs_1d;
    % 逆 DCT 变换
    img_recon = idct2(c_compressed);
    % 归一化
    img_min = min(img_recon(:));
    img_max = max(img_recon(:));
    if img_max > img_min
        img_gray = (img_recon - img_min) / (img_max - img_min);
    else
        img_gray = img_recon;
    end
    % 计算PSNR
    psnr_val = psnr_calc(I, img_gray);
    % 二值化
    img_recon = img_gray > 0.5;
end

% DWT压缩函数
function [img_recon, psnr_val] = dwt_compress(I, keep_ratio)
    % 一级小波
    [ca1, ch1, cv1, cd1] = dwt2(I, 'db4');
    % 二级小波
    [ca2, ch2, cv2, cd2] = dwt2(ca1, 'db4');
    % 所有系数拼接
    coeffs = [ca2(:); ch2(:); cv2(:); cd2(:); ch1(:); cv1(:); cd1(:)];
    total_coeffs = length(coeffs);
    keep_coeffs = round(total_coeffs * keep_ratio);
    % 各子带长度
    len_ca2 = numel(ca2);
    len_ch2 = numel(ch2);
    len_cv2 = numel(cv2);
    len_cd2 = numel(cd2);
    len_ch1 = numel(ch1);
    len_cv1 = numel(cv1);
    len_cd1 = numel(cd1);
    % 初始化
    coeffs_compressed = zeros(size(coeffs));
    % 优先保留最低频 LL2
    ca2_keep = min(len_ca2, keep_coeffs);
    coeffs_compressed(1:ca2_keep) = ca2(1:ca2_keep);
    remaining = keep_coeffs - ca2_keep;
    % 高频按能量排序
    if remaining > 0
        high_coeffs = [ch2(:); cv2(:); cd2(:); ch1(:); cv1(:); cd1(:)];
        [~, idx_high] = sort(abs(high_coeffs), 'descend');
        high_keep = min(length(high_coeffs), remaining);
        coeffs_compressed(len_ca2 + idx_high(1:high_keep)) = ...
            high_coeffs(idx_high(1:high_keep));
    end
    % 重新拆分系数
    p = 0;
    ca2_compressed = reshape(coeffs_compressed(p+1:p+len_ca2), size(ca2));
    p = p + len_ca2;
    ch2_compressed = reshape(coeffs_compressed(p+1:p+len_ch2), size(ch2));
    p = p + len_ch2;
    cv2_compressed = reshape(coeffs_compressed(p+1:p+len_cv2), size(cv2));
    p = p + len_cv2;
    cd2_compressed = reshape(coeffs_compressed(p+1:p+len_cd2), size(cd2));
    p = p + len_cd2;
    ch1_compressed = reshape(coeffs_compressed(p+1:p+len_ch1), size(ch1));
    p = p + len_ch1;
    cv1_compressed = reshape(coeffs_compressed(p+1:p+len_cv1), size(cv1));
    p = p + len_cv1;
    cd1_compressed = reshape(coeffs_compressed(p+1:p+len_cd1), size(cd1));
    % 先重建一级LL
    ca1_recon = idwt2(ca2_compressed, ch2_compressed, cv2_compressed, cd2_compressed, 'db4');
    ca1_recon = ca1_recon(1:size(ch1,1), 1:size(ch1,2));
    % 再重建原图
    img_recon = idwt2(ca1_recon, ch1_compressed, cv1_compressed, cd1_compressed, 'db4');
    % 裁剪尺寸
    img_recon = img_recon(1:size(I,1), 1:size(I,2));
    % 归一化
    img_min = min(img_recon(:));
    img_max = max(img_recon(:));
    if img_max > img_min
        img_gray = (img_recon - img_min) / (img_max - img_min);
    else
        img_gray = img_recon;
    end
    % 计算PSNR
    psnr_val = psnr_calc(I, img_gray);
    % 二值化
    img_recon = img_gray > 0.5;
end

% PSNR 计算函数
function psnr_val = psnr_calc(img_orig, img_recon)
    % 计算峰值信噪比
    mse = mean((img_orig(:) - img_recon(:)).^2);
    if mse == 0
        psnr_val = 100;
    else
        psnr_val = 20 * log10(1.0 / sqrt(mse));
    end
end

% Zigzag 扫描顺序函数
function idx = zigzag_order_full(M, N)
    % 生成 M x N 矩阵的 Zigzag 扫描索引
    idx = zeros(M*N, 1);
    count = 1;
    
    for sum_val = 0:(M+N-2)
        if mod(sum_val, 2) == 0
            % 从下往上扫描
            for i = min(sum_val, M-1):-1:max(0, sum_val-(N-1))
                j = sum_val - i;
                idx(count) = sub2ind([M, N], i+1, j+1);
                count = count + 1;
            end
        else
            % 从上往下扫描
            for j = min(sum_val, N-1):-1:max(0, sum_val-(M-1))
                i = sum_val - j;
                idx(count) = sub2ind([M, N], i+1, j+1);
                count = count + 1;
            end
        end
    end
end