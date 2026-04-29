% 1. Extracting the full 600 LLRs from Simulink
rx_llr_full = out.rx_llr;
rx_llr_full = rx_llr_full(:);


rx_llr = zeros(576, 1);

% 3. Stripping the first 24 bits by skipping them
for i = 1:576
    rx_llr(i) = rx_llr_full(24 + i);
end

% 4. Clamp the LLRs just in case they have very high values 
for i = 1:576
    if rx_llr(i) > 1000
        rx_llr(i) = 1000;
    elseif rx_llr(i) < -1000
        rx_llr(i) = -1000;
    end
end

disp(' Preamble stripped and 576 LLRs clamped.');

% CONVERT BIT LLRs TO GF(64) COSTS
sym_llr = zeros(64, 96);

for i = 1:96
    for v = 0:63
        temp_v = v;
        total_cost = 0;
        
        % Extract bits from LSB (j=6) up to MSB (j=1)
        for j = 6:-1:1
            % Manual elementary bit extraction
            bit_val = mod(temp_v, 2);
            temp_v = (temp_v - bit_val) / 2; 
            
            bit_idx = (i - 1) * 6 + j;
            llr_val = rx_llr(bit_idx);
            
            % Add penalty if the bit does not match the LLR's hard decision
            % (LLR > 0 means 0 is likely. LLR < 0 means 1 is likely)
            if bit_val == 0
                if llr_val < 0
                    total_cost = total_cost - llr_val; % Penalty is positive
                end
            end
            
            if bit_val == 1
                if llr_val > 0
                    total_cost = total_cost + llr_val; % Penalty is positive
                end
            end
        end
        
        % Store the cost (v+1 because MATLAB starts at index 1)
        sym_llr(v + 1, i) = total_cost;
    end
end

disp('sym_llr is ready.');