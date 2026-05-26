//=====================================================================
// Data I/O 29B Memory Board
// CPLD: ATF1504AS TQFP-44
// 
// Address routing:
//   CPU A13..A0 → SRAM A13..A0 (direct)
//   CPLD RB4..RB0 → SRAM A18..A14 (bank select)
//   CPLD uses bank_reg[5] to select SRAM0/SRAM1 (A19)
//=====================================================================

module dataio_29b_memory (
    // ---------- CPU Address Bus ----------
    input  wire       A0, A1, A2, A3, A4, A5, A6, A7,
                       A8, A9, A10, A11, A12, A13, A14, A15,
    
    // ---------- CPU Data Bus ----------
    inout  wire       D0, D1, D2, D3, D4, D6, D7,  // D5 not connected
    
    // ---------- CPU Control Signals ----------
    input  wire       nEN,         // Board enable (active low)
    input  wire       nWR,         // Write enable (active low)
    input  wire       nVO2,        // NAND(VMA, E) from 6802 pins 5+37 — active low
    
    // ---------- Memory Size Jumpers ----------
    input  wire       SEL0, SEL1,  // Pull-up, open = 1
    
    // ---------- JTAG Interface ----------
    input  wire       TDI, TMS, TCK,
    output wire       TDO,
    
    // ---------- SRAM Control Outputs ----------
    output wire       nRAM_A,      // SRAM0 chip select
    output wire       nRAM_B,      // SRAM1 chip select
    output wire       nRAM_WE,     // SRAM write enable
    
    // ---------- Bank Register Outputs (to SRAM A18..A14) ----------
    output reg        RB0, RB1, RB2, RB3, RB4
);

    // =================================================================
    // Internal Registers & Wires
    // =================================================================
    reg [5:0] bank_reg;            // {D7, D6, D3, D2, D1, D0}
    wire [15:0] A;
    
    // =================================================================
    // Address Bus Concatenation
    // =================================================================
    assign A = {A15, A14, A13, A12, A11, A10, A9, A8,
                A7, A6, A5, A4, A3, A2, A1, A0};
    
    // =================================================================
    // Address Decoding
    // =================================================================
    // nVO2 is active-low (NAND of VMA and E): asserted (low) during valid cycle.
    // Bank register latch uses posedge nVO2 (= falling E edge) so nVO2 is
    // excluded from the async enables to avoid a same-edge race in simulation.
    wire is_e300_write = (A == 16'hE300) && !nEN && !nWR;
    wire is_e301_write = (A == 16'hE301) && !nEN && !nWR;
    wire is_e302_read  = (A == 16'hE302) && !nEN &&  nWR && !nVO2;

    // RAM window is $2000-$5FFF (16KB)
    wire is_ram_area = (A >= 16'h2000) && (A <= 16'h5FFF) && !nEN && !nVO2;
    
    // =================================================================
    // Bank Register Latch (per original 29B hardware)
    // $E300 captures D0-D3, $E301 captures D6-D7
    // =================================================================
    always @(posedge nVO2) begin
        if (is_e300_write)
            bank_reg[3:0] <= {D3, D2, D1, D0};   // D0-D3
        if (is_e301_write)
            bank_reg[5:4] <= {D7, D6};            // D6-D7
    end
    
    // =================================================================
    // Bank Register Outputs to SRAM Address Lines (A18..A14)
    // Note: A13 comes directly from CPU, not from CPLD
    // =================================================================
    always @(*) begin
        RB0 = bank_reg[0];   // SRAM A14
        RB1 = bank_reg[1];   // SRAM A15
        RB2 = bank_reg[2];   // SRAM A16
        RB3 = bank_reg[3];   // SRAM A17
        RB4 = bank_reg[4];   // SRAM A18 (from D6)
    end
    
    // =================================================================
    // Memory Size Limiting (from jumpers SEL0, SEL1)
    // Max bank is now 5 bits (32 banks per SRAM = 512KB per chip)
    // =================================================================
    wire [4:0] max_bank;
    assign max_bank = ({SEL1, SEL0} == 2'b00) ? 5'd31 :   // 1MB (32+32 banks)
                      ({SEL1, SEL0} == 2'b01) ? 5'd15 :   // 512KB (16+16 banks)
                      ({SEL1, SEL0} == 2'b10) ? 5'd7  :   // 256KB (8+8 banks)
                                                5'd3  ;   // 128KB (4+4 banks)
    
    wire [4:0] current_bank = bank_reg[4:0];
    wire bank_valid = (current_bank <= max_bank);
    
    // =================================================================
    // SRAM Chip Selects (bit 5 from D7 selects which SRAM)
    // =================================================================
    wire use_sram0 = !bank_reg[5];   // SRAM0 when bank bit 5 = 0
    wire use_sram1 =  bank_reg[5];   // SRAM1 when bank bit 5 = 1
    
    assign nRAM_A = !(is_ram_area && bank_valid && use_sram0);
    assign nRAM_B = !(is_ram_area && bank_valid && use_sram1);
    
    // =================================================================
    // SRAM Write Enable
    // =================================================================
    assign nRAM_WE = nWR;
    
    // =================================================================
    // JTAG TDO (high-Z during normal operation)
    // =================================================================
    assign TDO = 1'bz;
    
    // =================================================================
    // Data Bus Output (Parity Emulation at $E302)
    // When reading $E302: D7 low = no parity error
    // =================================================================
    wire drive_data = is_e302_read;
    
    assign D0 = drive_data ? 1'b1 : 1'bz;
    assign D1 = drive_data ? 1'b1 : 1'bz;
    assign D2 = drive_data ? 1'b1 : 1'bz;
    assign D3 = drive_data ? 1'b1 : 1'bz;
    assign D4 = drive_data ? 1'b1 : 1'bz;
    assign D6 = drive_data ? 1'b1 : 1'bz;
    assign D7 = drive_data ? 1'b0 : 1'bz;   // D7 low = no parity error

endmodule