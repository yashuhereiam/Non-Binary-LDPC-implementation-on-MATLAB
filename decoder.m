max_iter = 10;
V2C = zeros(64, 48, 4); % Variable to Check messages
C2V = zeros(64, 48, 4); % Check to Variable messages
decoded = zeros(96, 1);

% INITIALIZE V2C WITH CHANNEL COSTS
for c = 1:48
    for e = 1:4
        v_idx = H_idx(c, e);
        for val = 0:63
            V2C(val+1, c, e) = sym_llr(val+1, v_idx);
        end
    end
end

% MAIN DECODING LOOP
for iter = 1:max_iter
    
    % CHECK NODE UPDATE
    for c = 1:48
        
        % Permute V2C messages into check node domain (Multiply by H_val)
        V2C_perm = zeros(64, 4);
        for e = 1:4
            h_val = H_val(c, e);
            for val = 0:63
                val_perm = gf_mul(h_val+1, val+1);
                V2C_perm(val_perm+1, e) = V2C(val+1, c, e);
            end
        end
        
        % Calculate C2V_perm for each edge by combining the OTHER 3 edges
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
            
            e1 = other_edges(1);
            e2 = other_edges(2);
            e3 = other_edges(3);
            
            % Convolve edge 1 and edge 2
            temp_conv = zeros(64, 1);
            for v = 0:63
                temp_conv(v+1) = 100000; % Initialize with high cost
            end
            for v1 = 0:63
                for v2 = 0:63
                    v_sum = bitxor(v1, v2); % GF Add is bitxor
                    cost = V2C_perm(v1+1, e1) + V2C_perm(v2+1, e2);
                    if cost < temp_conv(v_sum+1)
                        temp_conv(v_sum+1) = cost;
                    end
                end
            end
            
            %  Convolve result with edge 3
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
        
        %Inverse Permute back to Variable domain (Divide by H_val)
        for e = 1:4
            h_val = H_val(c, e);
            for val_perm = 0:63
                val = gf_div(val_perm+1, h_val+1);
                C2V(val+1, c, e) = C2V_perm(val_perm+1, e);
            end
        end
    end
    
    % VARIABLE NODE UPDATE & HARD DECISION
    for v = 1:96
        total_costs = zeros(64, 1);
        
        % Start with Channel Cost
        for val = 0:63
            total_costs(val+1) = sym_llr(val+1, v);
        end
        
        % Add C2V messages from all connected Check Nodes
        for c = 1:48
            for e = 1:4
                if H_idx(c, e) == v
                    for val = 0:63
                        total_costs(val+1) = total_costs(val+1) + C2V(val+1, c, e);
                    end
                end
            end
        end
        
        % Normalize to prevent numbers from growing to infinity
        min_t = total_costs(1);
        for val = 1:63
            if total_costs(val+1) < min_t
                min_t = total_costs(val+1);
            end
        end
        
        % Hard Decision 
        best_val = 0;
        best_cost = 1000000;
        for val = 0:63
            total_costs(val+1) = total_costs(val+1) - min_t;
            if total_costs(val+1) < best_cost
                best_cost = total_costs(val+1);
                best_val = val;
            end
        end
        decoded(v) = best_val;
        
        % Create new V2C messages for next iteration
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
    
    % SYNDROME CHECK 
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
        disp(['Decoding converged at iteration ', num2str(iter)]);
        break;
    end
end