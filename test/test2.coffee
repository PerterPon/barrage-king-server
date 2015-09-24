
module.exports = ->
  middleware : () ->
    ( req, res, next ) ->
      res.end res.__test
