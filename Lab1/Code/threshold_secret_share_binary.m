function sub_images = threshold_secret_share_binary(k, n, image_path)
    % t: 恢复秘密图像所需的最小子图像数
    % n: 生成的子图像总数
    % image_path: 二值秘密图像的文件路径
    % sub_images: 返回值，用于存储所有生成份额的单元格数组
    % 1、处理输入图像：支持路径或矩阵，进行逻辑取反，黑色 1，白色 0
    if ischar(image_path) || isstring(image_path)
        binary_image = imread(image_path) ~= 0; 
    else
        binary_image = logical(image_path);
    end
    binary_image = ~binary_image;
    % 2、获取秘密图像的尺寸，初始化 n 个子图像存储空间
    [height, width] = size(binary_image);
    sub_images = cell(1, n);
    % 3、初始化加密矩阵
    C0 = [];
    C1 = [];
    for p = 0:k
        % 如果 p 为偶数，添加新列至 C0
        if mod(p, 2) == 0
            % get_q_ones_vectors(q, n): 返回单列中存在 k 个 1 的所有列向量，共 C_n_q 个
            % howmany_ones_need(p, k, n): 如果 2p <= k，输出 q = p；否则输出 q = n + p - k
            q = howmany_ones_need(p, k, n);
            C0 = [C0, get_q_ones_vectors(q, n)];
        end
        % 如果 p 为奇数，添加新列至 C1
        if mod(p, 2) == 1
            q = howmany_ones_need(p, k, n);
            C1 = [C1, get_q_ones_vectors(q, n)];
        end
    end
    % 4、循环处理多余列直至结束
    % 初始化可用资源列信息
    C0_use = ones(1, size(C0, 2));
    C1_use = ones(1, size(C1, 2));
    % 如果存在列未被使用
    while any(C0_use) || any(C1_use)
        if any(C1_use)
            % 提取可使用列，并对其可用标记清零
            C1_new = C1(:, logical(C1_use));
            C1_use(logical(C1_use)) = 0;
            % get_odd_weights(A, k, who): 对一矩阵任取 k 行，若存在这 k 行中某列包含奇(偶)数个1，记录 k 行下该列包含 1 的个数 r，返回所有可能的 r
            rs = get_odd_weights(C1_new, k, 1);
            % 对每个多余量 r，添加多余列至 C0
            for r_i = 1:length(rs)
                q = howmany_ones_need(rs(r_i), k, n);
                add = get_q_ones_vectors(q, n);
                C0 = [C0, add];
                C0_use = [C0_use, ones(1, size(add, 2))];
            end
        end
        if any(C0_use)
            C0_new = C0(:, logical(C0_use));
            C0_use(logical(C0_use)) = 0;
            rs = get_odd_weights(C0_new, k, 0);
            for r_i = 1:length(rs)
                q = howmany_ones_need(rs(r_i), k, n);
                add = get_q_ones_vectors(q, n);
                C1 = [C1, add];
                C1_use = [C1_use, ones(1, size(add, 2))];
            end
        end
    end
    % 5、利用加密矩阵得到 n 个共享份
    m = size(C0, 2);
    get_n = ceil(sqrt(m));
    e_b = zeros(1, m + 1);
    % 按 get_n 行对矩阵 binary_image 进行切割并列优先拼接
    num_blocks = ceil(height / get_n);
    blocks_cell = cell(num_blocks, 1);
    for i = 1:num_blocks
        row_range = ((i-1)*get_n + 1) : min(i*get_n, height);
        block = binary_image(row_range, :);
        blocks_cell{i} = block(:); % 列优先展开
    end
    secret_vector = vertcat(blocks_cell{:});
    % 6、根据 secret_vector 生成 n 个共享份向量 sub_vectors
    num_pixels = length(secret_vector);
    sub_vectors = cell(1, n);
    for i = 1:n
        sub_vectors{i} = zeros(1, num_pixels);
    end
    for start_idx = 1:m:num_pixels
        end_idx = min(start_idx + m - 1, num_pixels);
        current_segment = secret_vector(start_idx:end_idx);
        s = length(current_segment);
        b = sum(current_segment == 1); 
        if s == m
            % 完整块处理：使用 e_b mod m < b 判断
            if mod(e_b(b+1), m) < b
                Cx = C1(:, randperm(m));
            else
                Cx = C0(:, randperm(m));
            end
        else
            % 最后一组不足 m 个像素的处理
            if b < s / 2
                Cx = C0(:, randperm(m));
            else
                Cx = C1(:, randperm(m));
            end
        end
        e_b(b+1) = e_b(b+1) + 1;
        % 将 Cx 的列值分配给 sub_vectors
        for j = 1:s
            k_pos = start_idx + j - 1;
            for i_idx = 1:n
                sub_vectors{i_idx}(k_pos) = Cx(i_idx, j);
            end
        end
    end
    % 7、根据 sub_vectors 还原 n 个 sub_images
    for i_idx = 1:n
        current_v = sub_vectors{i_idx};
        current_img = zeros(height, width);
        curr_pos = 1;
        for i = 1:num_blocks
            row_range = ((i-1)*get_n + 1) : min(i*get_n, height);
            block_h = length(row_range);
            block_size = block_h * width;
            block_data = current_v(curr_pos : curr_pos + block_size - 1);
            current_img(row_range, :) = reshape(block_data, [block_h, width]);
            
            curr_pos = curr_pos + block_size;
        end
        % 还原为原始图像逻辑（0为黑，1为白），与开头的取反操作对应
        sub_images{i_idx} = ~current_img;
    end
    % 8、可视化结果展示并保存
    % 画布：展示原秘密图像
    figure('Name', '原始秘密图像', 'NumberTitle', 'off');
    imshow(~binary_image);
    title('原始秘密图像');
    imwrite(~binary_image, 'original_secret_binary.png');
    % 画布：展示生成的 n 个密钥图 (每个密钥图一个画布)
    for i = 1:n
        figure('Name', sprintf('共享份 %d', i), 'NumberTitle', 'off');
        imshow(sub_images{i});
        title(sprintf('共享份 %d', i));
        imwrite(sub_images{i}, sprintf('share_%d.png', i));
    end
    % 9、多份共享份异或还原与可视化并保存
    xor_images = cell(1, n-1);
    for many = 2:n
        selected_indices = 1:many;
        % 对选出的 many 份图像进行异或操作
        % 为了保证逻辑一致性，先将密钥图还原为“1为黑”的状态进行异或
        temp_xor = ~sub_images{selected_indices(1)};
        for idx = 2:many
            temp_xor = xor(temp_xor, ~sub_images{selected_indices(idx)});
        end
        t = many - 1;
        % 异或结果中 1为黑，显示时取反回“0为黑”的状态
        xor_images{t} = ~temp_xor;
        % 画布：展示每一组异或结果
        figure('Name', sprintf('任意 %d 份异或还原结果', many), 'NumberTitle', 'off');
        imshow(xor_images{t});
        title(sprintf('任意 %d 份异或', many));
        imwrite(xor_images{t}, sprintf('xor_reconstruction_%d_shares.png', many));
    end
end