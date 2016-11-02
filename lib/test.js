
/*
  test
  Author: yuhan.wyh<yuhan.wyh@alibaba-inc.com>
  Create: Wed Nov 02 2016 12:05:47 GMT+0800 (CST)
*/

"use strict";

class Test {

  middleware() {
    return function *( req, res, next ) {

      res.end( 'hello world!' );
    }
  }

}

module.exports = () => {
  return new Test();
}
