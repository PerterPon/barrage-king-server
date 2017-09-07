
/*
  barrage
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Tue Nov 22 2016 08:02:40 GMT+0800 (CST)
*/

"use strict";

const log = require( '../lib/log' )();

const addressPool = {};

const validMethod = [ 'register' ];

const LIMIT_TIME  = 5 * 1000;

class Barrage {

  constructor() {
    // current websocket connection
    this.connection = null;
  }

  onMessage() {
    return ( event ) => {
      let data = null;
      if ( 'utf8' === event.type ) {
        data = event.utf8Data;
      } else {

      }

      let barrage   = null;

      try {
        barrage     = JSON.parse( data );
        let method  = barrage.method;
        let barrageData = barrage.data;
        if ( -1 > validMethod.indexOf( method ) ) {
          let error = new Error( `invalid method` );
          throw error;
        }

        let ins     = this[ method ];
        ins.call( this, barrageData );
      } catch ( e ) {
        let error = new Error( `parse data with error!` );
        log.error( error.message );
        self.send( error );
      }
    }
  }

  send( data ) {
    let resData;
    if ( true === ( data instanceof Error ) ) {
      resData = {
        success : false,
        message : error.message
      };
    } else {
      resData = {
        success : true,
        data    : data
      };
    };

    this.connection.send( JSON.stringify( resData ) );
  }

  register( data ) {
    let address = data.address;
    let addresses = addressPool[ address ];
    if ( void( 0 ) == addresses ) {
      addresses = {};
      addressPool[ address ] = addresses;
    }

    let hcName  = this.connection.hcName;
    addresses[ hcName ] = this.connection;
  }

  barrage( data ) {
    let lastBarrageTime = this.connection.lastBarrageTime;
    if ( void( 0 ) == lastBarrageTime ) {
      this.connection.lastBarrageTime = Date.now();
    }

    let now = Date.now();

    if ( now - lastBarrageTime <= LIMIT_TIME ) {
      let error = new Error( '发送太频繁' );
      this.send( error );
      return;
    }

    this.connection.lastBarrageTime = new Date();
    let address   = data.address;
    let barrage   = data.barrage;
    let addresses = addressPool[ address ] || {};

    for ( let name in addresses ) {
      let connection = addresses[ name ];
      this.send( barrage );
    }
  }

}

module.exports = Barrage;
