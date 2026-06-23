clc; clear; close all;

% 参数配置
BLOCK_SIZE = 8;

% 按Zigzag顺序取前28个中低频系数
COEF_POS = [
    1,2;  2,1;
    1,3;  2,2;  3,1;
    1,4;  2,3;  3,2;  4,1;
    1,5;  2,4;  3,3;  4,2;  5,1;
    1,6;  2,5;  3,4;  4,3;  5,2;  6,1;
    1,7;  2,6;  3,5;  4,4;  5,3;  6,2;  7,1;
    1,8;
];

n_coef_total = size(COEF_POS, 1);
fprintf('使用 %d 个系数位置（Zigzag中低频）\n', n_coef_total);
Q = 8;       % QIM量化步长

% 载入载体图像
cover_rgb = imread('Picture\1.bmp');
if size(cover_rgb, 3) == 3
    cover_gray = rgb2gray(cover_rgb);
else
    cover_gray = cover_rgb;
end

% 裁剪为 BLOCK_SIZE 的整数倍
[H, W] = size(cover_gray);
H = floor(H / BLOCK_SIZE) * BLOCK_SIZE;
W = floor(W / BLOCK_SIZE) * BLOCK_SIZE;
cover_gray = cover_gray(1:H, 1:W);

fprintf('====== DCT-QIM 图像隐写 ======\n');
fprintf('载体图像尺寸: %d x %d\n', H, W);

% 准备秘密图像
secret_img = imread('Picture\2.bmp');
if size(secret_img, 3) == 3
    secret_gray = rgb2gray(secret_img);
else
    secret_gray = secret_img;
end

[secret_h, secret_w] = size(secret_gray);

fprintf('秘密图像尺寸: %d x %d\n', secret_h, secret_w);

% 将秘密图像转换为比特流
secret_bits = img2bits(secret_gray);
msg_len = length(secret_bits);

% 构造32位高度头 + 32位宽度头 + 秘密比特
height_bits = bitget(uint32(secret_h), 32:-1:1);
width_bits = bitget(uint32(secret_w), 32:-1:1);
payload = [height_bits, width_bits, secret_bits];

fprintf('秘密图像比特数: %d bits\n', msg_len);
fprintf('含头的总载荷: %d bits\n\n', length(payload));

% 嵌入
fprintf('--- 开始嵌入 (Q=%d) ---\n', Q);
stego_img = dct_qim_embed(cover_gray, payload, BLOCK_SIZE, COEF_POS, Q);

% 图像质量评估
cover_d = double(cover_gray);
stego_d = double(stego_img);
mse = mean((cover_d(:) - stego_d(:)).^2);
if mse < 1e-10
    psnr_val = Inf;
    fprintf('\n警告: PSNR=Inf，系数未被修改！请增大Q值或换用其他系数位置。\n');
else
    psnr_val = 10 * log10(255^2 / mse);
end
try
    ssim_val = ssim(stego_img, cover_gray);
catch
    ssim_val = NaN;
end

fprintf('\n====== 图像质量评估 ======\n');
fprintf('MSE : %.4f\n', mse);
if isinf(psnr_val)
    fprintf('PSNR: Inf dB\n');
else
    fprintf('PSNR: %.2f dB\n', psnr_val);
end
if ~isnan(ssim_val)
    fprintf('SSIM: %.6f\n', ssim_val);
end

% 提取
fprintf('\n--- 开始提取 ---\n');
extracted_all = dct_qim_extract(stego_img, length(payload), BLOCK_SIZE, COEF_POS, Q);

% 解析32位高度头
height_u32 = uint32(0);
for i = 1:32
    height_u32 = bitor(bitshift(height_u32, 1), uint32(extracted_all(i)));
end
extracted_h = double(height_u32);

% 解析32位宽度头
width_u32 = uint32(0);
for i = 33:64
    width_u32 = bitor(bitshift(width_u32, 1), uint32(extracted_all(i)));
end
extracted_w = double(width_u32);

fprintf('解析到的秘密图像尺寸: %d x %d\n', extracted_h, extracted_w);

% 安全检查
max_extractable = length(extracted_all) - 64;
expected_bits = extracted_h * extracted_w * 8;
if expected_bits < 1 || expected_bits > max_extractable
    error(['尺寸头解析异常! 预期比特数=%d，最大可提取=%d bits'], expected_bits, max_extractable);
end

% 提取秘密比特
msg_bits_ex = extracted_all(65 : 64 + expected_bits);

% 将比特流还原为图像
extracted_img = bits2img(msg_bits_ex, extracted_h, extracted_w);

% 计算提取图像与原始秘密图像的PSNR
secret_double = double(secret_gray);
extracted_double = double(extracted_img);
mse_secret = mean((secret_double(:) - extracted_double(:)).^2);
psnr_secret = 10 * log10(255^2 / mse_secret);

fprintf('\n====== 提取结果 ======\n');
fprintf('提取图像与原始秘密图像PSNR: %.2f dB\n', psnr_secret);
if psnr_secret > 30
    fprintf('✓ 图像提取成功!\n');
else
    fprintf('✗ 图像质量较差（尝试增大Q值）\n');
end

% 可视化
figure('Name','DCT-QIM图像隐写','NumberTitle','off','Position',[80,80,1200,700]);

subplot(2,3,1); imshow(cover_gray);
title('载体图像 Cover','FontSize',12);
xlabel(sprintf('%dx%d',W,H));

subplot(2,3,2); imshow(stego_img);
if isinf(psnr_val)
    title('含密图像 Stego  PSNR=Inf','FontSize',12);
