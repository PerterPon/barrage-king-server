 # middleware.coffee
 # honeycomb - lib/woerker/app.coffee
 # Copyright(c) 2014 Taobao.com
 # Author: jifeng.zjd <jifeng.zjd@taobao.com>

checkDirectMiddleware = (code)->
  code = code || ''
  start = code.indexOf '('
  end = code.indexOf ')'
  return false if start is -1 or end is -1
  params = code.substring start + 1, end
  arr = params.split ','
  return arr.length >= 3

unify = (userModule, fmethod, options, log, args)->
  originOptions = args.options
  str = userModule.toString()
  user = undefined
  # only file
  if fmethod is undefined
    if checkDirectMiddleware(str) 
      user = 
        middleware: ()->
          userModule
  # file method
  else
    #exports.a, exports.b
    if '[object Object]' is str
      submethod = userModule[fmethod]
      fmethodStr = submethod.toString()
      if checkDirectMiddleware(fmethodStr) 
        user = 
          middleware: ()->
            userModule[fmethod]
      else
        user = 
          middleware: ()->
            userModule[fmethod] options
  user = userModule(options, log) if user is undefined
  user

module.exports = unify
