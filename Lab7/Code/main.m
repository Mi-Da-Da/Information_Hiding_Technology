clear all;
clc;

% 参数设置
secret_image_path = '../Picture/2.bmp';  % 南开校徽二值图
cover_image_path = '../Picture/1.bmp';   % 载体位图
stego_image_path = '../Picture/stego_image.bmp';
extracted_secret_path = '../Picture/extracted_secret.bmp';
decrypted_path = '../Picture/decrypted_logo.bmp';

block_size = 4;  % 区域大小（每个区域隐藏1个比特）

% 读取载体并计算容量
cover_img = imread(cover_image_path);
if size(cover_img, 3) == 3
    cover_gray = rgb2gray(cover_img);
else
    cover_gray = cover_img;
end
[cover_height, cover_width] = size(cover_gray);
max_capacity = floor(cover_height / block_size) * floor(cover_width / block_size);
disp(['载体尺寸: ', num2str(cover_height), 'x', num2str(cover_width)]);
disp(['最大嵌入容量: ', num2str(max_capacity), ' 比特']);

% 读取并缩放秘密图像
secret_img = imread(secret_image_path);
if size(secret_img, 3) == 3
    secret_img = rgb2gray(secret_img);
end

% 根据载体容量计算最大可嵌入的秘密图像尺寸
max_secret_dim = floor(sqrt(max_capacity));
secret_resized = imresize(secret_img, [max_secret_dim, max_secret_dim]);
secret_binary = imbinarize(secret_resized);

[secret_height, secret_width] = size(secret_binary);
actual_bits_needed = secret_height * secret_width;
disp(['秘密图像尺寸: ', num2str(secret_height), 'x', num2str(secret_width)]);
disp(['实际需要嵌入: ', num2str(actual_bits_needed), ' 比特']);

% 加密
rng(42);  
key = randi([0, 1], size(secret_binary));
save('encryption_key.mat', 'key');
encrypted_secret = xor(secret_binary, key);
disp('加密完成');

blocks_per_row = floor(cover_width / block_size);
blocks_per_col = floor(cover_height / block_size);

% 将加密图像展平为比特流
secret_bits = encrypted_secret(:);
num_secret_bits = length(secret_bits);

stego_img = double(cover_gray);

% 嵌入：选择不重叠区域，计算每个区域的奇偶校验位，若奇偶校验位与秘密比特不匹配，则翻转该区域所有元素的最低位
for k = 1:num_secret_bits
    block_idx = k - 1;
    block_row = floor(block_idx / blocks_per_row);
    block_col = mod(block_idx, blocks_per_row);
    
    start_row = block_row * block_size + 1;
    start_col = block_col * block_size + 1;
    
    % 获取当前区域的奇偶校验位
    pixel = stego_img(start_row, start_col);
    current_parity = mod(pixel, 2);
    secret_bit = secret_bits(k);
    
    % 若奇偶性不匹配，翻转最低位
    if current_parity ~= secret_bit
        if pixel < 255
            stego_img(start_row, start_col) = pixel + 1;
        else
            stego_img(start_row, start_col) = pixel - 1;
        end
    end
end

stego_img = uint8(stego_img);
imwrite(stego_img, stego_image_path);
disp('嵌入完成');

% 提取
stego_img_read = imread(stego_image_path);
if size(stego_img_read, 3) == 3
    stego_img_read = rgb2gray(stego_img_read);
end
stego_img_read = double(stego_img_read);

extracted_bits = zeros(num_secret_bits, 1);

% 计算每个区域的奇偶校验位，重构秘密比特流
for k = 1:num_secret_bits
    block_idx = k - 1;
    block_row = floor(block_idx / blocks_per_row);
    block_col = mod(block_idx, blocks_per_row);
    
    start_row = block_row * block_size + 1;
    start_col = block_col * block_size + 1;
    
    pixel = stego_img_read(start_row, start_col);
    extracted_bits(k) = mod(pixel, 2);
end

extracted_secret = reshape(extracted_bits, secret_height, secret_width);
extracted_secret = logical(extracted_secret);
imwrite(extracted_secret, extracted_secret_path);
disp('提取完成');

% 解密
load('encryption_key.mat');
decrypted_secret = xor(extracted_secret, key);
imwrite(decrypted_secret, decrypted_path);
disp('解密完成');

% 显示结果
figure('Name', '奇偶校验位隐藏结果', 'Position', [100, 100, 1200, 600]);

subplot(2,3,1); imshow(secret_binary); title('原始秘密图像（缩放后）');
subplot(2,3,2); imshow(encrypted_secret); title('加密后的秘密图像');
subplot(2,3,3); imshow(cover_gray); title('载体图像');
subplot(2,3,4); imshow(stego_img); title('含密图像');
subplot(2,3,5); imshow(extracted_secret); title('提取的秘密图像');
subplot(2,3,6); imshow(decrypted_secret); title('解密后的校徽');