else
    title(sprintf('含密图像 Stego\nPSNR=%.2f dB',psnr_val),'FontSize',12);
end

diff_img = abs(cover_d - stego_d);
subplot(2,3,3); imshow(diff_img*10,[]); colormap(gca,hot);
title(sprintf('差值×10  (max diff=%d)',round(max(diff_img(:)))),'FontSize',12);

subplot(2,3,4); imshow(secret_gray);
title('原始秘密图像','FontSize',12);
xlabel(sprintf('%dx%d',secret_w,secret_h));

subplot(2,3,5); imshow(extracted_img);
title(sprintf('提取的秘密图像\nPSNR=%.2f dB',psnr_secret),'FontSize',12);

% 保存
imwrite(stego_img, 'Picture/stego_output.bmp');
imwrite(extracted_img, 'Picture/extracted_secret.bmp');
fprintf('\n含密图像已保存: Picture/stego_output.bmp\n');
fprintf('提取的秘密图像已保存: Picture/extracted_secret.bmp\n');

% 将图像转换为二进制序列
function bits = img2bits(img)
    img_uint8 = uint8(img);
    [h, w] = size(img_uint8);
    bits = zeros(1, h * w * 8, 'uint8');
    bit_idx = 1;
    
    for i = 1:h
        for j = 1:w
            pixel_bits = bitget(img_uint8(i, j), 8:-1:1);
            bits(bit_idx:bit_idx+7) = pixel_bits;
            bit_idx = bit_idx + 8;
        end
    end
end

% 将二进制序列还原为图像
function img = bits2img(bits, h, w)
    img = zeros(h, w, 'uint8');
    bit_idx = 1;
    
    for i = 1:h
        for j = 1:w
            byte_val = uint8(0);
            for b = 1:8
                byte_val = bitor(bitshift(byte_val, 1), uint8(bits(bit_idx)));
                bit_idx = bit_idx + 1;
            end
            img(i, j) = byte_val;
        end
    end
end

% 嵌入函数：QIM调制
function stego_img = dct_qim_embed(cover_img, secret_bits, block_size, coef_pos, Q)
cover_img = double(cover_img);
[H, W]    = size(cover_img);
nbh = floor(H / block_size);
nbw = floor(W / block_size);
n_coef = size(coef_pos, 1);  % 系数位置数量
max_bits = nbh * nbw * n_coef;  % 总容量 = 块数 × 每块系数数

fprintf('图像尺寸: %d x %d  |  分块: %dx%d = %d块\n', H, W, nbh, nbw, nbh*nbw);
fprintf('每块嵌入: %d bits | 总容量: %d bits | 待嵌入: %d bits\n', n_coef, max_bits, length(secret_bits));
if length(secret_bits) > max_bits
    error('秘密信息过长! 最大 %d bits', max_bits);
end

stego = cover_img;
bit_idx = 1;
n_bits  = length(secret_bits);

for bh = 1:nbh
    for bw = 1:nbw
        rs = (bh-1)*block_size+1;  cs = (bw-1)*block_size+1;
        block = stego(rs:rs+block_size-1, cs:cs+block_size-1);
        D = dct2(block);
        
        % 在当前块中嵌入多个比特（使用多个系数位置）
        for coef_idx = 1:n_coef
            if bit_idx > n_bits, break; end
            
            r = coef_pos(coef_idx, 1);
            c = coef_pos(coef_idx, 2);
            
            idx = round(D(r,c) / Q);    % 量化索引
            bit = double(secret_bits(bit_idx));
            
            if bit == 0
                if mod(idx,2) ~= 0, idx = idx + 1; end   % 偶数索引 → bit=0
            else
                if mod(idx,2) == 0, idx = idx + 1; end   % 奇数索引 → bit=1
            end
            D(r,c) = idx * Q;           % 反量化写回
            bit_idx = bit_idx + 1;
        end
        
        stego(rs:rs+block_size-1, cs:cs+block_size-1) = idct2(D);
        if bit_idx > n_bits, break; end
    end
    if bit_idx > n_bits, break; end
end

stego_img = uint8(max(0, min(255, round(stego))));
fprintf('嵌入完成! 共嵌入 %d bits\n', n_bits);
end

% 提取函数：QIM解调
function secret_bits = dct_qim_extract(stego_img, num_bits, block_size, coef_pos, Q)
stego_img = double(stego_img);
[H, W]    = size(stego_img);
nbh = floor(H / block_size);
nbw = floor(W / block_size);
n_coef = size(coef_pos, 1);  % 系数位置数量

secret_bits = zeros(1, num_bits, 'uint8');
bit_idx = 1;

for bh = 1:nbh
    for bw = 1:nbw
        rs = (bh-1)*block_size+1;  cs = (bw-1)*block_size+1;
        block = stego_img(rs:rs+block_size-1, cs:cs+block_size-1);
        D = dct2(block);
        
        % 从当前块中提取多个比特
        for coef_idx = 1:n_coef
            if bit_idx > num_bits, break; end
            
            r = coef_pos(coef_idx, 1);
            c = coef_pos(coef_idx, 2);
            
            idx = round(D(r,c) / Q);           % 量化索引
            secret_bits(bit_idx) = uint8(mod(abs(idx), 2));  % 奇偶 → bit
            bit_idx = bit_idx + 1;
        end
        if bit_idx > num_bits, break; end
    end
    if bit_idx > num_bits, break; end
end

fprintf('提取完成! 共提取 %d bits\n', num_bits);
end