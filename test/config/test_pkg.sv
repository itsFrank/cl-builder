package test_pkg; 

    typedef logic [31:0]    t_uint32;
    typedef logic [63:0]    t_uint64;
    
    typedef union packed {
        logic [511:0] cl;
        t_uint32 [15:0] u32;
        t_uint64 [7:0] u64;
    } t_cl;

    function real abs(real v);
        if (v < 0) v = v * -1.0;
        return v; 
    endfunction

    function real max(real v, real w);
        if (v > w) return v;
        return w; 
    endfunction

    function logic floatEq(real v, logic [31:0] b);
        // $display("v %f", v);
        // $display("b %f", $bitstoshortreal(b));
        // $display("diff %f vs %f", abs(v - $bitstoshortreal(b)), 0.0000001 *  max(abs(v), abs($bitstoshortreal(b))));
        return (abs(v - $bitstoshortreal(b) < 0.0000001 *  max(abs(v), abs($bitstoshortreal(b)))));
    endfunction

    function automatic logic [31:0] toFloat(real v);
        return $shortrealtobits(v); 
    endfunction

    function automatic real toReal(logic [31:0] v);
        return $bitstoshortreal(v); 
    endfunction
endpackage