
/*
  barrage
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Tue Nov 22 2016 08:02:40 GMT+0800 (CST)
*/

"use strict";

class Barrage {

  constructor() {
    
  }

  onMessage( event ) {
    const utf8Data = event;
    this.connection.send( process.pid );
  }

}

module.exports = ( options ) => {
  return new Barrage( options );
};
