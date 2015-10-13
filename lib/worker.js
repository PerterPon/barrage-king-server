
/*
  worker
  Author: PerterPon<PerterPon@gmail.com>
  Create: Wed Aug 12 2015 09:02:40 GMT+0800 (CST)
*/

"use strict";

require( 'coffee-script' ).register();

var app = process.argv[ 2 ];

var engine = require( './engine' );

try {
  engine.start( app );
} catch( e ) {
  console.log( e.message );
  console.log( '----------' );
  console.log( e.stack );
}
