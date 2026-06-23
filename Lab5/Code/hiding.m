clc; clear; close all;

% 参数设置
SECRET_MSG  = 'Hello TOM';          
AUDIO_FILE  = '../Video/test.mp3';         
OUTPUT_FILE = '../Video/stego_audio.mp3';   

% 回声参数
d0 = 100;          
d1 = 200;         
alpha = 0.5;      
segment_len = 8192;

fprintf('=== 回声信息隐藏系统 ===\n');
fprintf('待隐藏消息: %s\n', SECRET_MSG);

% 读取音频 
[audio, fs] = audioread(AUDIO_FILE);
audio = double(audio);

% 若为立体声，取左声道
if size(audio, 2) > 1
    audio = audio(:, 1);
end

% 消息转换为比特流
bits = text_to_bits(SECRET_MSG);
fprintf('消息比特数: %d\n', length(bits));

% 验证音频是否足够长
required_len = length(bits) * segment_len;
if length(audio) < required_len
    error('音频太短！需要 %d 样本，实际 %d 样本', required_len, length(audio));
end

% AI自适应延迟选择，使用局部能量分析自适应选择回声参数，提高不可感知性
fprintf('\n正在进行AI自适应参数优化...\n');
[d0_adapt, d1_adapt, alpha_adapt] = adaptive_echo_params(audio, bits, segment_len, d0, d1, alpha);

% 嵌入回声
fprintf('正在嵌入回声...\n');
stego_audio = embed_echo(audio, bits, segment_len, d0_adapt, d1_adapt, alpha_adapt);

% 保存隐写音频，归一化防止截幅
max_val = max(abs(stego_audio));
if max_val > 1
    stego_audio = stego_audio / max_val * 0.99;
end
audiowrite(OUTPUT_FILE, stego_audio, fs);
fprintf('隐写音频已保存: %s\n', OUTPUT_FILE);

% 提取验证 
fprintf('\n正在提取隐藏消息...\n');
[stego_back, fs2] = audioread(OUTPUT_FILE);
stego_back = double(stego_back(:,1));

extracted_bits = extract_echo(stego_back, length(bits), segment_len, d0_adapt, d1_adapt);
extracted_msg  = bits_to_text(extracted_bits);

fprintf('提取的消息: %s\n', extracted_msg);
if strcmp(extracted_msg, SECRET_MSG)
    fprintf('✓ 消息提取成功，与原始消息完全一致！\n');
else
    fprintf('✗ 消息提取有误，请调整参数。\n');
end

% 质量评估
N = min(length(audio), length(stego_audio));
snr_val = compute_snr(audio(1:N), stego_audio(1:N));
fprintf('\n音频质量评估:\n');
fprintf('  SNR: %.2f dB\n', snr_val);

% 可视化
plot_results(audio, stego_audio, bits, extracted_bits, fs, SECRET_MSG, extracted_msg);

fprintf('\n=== 完成 ===\n');


% 辅助函数

function bits = text_to_bits(text)
    % 文本转比特流（UTF-8, 每字符8位）
    bytes = uint8(text);
    bits  = [];
    for b = bytes
        for k = 7:-1:0
            bits(end+1) = bitand(bitshift(b, -k), 1); 
        end
    end
end

function text = bits_to_text(bits)
    % 比特流转文本
    text = '';
    n = floor(length(bits)/8)*8;
    for i = 1:8:n
        byte = 0;
        for k = 0:7
            byte = byte + bits(i+k) * 2^(7-k);
        end
        text(end+1) = char(byte); 
    end
end

