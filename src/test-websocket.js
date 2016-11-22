
/*
  test
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Wed Nov 16 2016 12:20:36 GMT+0800 (CST)
*/

"use strict";

class Test {

  constructor( connection ) {
    this.connection = connection;
  }

  onMessage( event ) {
    this.connection.send( process.pid );
  }

}

module.exports = Test;

