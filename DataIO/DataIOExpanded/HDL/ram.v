//=====================================================================
// AS6C4008 Behavioral Model
// 512K x 8 SRAM (4 Mbit)
// Compatible with: AS6C4008-55PCN, IS62WV5128, etc.
//=====================================================================

module as6c4008 (
    input  wire       CE_n,    // Chip enable (active low)
    input  wire       OE_n,    // Output enable (active low)
    input  wire       WE_n,    // Write enable (active low)
    input  wire [18:0] A,      // Address lines A0-A18 (512K addresses)
    inout  wire [7:0] DQ       // Data bus
);

    // Memory array: 512K x 8 = 4,194,304 bits
    reg [7:0] mem [0:524287];
    
    // Tri-state control for data bus
    wire read_enable  = !CE_n && !OE_n && WE_n;
    wire write_enable = !CE_n && !WE_n;

    // Combinatorial read — output tracks address instantly while selected
    assign DQ = read_enable ? mem[A] : 8'bzzzzzzzz;

    // Level-sensitive write — data captured continuously while CE# and WE# are low
    always @(write_enable or A or DQ) begin
        if (write_enable)
            mem[A] = DQ;
    end
    
    // Initialization (optional — loads known pattern for testing)
    integer i;
    initial begin
        for (i = 0; i < 524287; i = i + 1)
            mem[i] = 8'hFF;  // Initialize to 0xFF
        $display("AS6C4008 SRAM model initialized: 512K x 8");
    end

endmodule