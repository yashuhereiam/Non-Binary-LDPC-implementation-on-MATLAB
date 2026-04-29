% Generating GF(64) Elements
N_GF = 64;
gf_exp = zeros(N_GF, 1);
gf_log = zeros(N_GF, 1);


gf_exp(1) = 1;
gf_log(1) = -1; % -1 for -Inf
for i = 1:62
    val = gf_exp(i) * 2;
    if val >= 64
        val = bitxor(val, 67); % 67 is 1000011 binary
    end
    gf_exp(i+1) = val;
end
gf_exp(64) = 0; % Index 64 is value 0

for i = 1:63
    val = gf_exp(i);
    gf_log(val + 1) = i - 1; % +1 for 1-based indexing
end
gf_log(1) = -1;

