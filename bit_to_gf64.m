symbols = zeros(48, 1);
for i = 1:48
    val = 0;
    for j = 1:6
        bit_idx = (i - 1) * 6 + j;
        bit_val = tx_bits(bit_idx);
        % Binary to Decimal  (MSB first)
        weight = 1;
        for k = 1:(6 - j)
            weight = weight * 2;
        end
        val = val + bit_val * weight;
    end
    symbols(i) = val;
end