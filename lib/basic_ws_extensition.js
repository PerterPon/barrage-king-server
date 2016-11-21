
/*
  basic_ws_extensition
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Wed Nov 16 2016 12:21:38 GMT+0800 (CST)
*/

"use strict";

const co       = require( 'co' );

const thunkify = require( 'thunkify' );

class BasicWsExtensition {

  constructor( connection, options ) {
    this.connection = connection;
    this.options    = options;

    connection.on( 'message', function ( event ) {
      
    } );
  }

}

module.exports = BasicWsExtensition;
