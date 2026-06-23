% 本图片背景存在大量纯黑区域。在这些区域嵌入信息后，通过逆变换重构回像素值时，若结果为负数，会被强制截断为 0
% 这种数值截断会导致提取时 DWT 系数漂移回原始状态，从而造成严重的提取错误
% 故将 start_idx 移至 10000，将信息嵌入到图像中部纹理丰富的区域
clc; clear; close all;
% 1. 读取原图
cover_path = '../Picture/1.bmp';
% 检查文件是否存在
% if ~exist(cover_path, 'file')
%     error('未找到原图，请确保 "独属于我的蒙娜丽莎.png" 在当前目录下。');
% end
% 加载图像数据
img = imread(cover_path);
% 强制去除 Alpha 通道，防止透明度干扰 RGB 像素值
if size(img, 3) == 4
    img = img(:,:,1:3);
end
img_work = img;
B = double(img_work(:,:,3));

% 2. 准备秘密信息
secret_msg = '2313815 段俊宇';
msg_bytes = unicode2native(secret_msg, 'utf-8');
msg_bin_mat = dec2bin(msg_bytes, 8) - '0';
msg_bin = reshape(msg_bin_mat.', 1, []); 
msg_len = length(msg_bin);
len_bin = dec2bin(msg_len, 32) - '0';
watermark = [len_bin, msg_bin];

% 3. 进行一级二维离散小波变换
[cA, cH, cV, cD] = dwt2(B, 'haar');
cH_vec = cH(:);

% 4. 嵌入
delta = 80; 
% 避开背景死区，从图像中部开始嵌入
start_idx = 10000; 

% 遍历待嵌入的二进制位
for i = 1:length(watermark)
    % 计算当前位在分量向量中的索引
    idx = start_idx + i;
    % 获取当前的 DWT 系数值
    c = cH_vec(idx);
    % 获取当前待嵌入的位
    bit = watermark(i);
    % 根据待嵌入位进行量化处理
    if bit == 0
        % 嵌入 0：量化到 delta 的偶数倍
        cH_vec(idx) = round(c / delta) * delta;
    else
        % 嵌入 1：量化到 delta 的奇数倍偏移
        cH_vec(idx) = round((c - delta/2) / delta) * delta + delta/2;
    end
end
cH_emb = reshape(cH_vec, size(cH));

% 5. 逆离散小波变换重构图像通道
B_emb = idwt2(cA, cH_emb, cV, cD, 'haar');
sz = size(B);
% 修正因 DWT 变换可能产生的尺寸偏差
B_emb = B_emb(1:sz(1), 1:sz(2));
B_emb(B_emb < 0) = 0;
B_emb(B_emb > 255) = 255;
img_stego = img_work;
img_stego(:,:,3) = uint8(B_emb);

% 6. 保存含密图像
stego_path = '../Picture/stego_1.bmp';
imwrite(img_stego, stego_path);

% 打印完成提示
disp('============ DWT 隐写嵌入成功 ============');
disp(['秘密信息: ', secret_msg]);
disp(['含密图像已保存为: ', stego_path]);
