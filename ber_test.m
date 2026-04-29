bits_hat = zeros(288, 1);

for i = 1:48
    val = decoded(i);
    for j = 1:6
        weight = 1;
        for k = 1:(6 - j)
            weight = weight * 2;
        end
        
        if val >= weight
            bit_val = 1;
            val = val - weight;
        else
            bit_val = 0;
        end
        bit_idx = (i - 1) * 6 + j;
        bits_hat(bit_idx) = bit_val;
    end
end

% BER Calculation
errors = 0;
for i = 1:288
    if bits_hat(i) ~= tx_bits(i)
        errors = errors + 1;
    end
end
BER = errors / 288;
disp(['Total Errors = ', num2str(errors)]);
disp(['BER = ', num2str(BER)]);