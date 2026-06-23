clc;
clear;
% 输入参数
input_image = '../Picture/1.bmp';
output_image = '../Picture/stego_image.bmp';
position_file = '../Picture/positions.mat';  % 保存位置信息
secret_message = '这是一条秘密信息！Hello World!';
secret_key = 2026;

% 隐藏信息
hide_message(input_image, secret_message, output_image, secret_key, position_file);
% 提取信息
extracted = extract_message(output_image, position_file);

fprintf('原始信息: %s\n', secret_message);
fprintf('提取信息: %s\n', extracted);
if strcmp(secret_message, extracted)
    fprintf('✓ 验证成功：信息完全一致\n');
else
    fprintf('✗ 验证失败\n');
end

% 信息隐藏函数
function hide_message(input_image, secret_message, output_image, secret_key, position_file)
    img = imread(input_image);
    [h, w, c] = size(img);
    
    % 将字符串转为UTF8字节，兼容中文
    message_bytes = unicode2native(secret_message, 'UTF-8');
    message_length = length(message_bytes);
    length_bits = dec2bin(message_length, 32) - '0';
    message_bits = reshape(dec2bin(message_bytes, 8).' - '0', 1, []);
    data_bits = [length_bits message_bits];
    
    % 图像容量
    capacity = h * w * c;
    if length(data_bits) > capacity
        error('图像容量不足');
    end
    
    % 转为一维
    img_vec = img(:);
    total_pixels = length(img_vec);
    
    % 使用密钥生成随机位置
    rng(secret_key);
    all_positions = randperm(total_pixels);
    positions = all_positions(1:length(data_bits));
    
    % 保存位置信息
    save(position_file, 'positions');
    
    % LSB嵌入到随机位置
    for i = 1:length(data_bits)
        img_vec(positions(i)) = bitset(img_vec(positions(i)), 1, data_bits(i));
    end
    
    % 恢复图像
    stego_img = reshape(img_vec, h, w, c);
    imwrite(stego_img, output_image);
    
    % 计算PSNR
    [mse, psnr] = calculate_psnr(img, stego_img);
    fprintf('隐写完成\n');
    fprintf('PSNR: %.2f dB\n', psnr);
end

% 信息提取函数
function message = extract_message(stego_image, position_file)
    fprintf('开始提取信息...\n');
    
    % 加载位置信息
    load(position_file, 'positions');
    
    img = imread(stego_image);
    img_vec = img(:);
    
    % 读取32bit长度
    length_bits = zeros(1, 32);
    for i = 1:32
        length_bits(i) = bitget(img_vec(positions(i)), 1);
    end
    message_length = bin2dec(char(length_bits + '0'));
    
    % 读取消息bit
    total_bits = message_length * 8;
    message_bits = zeros(1, total_bits);
    for i = 1:total_bits
        message_bits(i) = bitget(img_vec(positions(i+32)), 1);
    end
    
    % 将bit转换为byte
    message_bytes = zeros(1, message_length);
    for i = 1:message_length
        start_idx = (i-1) * 8 + 1;
        end_idx = i * 8;
        byte = message_bits(start_idx:end_idx);
        message_bytes(i) = bin2dec(char(byte + '0'));
    end
    
    % 将UTF8转换为字符串
    message = native2unicode(uint8(message_bytes), 'UTF-8');
    fprintf('提取完成\n');
end

% PSNR计算
function [mse, psnr] = calculate_psnr(original, stego)
    original = double(original);
    stego = double(stego);
    mse = mean((original(:) - stego(:)).^2);
    if mse == 0
        psnr = Inf;
    else
        psnr = 10 * log10(255^2 / mse);
    end
end