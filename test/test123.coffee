


module.exports = () ->
  middleware : () ->
    ( req, res, next ) =>
      res.__test = '123'
      next()
      # res.end '123:' + process.pid
