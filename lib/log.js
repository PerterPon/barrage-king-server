
/*
  log
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Mon Nov 21 2016 03:56:23 GMT+0800 (CST)
*/

"use strict";

const JustLog = require( 'justlog' );

const common  = require( './common' );

let log = null;

class Log {

  constructor() {
    const config  = common.getConfig();
    let logDir    = config.log_dir;
    let logIns    = null;
    if ( void( 0 ) == logDir ) {
      logDir     = process.cwd();
    }

    if ( process.env.NODE_ENV && 'dev' !== process.env.NODE_ENV ) {
      logIns = JustLog( {
        file : {
          level : JustLog.ERROR | JustLog.INFO | JustLog.WARN,
          path  : config.justlogPath,
        }
      } );
        
    } else {
      logIns = console;
    }
    return logIns;
  }

}

module.exports = () => {
  if ( null === log ) {
    log = new Log();
  }
  return log;
};
