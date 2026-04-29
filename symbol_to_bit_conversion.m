
encoded_bits = zeros(576, 1);

% Converting each symbol to 6 bits (MSB first)
for i = 1:96
    val = encoded(i);
    
    for j = 1:6
        % Calculating the weight of the current bit position (32, 16, 8, 4, 2, 1)
        weight = 1;
        for k = 1:(6 - j)
            weight = weight * 2;
        end
        
        % Subtract weight if value is large enough (manual decimal-to-binary)
        if val >= weight
            bit_val = 1;
            val = val - weight;
        else
            bit_val = 0;
        end
        
        % Storing the bit in the correct position
        bit_idx = (i - 1) * 6 + j;
        encoded_bits(bit_idx) = bit_val;
    end
end


sim_time = zeros(576, 1);
for i = 1:576
    sim_time(i) = i - 1;
end
tx_sim_data = [sim_time, encoded_bits];

disp(' 576 bits ready ');