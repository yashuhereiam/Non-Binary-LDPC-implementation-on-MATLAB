% 1. Converting 48 message symbols  into a GF(64) column vector
symbols_gf = gf(symbols, 6, 67);

% 2. Calculating the 48 parity symbols using simple matrix multiplication
parity_gf = B_inv_A_gf * symbols_gf;

% 3. Combining message and parity into the final 96-symbol encoded vector
encoded_gf = [symbols_gf; parity_gf];

% 4. Converting back to standard MATLAB doubles so we can turn them into bits
encoded = double(encoded_gf.x);