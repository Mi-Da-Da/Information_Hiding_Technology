% FFT变换处理函数
function [x_reconstructed, snr_val] = fft_analysis(x, ratio)
    X = fft(x);
    N = length(X);
    keep_count = floor(N * (1 - ratio));
    half_keep = floor( keep_count / 2);
    % 保留低频，去除高频
    X_filtered = X;
    X_filtered(half_keep+1:N-half_keep) = 0;
    % 逆变换
    x_reconstructed = real(ifft(X_filtered));
    % 计算SNR
    snr_val = snr(x, x - x_reconstructed);
end

% DWT变换处理函数
function [x_reconstructed, snr_val] = dwt_analysis(x, ratio)
    [c, l] = wavedec(x, 3, 'db4');
    % 按系数大小排序，去除小系数
    sorted_c = sort(abs(c), 'descend');
    threshold_idx = floor(length(c) * (1 - ratio));
    threshold = sorted_c(threshold_idx);
    % 阈值处理
    c_filtered = c;
    c_filtered(abs(c) < threshold) = 0;
    % 逆变换
    x_reconstructed = waverec(c_filtered, l, 'db4');
    % 计算SNR
    snr_val = snr(x, x - x_reconstructed);
end

% DCT变换处理函数
function [x_reconstructed, snr_val] = dct_analysis(x, ratio)
    Xdct = dct(x);
    N = length(Xdct);
    keep_count = floor(N * (1 - ratio));
    % 保留低频，去除高频
    Xdct_filtered = Xdct;
    Xdct_filtered(keep_count+1:end) = 0;

    x_reconstructed = idct(Xdct_filtered);
    snr_val = snr(x, x - x_reconstructed);
end

filename = 'test.mp3';
if exist(filename, 'file')
    [x, fs] = audioread(filename);
    x = mean(x, 2);  % 转单声道
    % 使用音频的前10秒
    target_samples = 10 * fs;
    if length(x) > target_samples
        start_idx = floor((length(x) - target_samples) / 2);
        x = x(start_idx+1:start_idx+target_samples);
    else
        x = [x; zeros(target_samples-length(x), 1)];
    end
    t = (0:length(x)-1)/fs;
end

% 定义去除比例
removal_ratios = [0.15, 0.30, 0.50, 0.80];
ratio_names = {'15%', '30%', '50%', '80%'};
ratio_percent = removal_ratios * 100;

% 初始化存储
snr_fft = zeros(size(removal_ratios));
snr_dwt = zeros(size(removal_ratios));
snr_dct = zeros(size(removal_ratios));

x_fft_all = cell(length(removal_ratios), 1);
x_dwt_all = cell(length(removal_ratios), 1);
x_dct_all = cell(length(removal_ratios), 1);

% 获取三种变换后的数据
for i = 1:length(removal_ratios)
    ratio = removal_ratios(i);
    [x_fft_all{i}, snr_fft(i)] = fft_analysis(x, ratio);
    [x_dwt_all{i}, snr_dwt(i)] = dwt_analysis(x, ratio);
    [x_dct_all{i}, snr_dct(i)] = dct_analysis(x, ratio);
end

% 波形图展示5秒的内容
display_duration = min(5, length(x)/fs);
display_samples = round(display_duration * fs);

% 图表展示
fig = figure('Name', '信号变换分析', 'Position', [100, 100, 1400, 900]);
tabgroup = uitabgroup('Parent', fig);

tab1 = uitab('Parent', tabgroup, 'Title', 'SNR对比');
ax1 = axes('Parent', tab1, 'Position', [0.1, 0.1, 0.8, 0.8]);

