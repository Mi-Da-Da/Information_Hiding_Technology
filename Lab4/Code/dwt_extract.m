clc; clear; close all;

% 1. 读取含密图像
stego_path = '../Picture/stego_1.bmp';
% if ~exist(stego_path, 'file')
%     error('未找到含密图像，请先运行 dwt_exp.m 生成含密图片。');
% end
img_stego = imread(stego_path);
B_stego = double(img_stego(:,:,3));

% 2. 进行一级二维离散小波变换
[cA, cH, cV, cD] = dwt2(B_stego, 'haar');
% 提取水平细节分量并展平为向量
cH_vec = cH(:);

% 设置量化步长
delta = 80; 
% 设置起始索引
start_idx = 10000; 

% 3. 提取前 32 位长度信息
len_bin = zeros(1, 32);
for i = 1:32
    idx = start_idx + i;
    c = cH_vec(idx);
    d0 = abs(c - round(c / delta) * delta);
    d1 = abs(c - (round((c - delta/2) / delta) * delta + delta/2));
    % 根据欧氏距离最小原则进行位判决
    if d0 < d1
        % 距离 d0 更近，判定为位 0
        len_bin(i) = 0;
    else
        % 距离 d1 更近，判定为位 1
        len_bin(i) = 1;
    end
end

% 将 32 位二进制字符转换为十进制整数，得到消息长度
msg_len = bin2dec(char(len_bin + '0'));

% 进行基本的安全检查，防止解析出非法长度导致崩溃
if msg_len > (length(cH_vec) - start_idx - 32) || msg_len <= 0
    error('提取到的长度信息异常（%d），请检查图片是否正确或已被篡改！', msg_len);
end

% 4. 根据提取出的长度信息，提取秘密数据位
msg_bin = zeros(1, msg_len);
for i = 1:msg_len
    idx = start_idx + 32 + i;
    % 获取当前的 DWT 系数值
    c = cH_vec(idx);
    % 再次使用量化判决逻辑
    d0 = abs(c - round(c / delta) * delta);
    d1 = abs(c - (round((c - delta/2) / delta) * delta + delta/2));
    if d0 < d1
        msg_bin(i) = 0;
    else
        msg_bin(i) = 1;
    end
end

% 5. 将二进制数据还原为原始字符串
msg_bin_mat = reshape(msg_bin, 8, [])';
msg_bytes = bin2dec(char(msg_bin_mat + '0'));

% 将字节流按 UTF-8 编码还原为原始字符
extracted_msg = native2unicode(uint8(msg_bytes)', 'utf-8');

% 打印成功提取的提示和内容
disp('============ DWT 信息提取成功 ============');
% 输出提取出的隐藏秘密信息
disp(['提取出的隐藏信息为: ', extracted_msg]);
