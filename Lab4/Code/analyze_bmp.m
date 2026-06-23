% 分析 BMP 文件格式的函数
function analyze_bmp()
    % 读取 BMP 文件
    file_path = '../Picture/1.bmp';
fid = fopen(file_path, 'r');
if fid == -1
    error('无法打开文件');
end

% 读取文件头信息，14字节
file_header = fread(fid, 14, 'uint8=>uint8');

% 解析文件头
bfType = char(file_header(1:2));  % 文件类型
bfSize = typecast(file_header(3:6), 'uint32');  % 文件大小
bfReserved1 = typecast(file_header(7:8), 'uint16');  % 保留字段1
bfReserved2 = typecast(file_header(9:10), 'uint16');  % 保留字段2
bfOffBits = typecast(file_header(11:14), 'uint32');  % 像素数据偏移量

% 读取信息头，40字节
info_header = fread(fid, 40, 'uint8=>uint8');

% 解析信息头
biSize = typecast(info_header(1:4), 'uint32');  % 信息头大小
biWidth = typecast(info_header(5:8), 'int32');  % 图像宽度
biHeight = typecast(info_header(9:12), 'int32');  % 图像高度
biPlanes = typecast(info_header(13:14), 'uint16');  % 色彩平面数
biBitCount = typecast(info_header(15:16), 'uint16');  % 每像素位数
biCompression = typecast(info_header(17:20), 'uint32');  % 压缩类型
biSizeImage = typecast(info_header(21:24), 'uint32');  % 图像大小
biXPelsPerMeter = typecast(info_header(25:28), 'int32');  % 水平分辨率
biYPelsPerMeter = typecast(info_header(29:32), 'int32');  % 垂直分辨率
biClrUsed = typecast(info_header(33:36), 'uint32');  % 使用的颜色数
biClrImportant = typecast(info_header(37:40), 'uint32');  % 重要颜色数

% 关闭文件
fclose(fid);

% 输出结果
fprintf('=== BMP 文件格式分析 ===\n');
fprintf('文件类型: %s\n', bfType);
fprintf('文件大小: %d 字节\n', bfSize);
fprintf('保留字段1: %d\n', bfReserved1);
fprintf('保留字段2: %d\n', bfReserved2);
fprintf('像素数据偏移量: %d 字节\n', bfOffBits);
fprintf('信息头大小: %d 字节\n', biSize);
fprintf('图像宽度: %d 像素\n', biWidth);
fprintf('图像高度: %d 像素\n', biHeight);
fprintf('色彩平面数: %d\n', biPlanes);
fprintf('每像素位数: %d\n', biBitCount);
fprintf('压缩类型: %d\n', biCompression);
fprintf('图像大小: %d 字节\n', biSizeImage);
fprintf('水平分辨率: %d\n', biXPelsPerMeter);
fprintf('垂直分辨率: %d\n', biYPelsPerMeter);
fprintf('使用的颜色数: %d\n', biClrUsed);
fprintf('重要颜色数: %d\n', biClrImportant);