% 根据各段局部能量调整回声参数，低能量段使用较小衰减，高能量段使用较大衰减
function [d0a, d1a, aa] = adaptive_echo_params(audio, bits, seg_len, d0, d1, alpha)

    num_bits = length(bits);
    energies = zeros(1, num_bits);
    for i = 1:num_bits
        seg = audio((i-1)*seg_len+1 : i*seg_len);
        energies(i) = mean(seg.^2);
    end
    
    % 归一化能量
    e_norm = energies / (max(energies) + 1e-10);
    
    % 自适应衰减系数：能量高时alpha小，能量低时alpha稍大
    alpha_vec = alpha * (0.6 + 0.4 * e_norm);
    
    % 本实现返回全局均值
    d0a = d0;
    d1a = d1;
    aa  = mean(alpha_vec);
    fprintf('  自适应alpha: %.4f（原始: %.4f）\n', aa, alpha);
end

% 回声嵌入：对每段音频叠加对应延迟的回声
function stego = embed_echo(audio, bits, seg_len, d0, d1, alpha)
    
    stego = audio;
    num_bits = length(bits);
    
    for i = 1:num_bits
        s_idx = (i-1)*seg_len + 1;
        e_idx = min(i*seg_len, length(audio));
        seg = audio(s_idx:e_idx);
        
        % 选择延迟
        if bits(i) == 0
            delay = d0;
        else
            delay = d1;
        end
        
        % 生成回声段
        echo_seg = zeros(size(seg));
        for j = delay+1:length(seg)
            echo_seg(j) = alpha * seg(j - delay);
        end
        
        stego(s_idx:e_idx) = seg + echo_seg;
    end
end

% 回声提取：使用倒谱检测回声延迟峰值
function bits = extract_echo(stego, num_bits, seg_len, d0, d1)
    
    bits = zeros(1, num_bits);
    
    for i = 1:num_bits
        s_idx = (i-1)*seg_len + 1;
        e_idx = min(i*seg_len, length(stego));
        seg = stego(s_idx:e_idx);
        
        % 计算实倒谱
        N   = length(seg);
        X   = fft(seg, N);
        log_X = log(abs(X).^2 + 1e-10);
        ceps = real(ifft(log_X));
        
        % 比较d0和d1处的倒谱幅度
        c0 = abs(ceps(d0+1));
        c1 = abs(ceps(d1+1));
        
        bits(i) = c1 > c0;
    end
end

function snr = compute_snr(original, stego)
    noise = stego - original;
    snr = 10 * log10(sum(original.^2) / (sum(noise.^2) + 1e-10));
end

function plot_results(audio, stego, bits, ext_bits, fs, orig_msg, ext_msg)
    t = (0:length(audio)-1) / fs;
    ts = (0:length(stego)-1) / fs;
    
    figure('Name','回声信息隐藏结果','Position',[100 100 1200 800]);
    
    % 原始波形
    subplot(3,2,1);
    plot(t, audio, 'b', 'LineWidth', 0.5);
    title('原始音频波形'); xlabel('时间(s)'); ylabel('幅度');
    grid on;
    
    % 隐写波形
    subplot(3,2,2);
    plot(ts, stego, 'r', 'LineWidth', 0.5);
    title('隐写音频波形'); xlabel('时间(s)'); ylabel('幅度');
    grid on;
    
    % 差异波形
    subplot(3,2,3);
    N = min(length(audio), length(stego));
    plot((0:N-1)/fs, stego(1:N)-audio(1:N), 'g', 'LineWidth', 0.5);
    title('差异信号（回声噪声）'); xlabel('时间(s)'); ylabel('幅度');
    grid on;
    
    % 频谱对比
    subplot(3,2,4);
    NFFT = 2048;
    f = (0:NFFT/2) * fs / NFFT;
    A_orig  = abs(fft(audio(1:min(NFFT,end)), NFFT));
    A_stego = abs(fft(stego(1:min(NFFT,end)), NFFT));
    plot(f, 20*log10(A_orig(1:NFFT/2+1)+1e-10), 'b'); hold on;
    plot(f, 20*log10(A_stego(1:NFFT/2+1)+1e-10), 'r--');
    legend('原始','隐写'); title('频谱对比');
    xlabel('频率(Hz)'); ylabel('幅度(dB)'); grid on;
end