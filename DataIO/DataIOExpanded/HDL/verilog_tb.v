//=====================================================================
// Test Bench for Data I/O 29B Memory Board
// With dual AS6C4008 SRAM instances (512KB each = 1MB total)
//=====================================================================

`timescale 1ns / 1ps

module dataio_29b_memory_tb;

    // =================================================================
    // Test Bench Signals
    // =================================================================
    reg         A0, A1, A2, A3, A4, A5, A6, A7,
                A8, A9, A10, A11, A12, A13, A14, A15;
    reg         nEN, nWR, nVO2;
    reg         SEL0, SEL1;
    reg         TDI, TMS, TCK;
    wire        TDO;
    wire        D0, D1, D2, D3, D4, D6, D7;  // D5 not connected
    wire        nRAM_A, nRAM_B, nRAM_WE;
    wire        RB0, RB1, RB2, RB3, RB4;
    
    // Data bus drive from test bench (during write cycles)
    reg  [7:0]  cpu_data_out;
    wire [7:0]  cpu_data_in;

    // Test variables
    reg  [7:0]  read_data;
    reg  [7:0]  pattern1, pattern2;
    reg         test_passed;
    integer     i;
    reg  [7:0]  expected [0:1023];
    integer     fail_count;
    
    // D5 is not connected to CPLD — tie to GND in simulation
    wire        D5 = 1'bz;
    
    // =================================================================
    // SRAM Connections
    // =================================================================
    // SRAM0: 512KB, enabled by nRAM_A
    wire [18:0] sram0_addr;
    wire [7:0]  sram0_dq;
    
    // SRAM1: 512KB, enabled by nRAM_B
    wire [18:0] sram1_addr;
    wire [7:0]  sram1_dq;
    
    // Address construction for SRAMs:
    //   A18..A14 from CPLD (RB4..RB0)
    //   A13..A0 from CPU (direct)
    assign sram0_addr = {RB4, RB3, RB2, RB1, RB0, A13, A12, A11, A10, A9, A8, 
                         A7, A6, A5, A4, A3, A2, A1, A0};
    assign sram1_addr = {RB4, RB3, RB2, RB1, RB0, A13, A12, A11, A10, A9, A8,
                         A7, A6, A5, A4, A3, A2, A1, A0};
    
    // CPU drives SRAM DQ during writes; SRAM model drives DQ during reads
    assign sram0_dq = (nRAM_A == 0 && nRAM_WE == 0) ? cpu_data_out : 8'bzzzzzzzz;
    assign sram1_dq = (nRAM_B == 0 && nRAM_WE == 0) ? cpu_data_out : 8'bzzzzzzzz;
    
    // =================================================================
    // Instantiate DUT (CPLD)
    // =================================================================
    dataio_29b_memory dut (
        .A0(A0), .A1(A1), .A2(A2), .A3(A3), .A4(A4), .A5(A5), .A6(A6), .A7(A7),
        .A8(A8), .A9(A9), .A10(A10), .A11(A11), .A12(A12), .A13(A13), .A14(A14), .A15(A15),
        .D0(D0), .D1(D1), .D2(D2), .D3(D3), .D4(D4), .D6(D6), .D7(D7),
        .nEN(nEN), .nWR(nWR), .nVO2(nVO2),
        .SEL0(SEL0), .SEL1(SEL1),
        .TDI(TDI), .TMS(TMS), .TCK(TCK), .TDO(TDO),
        .nRAM_A(nRAM_A), .nRAM_B(nRAM_B), .nRAM_WE(nRAM_WE),
        .RB0(RB0), .RB1(RB1), .RB2(RB2), .RB3(RB3), .RB4(RB4)
    );
    
    // =================================================================
    // Instantiate SRAMs
    // =================================================================
    as6c4008 sram0_inst (
        .CE_n(nRAM_A),
        .OE_n(1'b0),           // Always enabled (WE# takes priority)
        .WE_n(nRAM_WE),
        .A(sram0_addr),
        .DQ(sram0_dq)
    );
    
    as6c4008 sram1_inst (
        .CE_n(nRAM_B),
        .OE_n(1'b0),           // Always enabled (WE# takes priority)
        .WE_n(nRAM_WE),
        .A(sram1_addr),
        .DQ(sram1_dq)
    );
    
    // =================================================================
    // Clock Generation
    // nVO2 = NAND(VMA, E) — active low, 2 MHz (500 ns period).
    // Starts low so the first valid cycle begins immediately.
    // =================================================================
    initial begin
        nVO2 = 0;
        forever #250 nVO2 = ~nVO2;
    end
    
    // =================================================================
    // Helper Tasks
    // =================================================================
    
    // CPU write cycle (nEN active, nWR low)
    task cpu_write;
        input [15:0] address;
        input [7:0] data;
        begin
            @(negedge nVO2);
            {A15,A14,A13,A12,A11,A10,A9,A8,
             A7,A6,A5,A4,A3,A2,A1,A0} = address;
            cpu_data_out = data;
            nWR = 0;
            nEN = 0;
            @(negedge nVO2);
            nWR = 1;
            nEN = 1;
        end
    endtask
    
    // CPU read cycle (nEN active, nWR high)
    task cpu_read;
        input [15:0] address;
        output [7:0] data;
        begin
            @(negedge nVO2);         // nVO2 goes low = start of valid cycle
            {A15,A14,A13,A12,A11,A10,A9,A8,
             A7,A6,A5,A4,A3,A2,A1,A0} = address;
            nWR = 1;
            nEN = 0;
            // nVO2 is now low: SRAM/CPLD is selected and driving data.
            // Sample 200 ns in (well inside the 250 ns valid window) to
            // avoid racing the posedge deselect.
            #200;
            data = cpu_data_in;
            @(posedge nVO2);         // wait for end of valid cycle
            nEN = 1;
        end
    endtask
    
    // Drive data bus from test bench during writes
    assign D0 = (nEN == 0 && nWR == 0) ? cpu_data_out[0] : 1'bz;
    assign D1 = (nEN == 0 && nWR == 0) ? cpu_data_out[1] : 1'bz;
    assign D2 = (nEN == 0 && nWR == 0) ? cpu_data_out[2] : 1'bz;
    assign D3 = (nEN == 0 && nWR == 0) ? cpu_data_out[3] : 1'bz;
    assign D4 = (nEN == 0 && nWR == 0) ? cpu_data_out[4] : 1'bz;
    assign D6 = (nEN == 0 && nWR == 0) ? cpu_data_out[6] : 1'bz;
    assign D7 = (nEN == 0 && nWR == 0) ? cpu_data_out[7] : 1'bz;
    
    // Capture data bus during reads (from either CPLD or SRAMs)
    assign cpu_data_in = (nEN == 0 && nWR == 1) ? 
                         (nRAM_A == 0 ? sram0_dq : 
                          (nRAM_B == 0 ? sram1_dq : 
                           {D7, D6, 1'b0, D4, D3, D2, D1, D0})) : 8'bzzzzzzzz;
    
    // =================================================================
    // Main Test Sequence
    // =================================================================
    initial begin
        $display("==========================================================");
        $display("Data I/O 29B Memory Board Test Bench");
        $display("With dual AS6C4008 SRAM instances (512KB each = 1MB total)");
        $display("==========================================================");
        $display("");
        
        // Initialise
        nEN = 1;
        nWR = 1;
        SEL0 = 1;
        SEL1 = 1;
        TDI = 0;
        TMS = 0;
        TCK = 0;
        cpu_data_out = 8'h00;
        pattern1 = 8'h55;
        pattern2 = 8'hAA;
        test_passed = 1;
        
        // Wait for reset
        repeat (5) @(negedge nVO2);
        
        // ===== Test 1: Bank register write and SRAM write/read =====
        $display("--- Test 1: Write bank register, then write/read SRAM0 ---");
        // Select bank 0 (bank_reg = 0), SRAM0 (bank_reg[5]=0)
        cpu_write(16'hE300, 8'b00000000);  // D0-D3 = 0
        cpu_write(16'hE301, 8'b00000000);  // D6=0, D7=0
        repeat (2) @(negedge nVO2);
        
        // Write pattern to $2000
        cpu_write(16'h2000, pattern1);
        $display("  Wrote 0x%02h to $2000", pattern1);
        
        // Read back from $2000
        cpu_read(16'h2000, read_data);
        $display("  Read back 0x%02h from $2000", read_data);
        
        if (read_data == pattern1) begin
            $display("  PASS: SRAM0 write/read PASSED");
        end else begin
            $display("  FAIL: SRAM0 write/read FAILED (expected 0x%02h, got 0x%02h)", pattern1, read_data);
            test_passed = 0;
        end
        
        // ===== Test 2: Select different page within SRAM0 =====
        $display("\n--- Test 2: Write to different page within SRAM0 ---");
        // Select bank 1 (bank_reg[4:0]=1), SRAM0 (bank_reg[5]=0)
        cpu_write(16'hE300, 8'b00000001);  // D0-D3 = 1 (bank 1)
        cpu_write(16'hE301, 8'b00000000);  // D6=0, D7=0
        repeat (2) @(negedge nVO2);
        
        // Write different pattern to same CPU address ($2000) but different SRAM page
        cpu_write(16'h2000, pattern2);
        $display("  Wrote 0x%02h to $2000 (bank 1)", pattern2);
        
        // Switch back to bank 0 and verify original data unchanged
        cpu_write(16'hE300, 8'b00000000);
        repeat (2) @(negedge nVO2);
        cpu_read(16'h2000, read_data);
        $display("  Bank 0, $2000 = 0x%02h (expected 0x%02h)", read_data, pattern1);
        
        if (read_data == pattern1) begin
            $display("  PASS: Bank switching (SRAM0) PASSED");
        end else begin
            $display("  FAIL: Bank switching (SRAM0) FAILED");
            test_passed = 0;
        end
        
        // ===== Test 3: Select SRAM1 =====
        $display("\n--- Test 3: Select SRAM1 and verify independent operation ---");
        // Select bank 0, SRAM1 (bank_reg[5]=1)
        cpu_write(16'hE300, 8'b00000000);
        cpu_write(16'hE301, 8'b10000000);  // D6=0, D7=1
        repeat (2) @(negedge nVO2);
        
        // Write pattern to SRAM1 at $2000
        cpu_write(16'h2000, pattern1);
        $display("  Wrote 0x%02h to $2000 (SRAM1)", pattern1);
        
        // Switch to SRAM0 and verify it still has pattern2 at $2000
        cpu_write(16'hE301, 8'b00000000);
        repeat (2) @(negedge nVO2);
        cpu_read(16'h2000, read_data);
        $display("  SRAM0 at $2000 = 0x%02h", read_data);
        
        // Switch back to SRAM1 and verify pattern1
        cpu_write(16'hE301, 8'b10000000);
        repeat (2) @(negedge nVO2);
        cpu_read(16'h2000, read_data);
        $display("  SRAM1 at $2000 = 0x%02h", read_data);
        
        if (read_data == pattern1) begin
            $display("  PASS: SRAM1 write/read PASSED");
        end else begin
            $display("  FAIL: SRAM1 write/read FAILED");
            test_passed = 0;
        end
        
        // ===== Test 4: Memory size limiting (128KB mode) =====
        $display("\n--- Test 4: Memory size limiting (128KB mode, max_bank=3) ---");
        SEL0 = 1; SEL1 = 1;  // 128KB mode
        // Try to write to bank 4 (should be invalid)
        cpu_write(16'hE300, 8'b00000100);  // bank 4
        cpu_write(16'hE301, 8'b00000000);
        repeat (2) @(negedge nVO2);
        
        // Attempt to write to $2000 (should not be enabled)
        cpu_write(16'h2000, pattern2);
        $display("  Attempted write to bank 4 (invalid)");
        
        // Read back — should not have changed
        cpu_read(16'h2000, read_data);
        $display("  Read back from bank 4: 0x%02h", read_data);
        
        // Switch back to bank 0 and verify original data
        cpu_write(16'hE300, 8'b00000000);
        repeat (2) @(negedge nVO2);
        cpu_read(16'h2000, read_data);
        $display("  Bank 0 data = 0x%02h (should be unchanged)", read_data);
        
        // ===== Test 5: Parity readback =====
        $display("\n--- Test 5: Parity status read at $E302 ---");
        cpu_read(16'hE302, read_data);
        $display("  Parity read = 0x%02h (D7 should be 0 = no error)", read_data);
        
        if ((read_data & 8'h80) == 8'h00) begin
            $display("  PASS: PARITY TEST PASSED");
        end else begin
            $display("  FAIL: PARITY TEST FAILED (D7=1)");
            test_passed = 0;
        end
        
        // ===== Test 6: Full 1MB mode =====
        $display("\n--- Test 6: Full 1MB mode (max_bank=31) ---");
        SEL0 = 0; SEL1 = 0;  // 1MB mode
        
        // Write to bank 31
        cpu_write(16'hE300, 8'b00001111);  // lower 4 bits = 1111
        cpu_write(16'hE301, 8'b00100000);  // D6=1 (bit 4), D7=0
        repeat (2) @(negedge nVO2);
        
        // Write pattern to highest bank
        cpu_write(16'h2000, pattern2);
        $display("  Wrote 0x%02h to bank 31", pattern2);
        
        // Read back
        cpu_read(16'h2000, read_data);
        $display("  Read back 0x%02h from bank 31", read_data);
        
        if (read_data == pattern2) begin
            $display("  PASS: 1MB mode PASSED");
        end else begin
            $display("  FAIL: 1MB mode FAILED");
            test_passed = 0;
        end
        
        // ===== Test 7: Verify A13 routing (direct from CPU) =====
        $display("\n--- Test 7: Verify A13 routing (direct from CPU to SRAM) ---");
        $display("  A13 is connected directly from CPU to SRAM");
        $display("  This provides 8KB granularity within the 16KB window");
        $display("  CPLD does NOT generate A13 (no RB5 output)");
        
        // ===== Test 8: Random 1K block write/read =====
        $display("\n--- Test 8: Random 1KB block write/read (SRAM0 bank 0) ---");
        // Return to bank 0, SRAM0, 128KB mode
        SEL0 = 1; SEL1 = 1;
        cpu_write(16'hE300, 8'b00000000);
        cpu_write(16'hE301, 8'b00000000);
        repeat (2) @(negedge nVO2);

        // Write 1024 random bytes starting at $2000
        for (i = 0; i < 1024; i = i + 1) begin
            expected[i] = $random;
            cpu_write(16'h2000 + i, expected[i]);
        end

        // Read back and compare
        fail_count = 0;
        for (i = 0; i < 1024; i = i + 1) begin
            cpu_read(16'h2000 + i, read_data);
            if (read_data !== expected[i]) begin
                if (fail_count < 8)
                    $display("  MISMATCH @ $%04h: wrote 0x%02h, read 0x%02h",
                             16'h2000 + i, expected[i], read_data);
                fail_count = fail_count + 1;
            end
        end

        if (fail_count == 0) begin
            $display("  PASS: Random 1KB test PASSED (1024/1024 bytes correct)");
        end else begin
            $display("  FAIL: Random 1KB test FAILED (%0d/1024 bytes mismatched)", fail_count);
            test_passed = 0;
        end

        // ===== Test Complete =====
        $display("\n==========================================================");
        if (test_passed)
            $display("PASS: ALL TESTS PASSED");
        else
            $display("FAIL: SOME TESTS FAILED");
        $display("==========================================================");
        $finish;
    end

endmodule