# Solution to MATLAB and Simulink Challenge project  '192' 'Improve the Accuracy of Satellite Navigation Systems'


[Program link](https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub)

[Project description link] 
(https://github.com/mathworks/MATLAB-Simulink-Challenge-Project-Hub/blob/main/projects/Improve%20the%20Accuracy%20of%20Satellite%20Navigation%20Systems/README.md)


# BeiDou GF(64) Non-Binary LDPC Communication System

## Project Details
This project implements a complete, end-to-end simulation of a GNSS communication link compliant with the **BeiDou Navigation Satellite System (BDS) B-CNAV2 Signal In Space Interface Control Document (ICD)**. 

The core achievement of this project is the **implementation** of a Galois Field $GF(64)$ Non-Binary Low-Density Parity-Check (LDPC) encoder and an Extended Min-Sum (EMS) iterative decoder. To demonstrate a fundamental understanding of information theory, the LDPC algorithms were engineered using explicit matrix operations and basic loop logic in MATLAB.

**Approach Adopted:**
* **Transmitter (TX):** Generates a 288-bit payload (PRN, Type, SOW, Data, CRC) and maps it to 48 $GF(64)$ symbols. An LDPC encoder multiplies the systematic symbols by a pre-calculated parity matrix $p = B^{-1}(Au)$ (derived from the Annex $H_{48,96}$ matrix with a row weight of 4). The 96 encoded symbols are converted to a 576-bit stream, appended with the 24-bit BeiDou synchronization preamble (`0xE24DE8`), and passed to Simulink.
* **Channel:** Modeled in Simulink using BPSK Baseband Modulation, an AWGN channel parameterized by SNR, and a soft-decision BPSK Demodulator that outputs Log-Likelihood Ratios (LLRs).
* **Receiver (RX):** Strips the preamble and translates the 576 LLRs into a $64 \times 96$ penalty cost matrix. A custom EMS decoder executes a Extended Min-Sum algorithm, using pre-calculated $GF(64)$ arithmetic tables to permute Check-to-Variable and Variable-to-Check messages across the Tanner graph. The decoder limits at 10 iterations to resolve noise conflicts and extract the corrected bits.

---

## How to Run
### Prerequisites
To run this simulation, you will need:
* **MATLAB**.
* **Simulink**.
* **Communications Toolbox** (Required only for the basic Simulink Modulation/AWGN channel blocks and `gf()` array initialization).

### Step-by-Step Execution


1. **Initialize & Encode (TX):** (Run `gf_generator.m` to generate gf(64) elements if not use gf() functions) i. Run `example_message-signal` to generate the message signal ii. `bit_to_gf64.m` to convert bits to gf(64) field iii.`H_matrix_generation` to initialize the H matrix iv.`encoder.m` to apply the Annex matrix encoding v.`symbol_to_bit_conversion.m` for  conversion of gf to bits  and add the preamble using `add_preamble`.
2. **Run the Channel:** Open `GNSS_Channel.slx`. Ensure the `From Workspace` block is linked to `tx_sim_data`. You can manually adjust the AWGN **SNR (dB)** and the Demodulator **Variance** ($10^{-\text{SNR}/10}$), then click **Run**.
3. **Decode & Verify (RX):** Run `bit_llr_to_gf.m` to strip the preamble, convert LLRs to gf(64) costs , and `gf_math_table_precompute.m` to precompute gf tables which is going to be used in the decoder , `decoder.m` execute the Min-Sum iterations. Finally, run `ber_test.m` to extract the binary data and print the Bit Error Rate (BER) to the console.
4. **Automated Waterfall Testing:** To test the system across multiple noise levels automatically, simply run `ber_plot.m`. This script will loop through Simulink SNR values from `-3.0 db` to `+1.5 dB`, decode each frame, and plot the performance curve.

---

## Demo / Results
*Note: Below is the performance of the system resolving extreme channel noise.*

<img width="883" height="810" alt="image" src="https://github.com/user-attachments/assets/47d401be-2869-4fcb-9e9b-f133f179cafb" />


<img width="576" height="259" alt="image" src="https://github.com/user-attachments/assets/7fdc82b0-8828-484f-bf47-977e7c9bd11c" />





**Expected Results:**
Due to the rate-$1/2$ nature of the LDPC code, the Bit SNR ($E_b/N_0$) is roughly `3 dB` higher than the Simulink symbol SNR. 
* At **-3.0 dB Simulink SNR** (approx. 0 dB $E_b/N_0$), the noise overpowers the decoder, resulting in a high error rate (decoder hits maximum iterations).
* At **-1.5 dB Simulink SNR** (approx. 1.5 dB $E_b/N_0$), the custom EMS decoder successfully fights through the heavy noise, iterating ~8 times to perfectly resolve the Tanner graph.
* At **0 dB Simulink SNR and above**, the decoder easily achieves a **0.0 BER**, matching theoretical expectations for the BeiDou B-CNAV2 standard.

---

## References
1. **BeiDou Navigation Satellite System Signal In Space Interface Control Document** - *Open Service Signals B1C and B2a (Test Version), August 2017.* China Satellite Navigation Office. (Used for frame structure, synchronization preamble, and $H_{48,96}$ matrix definitions).
2. **Declercq, D., & Fossorier, M. (2007).** *Decoding algorithms for nonbinary LDPC codes over GF(q).* IEEE Transactions on Communications. (Reference for Extended Min-Sum algorithm theory).
