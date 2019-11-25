module __testsuite;
  import svunit_pkg::svunit_testsuite;

  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  cl_builder_unit_test cl_builder_ut();


  //===================================
  // Build
  //===================================
  function void build();
    cl_builder_ut.build();
    svunit_ts = new(name);
    svunit_ts.add_testcase(cl_builder_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    cl_builder_ut.run();
    svunit_ts.report();
  endtask

endmodule
