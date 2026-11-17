`default_nettype none

// Small, synchronous IPv4 longest-prefix-match router core.
//
// The core routes packet metadata rather than Ethernet bytes.  An Ethernet/
// MAC front end can attach to this interface and use out_drop to discard
// packets for which no route exists.
module ipv4_router #(
    parameter integer ROUTE_COUNT = 4
) (
    input  logic        clk,
    input  logic        rst,

    input  logic        cfg_valid,
    input  logic [((ROUTE_COUNT <= 1) ? 1 : $clog2(ROUTE_COUNT))-1:0] cfg_index,
    input  logic [31:0] cfg_prefix,
    input  logic [31:0] cfg_mask,
    input  logic [31:0] cfg_next_hop,
    input  logic        cfg_route_valid,

    input  logic        in_valid,
    output logic        in_ready,
    input  logic [31:0] in_dst_ip,

    output logic        out_valid,
    input  logic        out_ready,
    output logic [31:0] out_next_hop,
    output logic        out_drop
);
    localparam integer INDEX_WIDTH = (ROUTE_COUNT <= 1) ? 1 : $clog2(ROUTE_COUNT);

    logic [31:0] route_prefix [0:ROUTE_COUNT-1];
    logic [31:0] route_mask [0:ROUTE_COUNT-1];
    logic [31:0] route_next_hop [0:ROUTE_COUNT-1];
    logic route_valid [0:ROUTE_COUNT-1];

    logic match_found;
    logic [31:0] selected_next_hop;
    integer selected_prefix_length;
    integer prefix_length;
    integer i;

    assign in_ready = ~out_valid | out_ready;

    // A route with the most set mask bits wins.  Iterating from low to high
    // index makes the lowest index the deterministic tie breaker.
    always_comb begin
        match_found = 1'b0;
        selected_next_hop = 32'b0;
        selected_prefix_length = -1;

        for (i = 0; i < ROUTE_COUNT; i = i + 1) begin
            prefix_length = $countones(route_mask[i]);
            if (route_valid[i] &&
                ((in_dst_ip & route_mask[i]) == (route_prefix[i] & route_mask[i])) &&
                (prefix_length > selected_prefix_length)) begin
                match_found = 1'b1;
                selected_next_hop = route_next_hop[i];
                selected_prefix_length = prefix_length;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_next_hop <= 32'b0;
            out_drop <= 1'b0;
            for (i = 0; i < ROUTE_COUNT; i = i + 1) begin
                route_prefix[i] <= 32'b0;
                route_mask[i] <= 32'b0;
                route_next_hop[i] <= 32'b0;
                route_valid[i] <= 1'b0;
            end
        end else begin
            if (cfg_valid && (cfg_index < ROUTE_COUNT)) begin
                route_prefix[cfg_index] <= cfg_prefix;
                route_mask[cfg_index] <= cfg_mask;
                route_next_hop[cfg_index] <= cfg_next_hop;
                route_valid[cfg_index] <= cfg_route_valid;
            end

            if (in_ready) begin
                out_valid <= in_valid;
                if (in_valid) begin
                    out_next_hop <= selected_next_hop;
                    out_drop <= ~match_found;
                end
            end
        end
    end
endmodule

`default_nettype wire
