% Defining the 24-bit Preamble manually (0xE24DE8) from the Annex
preamble = [1; 1; 1; 0; 0; 0; 1; 0; 0; 1; 0; 0; 1; 1; 0; 1; 1; 1; 1; 0; 1; 0; 0; 0];

frame_bits = zeros(600, 1);

%  Copying Preamble to the front
for i = 1:24
    frame_bits(i) = preamble(i);
end

% Copying the encoded bits after the preamble
for i = 1:576
    frame_bits(24 + i) = encoded_bits(i);
end

% 5. Preparing data format for Simulink 'From Workspace'
sim_time = zeros(600, 1);
for i = 1:600
    sim_time(i) = i - 1;
end
tx_sim_data = [sim_time, frame_bits];

disp(' 600-bit frame ready for Simulink.');