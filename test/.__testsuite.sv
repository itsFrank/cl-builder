module __testsuite;
  import svunit_pkg::svunit_testsuite;

  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  CL_BUILDER_unit_test CL_BUILDER_ut();


  //===================================
  // Build
  //===================================
  function void build();
    CL_BUILDER_ut.build();
    svunit_ts = new(name);
    svunit_ts.add_testcase(CL_BUILDER_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    CL_BUILDER_ut.run();
    svunit_ts.report();
  endtask

endmodule