plot(ax1, ratio_percent, snr_fft, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold(ax1, 'on');
plot(ax1, ratio_percent, snr_dwt, 'g-s', 'LineWidth', 2, 'MarkerSize', 8);
plot(ax1, ratio_percent, snr_dct, 'r-^', 'LineWidth', 2, 'MarkerSize', 8);
hold(ax1, 'off');

grid(ax1, 'on');
xlabel(ax1, '去除比例 (%)', 'FontSize', 12);
ylabel(ax1, 'SNR (dB)', 'FontSize', 12);
title(ax1, 'FFT、DWT、DCT变换去除高频成分后的SNR对比', 'FontSize', 14);
legend(ax1, 'FFT', 'DWT', 'DCT', 'Location', 'best');
set(ax1, 'FontSize', 11);

for i = 1:length(ratio_percent)
    text(ax1, ratio_percent(i), snr_fft(i)+0.5, sprintf('%.1f', snr_fft(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
    text(ax1, ratio_percent(i), snr_dwt(i)+0.5, sprintf('%.1f', snr_dwt(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
    text(ax1, ratio_percent(i), snr_dct(i)+0.5, sprintf('%.1f', snr_dct(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end

% 三种变换后重建信号的波形图与原始图像对比
tab2 = uitab('Parent', tabgroup, 'Title', 'FFT信号对比');

subplot(5, 1, 1, 'Parent', tab2);
plot(t(1:display_samples), x(1:display_samples), 'b-', 'LineWidth', 1);
title('原始音频信号 (前5秒)', 'FontSize', 12);
ylabel('幅值', 'FontSize', 10);
grid on;
xlim([0, display_duration]);

% 显示不同去除比例的重建信号
for i = 1:length(removal_ratios)
    subplot(5, 1, i+1, 'Parent', tab2);
    plot(t(1:display_samples), x_fft_all{i}(1:display_samples), 'r-', 'LineWidth', 1);
    title(sprintf('FFT重建信号 - 去除 %s 高频成分 (SNR: %.2f dB)', ratio_names{i}, snr_fft(i)), 'FontSize', 10);
    ylabel('幅值', 'FontSize', 10);
    grid on;
    xlim([0, display_duration]);
    if i == length(removal_ratios)
        xlabel('时间 (s)', 'FontSize', 10);
    end
end

tab3 = uitab('Parent', tabgroup, 'Title', 'DWT信号对比');

subplot(5, 1, 1, 'Parent', tab3);
plot(t(1:display_samples), x(1:display_samples), 'b-', 'LineWidth', 1);
title('原始音频信号 (前5秒)', 'FontSize', 12);
ylabel('幅值', 'FontSize', 10);
grid on;
xlim([0, display_duration]);

for i = 1:length(removal_ratios)
    subplot(5, 1, i+1, 'Parent', tab3);
    plot(t(1:display_samples), x_dwt_all{i}(1:display_samples), 'r-', 'LineWidth', 1);
    title(sprintf(['DWT重建信号 - 去除 %s 高频成分' ...
        ' (SNR: %.2f dB)'], ratio_names{i}, snr_dwt(i)), 'FontSize', 10);
    ylabel('幅值', 'FontSize', 10);
    grid on;
    xlim([0, display_duration]);
    if i == length(removal_ratios)
        xlabel('时间 (s)', 'FontSize', 10);
    end
end

tab4 = uitab('Parent', tabgroup, 'Title', 'DCT信号对比');

subplot(5, 1, 1, 'Parent', tab4);
plot(t(1:display_samples), x(1:display_samples), 'b-', 'LineWidth', 1);
title('原始音频信号 (前5秒)', 'FontSize', 12);
ylabel('幅值', 'FontSize', 10);
grid on;
xlim([0, display_duration]);

for i = 1:length(removal_ratios)
    subplot(5, 1, i+1, 'Parent', tab4);
    plot(t(1:display_samples), x_dct_all{i}(1:display_samples), 'r-', 'LineWidth', 1);
    title(sprintf('DCT重建信号 - 去除 %s 高频成分 (SNR: %.2f dB)', ratio_names{i}, snr_dct(i)), 'FontSize', 10);
    ylabel('幅值', 'FontSize', 10);
    grid on;
    xlim([0, display_duration]);
    if i == length(removal_ratios)
        xlabel('时间 (s)', 'FontSize', 10);
    end
end