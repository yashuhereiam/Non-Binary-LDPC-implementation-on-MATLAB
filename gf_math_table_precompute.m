
gf_mul = zeros(64, 64);
gf_div = zeros(64, 64);

for i = 0:63
    for j = 0:63
        % Multiplication (i * j)
        if (i == 0) || (j == 0)
            gf_mul(i+1, j+1) = 0;
        else
            idx = gf_log(i+1) + gf_log(j+1);
            while idx >= 63
                idx = idx - 63;
            end
            gf_mul(i+1, j+1) = gf_exp(idx+1);
        end
        
        % Division (i / j)
        if j == 0
            gf_div(i+1, j+1) = 0; % Prevent crash on div by 0
        elseif i == 0
            gf_div(i+1, j+1) = 0;
        else
            idx = gf_log(i+1) - gf_log(j+1);
            while idx < 0
                idx = idx + 63;
            end
            gf_div(i+1, j+1) = gf_exp(idx+1);
        end
    end
end
disp('GF Math tables ready!');