`timescale 1ns/1ps
`default_nettype none

module ipv4_router_tb;
    logic clk = 1'b0;
    logic rst = 1'b1;
    logic cfg_valid = 1'b0;
    logic [1:0] cfg_index = 2'b0;
    logic [31:0] cfg_prefix = 32'b0;
    logic [31:0] cfg_mask = 32'b0;
    logic [31:0] cfg_next_hop = 32'b0;
    logic cfg_route_valid = 1'b0;
    logic in_valid = 1'b0;
    logic in_ready;
    logic [31:0] in_dst_ip = 32'b0;
    logic out_valid;
    logic out_ready = 1'b1;
    logic [31:0] out_next_hop;
    logic out_drop;

    ipv4_router dut (.*);

    always #5 clk = ~clk;

    task automatic configure(
        input logic [1:0] index,
        input logic [31:0] prefix,
        input logic [31:0] mask,
        input logic [31:0] next_hop
    );
        begin
            @(negedge clk);
            cfg_valid = 1'b1;
            cfg_index = index;
            cfg_prefix = prefix;
            cfg_mask = mask;
            cfg_next_hop = next_hop;
            cfg_route_valid = 1'b1;
            @(negedge clk);
            cfg_valid = 1'b0;
        end
    endtask

    task automatic route(
        input logic [31:0] destination,
        input logic [31:0] expected_hop,
        input logic expected_drop
    );
        begin
            @(negedge clk);
            in_dst_ip = destination;
            in_valid = 1'b1;
            @(posedge clk);
            #1;
            if (!out_valid || out_next_hop !== expected_hop || out_drop !== expected_drop) begin
                $fatal(1, "unexpected route for %h: valid=%b hop=%h drop=%b",
                       destination, out_valid, out_next_hop, out_drop);
            end
            @(negedge clk);
            in_valid = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 1'b0;
        configure(2'd0, 32'h0a000000, 32'hff000000, 32'hc0a80101);
        configure(2'd1, 32'h0a010000, 32'hffff0000, 32'hc0a80102);

        route(32'h0a01002a, 32'hc0a80102, 1'b0);
        route(32'h0a02002a, 32'hc0a80101, 1'b0);
        route(32'hac100001, 32'h00000000, 1'b1);

        $display("ipv4_router_tb: PASS");
        $finish;
    end
endmodule

`default_nettype wire
