% SETTING UP  THE TEST POINTS 
snr_test = [-3.0, -2.5, -2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5];
ber_result = zeros(10, 1);

disp('Starting Automated BER Test...');

%MAIN LOOP OVER ALL SNR VALUES 
for test_idx = 1:10
    
    current_snr = snr_test(test_idx);
    
    
    current_var = 10^(-current_snr / 10);
    
   
    set_param('GNSS_Channel/AWGN Channel', 'SNR', num2str(current_snr));
    set_param('GNSS_Channel/BPSK Demodulator Baseband', 'Variance', num2str(current_var));
    

    sim_data = sim('GNSS_Channel');
    
    
    rx_llr_full = sim_data.rx_llr;
    rx_llr_full = rx_llr_full(:);
    
  
    rx_llr = zeros(576, 1);
    for i = 1:576
        rx_llr(i) = rx_llr_full(24 + i);
        if rx_llr(i) > 1000
            rx_llr(i) = 1000;
        elseif rx_llr(i) < -1000
            rx_llr(i) = -1000;
        end
    end
    
    %  CONVERT TO COSTS 
    sym_llr = zeros(64, 96);
    for i = 1:96
        for v = 0:63
            temp_v = v;
            total_cost = 0;
            for j = 6:-1:1
                bit_val = mod(temp_v, 2);
                temp_v = (temp_v - bit_val) / 2; 
                bit_idx = (i - 1) * 6 + j;
                llr_val = rx_llr(bit_idx);
                
                if bit_val == 0
                    if llr_val < 0
                        total_cost = total_cost - llr_val; 
                    end
                end
                if bit_val == 1
                    if llr_val > 0
                        total_cost = total_cost + llr_val; 
                    end
                end
            end
            sym_llr(v + 1, i) = total_cost;
        end
    end
    
    % EMS MIN-SUM DECODER 
    V2C = zeros(64, 48, 4); 
    C2V = zeros(64, 48, 4); 
    decoded = zeros(96, 1);
    
    % Init V2C
    for c = 1:48
        for e = 1:4
            v_idx = H_idx(c, e);
            for val = 0:63
                V2C(val+1, c, e) = sym_llr(val+1, v_idx);
            end
        end
    end
    
    % Main Decoder Loop
    for iter = 1:10
        for c = 1:48
            V2C_perm = zeros(64, 4);
            for e = 1:4
                h_val = H_val(c, e);
                for val = 0:63
                    val_perm = gf_mul(h_val+1, val+1);
                    V2C_perm(val_perm+1, e) = V2C(val+1, c, e);
                end
            end
            
            C2V_perm = zeros(64, 4);
            for e = 1:4
                other_edges = zeros(3, 1);
                idx = 1;
                for temp_e = 1:4
                    if temp_e ~= e
                        other_edges(idx) = temp_e;
                        idx = idx + 1;
                    end
                end
                
                e1 = other_edges(1); e2 = other_edges(2); e3 = other_edges(3);
                
                temp_conv = zeros(64, 1);
                for v = 0:63
                    temp_conv(v+1) = 100000;
                end
                for v1 = 0:63
                    for v2 = 0:63
                        v_sum = bitxor(v1, v2);
                        cost = V2C_perm(v1+1, e1) + V2C_perm(v2+1, e2);
                        if cost < temp_conv(v_sum+1)
                            temp_conv(v_sum+1) = cost;
                        end
                    end
                end
                
                for v = 0:63
                    C2V_perm(v+1, e) = 100000; 
                end
                for v12 = 0:63
                    for v3 = 0:63
                        v_sum = bitxor(v12, v3);
                        cost = temp_conv(v12+1) + V2C_perm(v3+1, e3);
                        if cost < C2V_perm(v_sum+1, e)
                            C2V_perm(v_sum+1, e) = cost;
                        end
                    end
                end
            end
            
            for e = 1:4
                h_val = H_val(c, e);
                for val_perm = 0:63
                    val = gf_div(val_perm+1, h_val+1);
                    C2V(val+1, c, e) = C2V_perm(val_perm+1, e);
                end
            end
        end
        
        for v = 1:96
            total_costs = zeros(64, 1);
            for val = 0:63
                total_costs(val+1) = sym_llr(val+1, v);
            end
            for c = 1:48
                for e = 1:4
                    if H_idx(c, e) == v
                        for val = 0:63
                            total_costs(val+1) = total_costs(val+1) + C2V(val+1, c, e);
                        end
                    end
                end
            end
            
            min_t = total_costs(1);
            for val = 1:63
                if total_costs(val+1) < min_t
                    min_t = total_costs(val+1);
                end
            end
            
            best_val = 0; best_cost = 1000000;
            for val = 0:63
                total_costs(val+1) = total_costs(val+1) - min_t;
                if total_costs(val+1) < best_cost
                    best_cost = total_costs(val+1);
                    best_val = val;
                end
            end
            decoded(v) = best_val;
            
            for c = 1:48
                for e = 1:4
                    if H_idx(c, e) == v
                        for val = 0:63
                            V2C(val+1, c, e) = total_costs(val+1) - C2V(val+1, c, e) + min_t;
                        end
                    end
                end
            end
        end
        
        syndrome_ok = 1;
        for c = 1:48
            row_sum = 0;
            for e = 1:4
                v_idx = H_idx(c, e);
                h_val = H_val(c, e);
                v_val = decoded(v_idx);
                mul_val = gf_mul(h_val+1, v_val+1);
                row_sum = bitxor(row_sum, mul_val);
            end
            if row_sum ~= 0
                syndrome_ok = 0;
                break;
            end
        end
        
        if syndrome_ok == 1
            break;
        end
    end
    
    % BER CALCULATION 
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
    
    errors = 0;
    for i = 1:288
        if bits_hat(i) ~= tx_bits(i)
            errors = errors + 1;
        end
    end
    BER = errors / 288;
    
    
    ber_result(test_idx) = BER;
    disp(['Simulink SNR: ', num2str(current_snr, '%0.1f'), ' dB | Iters: ', num2str(iter), ' | Errors: ', num2str(errors), ' | BER: ', num2str(BER)]);
    
end

% Plotting the result 
figure;
semilogy(snr_test, ber_result, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
grid on;
title('GF(64) LDPC Waterfall Curve (BeiDou B-CNAV2)');
xlabel('Simulink SNR (E_s/N_0) in dB');
ylabel('Bit Error Rate (BER)');


ylim([1e-3, 1]); 
disp('Waterfall Test Complete! Plot generated.');