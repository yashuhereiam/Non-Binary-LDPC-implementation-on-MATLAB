
PRN_bits  = zeros(6, 1);
Type_bits = zeros(6, 1);
SOW_bits  = zeros(18, 1);
Data_bits = zeros(234, 1);
CRC_bits  = zeros(24, 1);
tx_bits   = zeros(288, 1);

% PRN = 14 (001110)
PRN_bits(1) = 0; PRN_bits(2) = 0; PRN_bits(3) = 1; 
PRN_bits(4) = 1; PRN_bits(5) = 1; PRN_bits(6) = 0;

% Type = 10 (001010)
Type_bits(1) = 0; Type_bits(2) = 0; Type_bits(3) = 1; 
Type_bits(4) = 0; Type_bits(5) = 1; Type_bits(6) = 0;

% SOW = 100000 (011000011010100000)
SOW_bits(1) = 0;  SOW_bits(2) = 1;  SOW_bits(3) = 1;  SOW_bits(4) = 0; 
SOW_bits(5) = 0;  SOW_bits(6) = 0;  SOW_bits(7) = 0;  SOW_bits(8) = 1; 
SOW_bits(9) = 1;  SOW_bits(10) = 0; SOW_bits(11) = 1; SOW_bits(12) = 0; 
SOW_bits(13) = 1; SOW_bits(14) = 0; SOW_bits(15) = 0; SOW_bits(16) = 0; 
SOW_bits(17) = 0; SOW_bits(18) = 0;

% 5 Data = 234 bits (alternating 1s and 0s)
for i = 1:234
    half_i = floor(i / 2);
    if i == (half_i * 2)
        Data_bits(i) = 0; % Even index
    else
        Data_bits(i) = 1; % Odd index
    end
end

% 6. CRC = 24 dummy bits 
for i = 1:24
    third_i = floor(i / 3);
    if i == (third_i * 3)
        CRC_bits(i) = 1;
    else
        CRC_bits(i) = 0;
    end
end


current_idx = 1;

for i = 1:6
    tx_bits(current_idx) = PRN_bits(i);
    current_idx = current_idx + 1;
end

for i = 1:6
    tx_bits(current_idx) = Type_bits(i);
    current_idx = current_idx + 1;
end

for i = 1:18
    tx_bits(current_idx) = SOW_bits(i);
    current_idx = current_idx + 1;
end

for i = 1:234
    tx_bits(current_idx) = Data_bits(i);
    current_idx = current_idx + 1;
end

for i = 1:24
    tx_bits(current_idx) = CRC_bits(i);
    current_idx = current_idx + 1;
end

disp('Example values loaded! tx_bits is 288x1.');