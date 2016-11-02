
# /*
#   Author: yuhan.wyh@alibaba-inc.com
#   Create: Sat Jan 31 2015 14:38:06 GMT+0800 (CST)
# */
# 

"use strict"

fs        = require 'fs'
co        = require 'co'
os        = require 'options-stream'
tool      = require './util'
path      = require 'path'
unify     = require './unify'
cover     = require 'node-cover'
urlLib    = require 'url'
justlog   = require 'justlog'
connect   = require 'connect'
thunkify  = require 'thunkify'
coverRouter = require 'cover-router'

class App

  routers : []

  constructor : ( options, @log ) ->
    @log    ?= console
    @options = os
      dir : ''
    , options

    # get app config
    config   = @_getAppCfg()
    @config  = config
    console.log config
    return if undefined is config

    # generator server
    @serverConfig = os
      run        :
        development : true
      serverPath : __dirname
    , options.serverConfig
    @development = @serverConfig.run.development in [ true, 'true' ]
    { name, version } = config
    # generate sock file path
    basePath     = process.cwd()
    folderPath   = if true is @development then '/' else '../../'
    filePath     = "run/#{ encodeURIComponent name }@#{ version }-#{ process.pid }.sock"
    # sock         = path.join basePath, folderPath, filePath
    sock         = 4239
    config.sock  = sock

    @app         = @_generatorServer()

    @app.on 'error', @_errHandle.bind @

    @app.use ( req, res, next ) ->
      yield next
      if true is res.writable
        res.statusCode = 404
        res.end "Can Not Find: #{req.url}"

    # on exit
    process.on 'exit', ->
      fs.unlinkSync sock if fs.existsSync sock

    # @run()
    return undefined

  _getAppCfg : ->
    { options, log } = @
    { dir } = options
    if false is fs.existsSync dir
      @err  = new Error 'App File NOT Found: ' + JSON.stringify options
      log.error @err
      return undefined
    config  = tool.getAppconfig dir

    if undefined is config
      @err  = new Error 'Read App Config Error: ' + JSON.stringify options
      log.error @err
      return undefined
    config

  # _getPrefixes : ( urls ) ->
  #   urlMap   = {}
  #   for url in urls
  #     { pathname } = urlLib.parse url, true
  #     urlMap[ pathname ] = true
  #   Object.keys urlMap    

  _generatorServer : ->
    app = cover()

  _init : co.wrap ( cb ) ->
    { config, options } = @
    return cb() if undefined is config
    { dir }       = options
    { initFiles } = config
    return cb() if not initFiles or 0 is Object.keys( initFiles ).length
    try
      for file, val of initFiles
        modPath   = path.join dir, file
        module    = require modPath
        modIns    = module val
        { ready } = modIns
        continue unless ready?
        readyFn   = thunkify ready
        yield readyFn()
    catch e
    finally
      cb e

  _initLog : ->
    { dir, logPath, logsDir } = @options
    { name } = @config
    log = console
    { development }  = @
    if false is development and logPath?
      log = justlog
        file  : 
          level   : justlog.ERROR | justlog.INFO | justlog.WARN
          path    : logPath
          pattern : "{fulltime} ({file}) [{levelTrim}] {action} {info}"
        stdio : false
      middlewareLog = justlog.middleware
        file  :
          path : "[#{path.join logsDir, 'access'}-]YYYY-MM-DD[.log]"
        stdio : false
      appAccess = justlog.middleware
        file :
          path : "[#{path.join logsDir, name + '-access'}-]YYYY-MM-DD[.log]"
        stdio: false
    log.log = log.info
    { log, middlewareLog, appAccess }

  _useMiddlewares : co.wrap ( lists ) ->
    { log, middlewareLog, appAccess } = @_initLog()
    @_doUseMiddleware '/', appAccess,     undefined, false if appAccess
    @_doUseMiddleware '/', middlewareLog, undefined, false if appAccess

    { serverConfig, options } = @
    { dir } = options

    for item, idx in lists
      { module, pathname, method, fmethod } = item
      if undefined in [ module, pathname ]
        @log.warn "WARN: Wrong middleware Config, module and pathname is necessary: #{JSON.stringify k}"
        continue
      delete item.module
      delete item.pathname

      if item.options?._hc_config
        { _hc_config } = item.options
        if 'object' is typeof _hc_config
          for one, val of _hc_config
            item.options[ one ] = serverConfig[ val ]
        else
          item.options  = os serverConfig[ _hc_config ], item.options

      # 如果是自有中间件
      if /.*\.\/.*/.test module
        file = path.join dir, module
      # 如果是connect 中间件
      else if /^connect\.(.*)/.test module
        { $1:connectModule } = RegExp
        # connectModule = RegExp.$1
        if connect?[ connectModule ]
          userModule  = connect[ connectModule ]
        else
          @_errHandle new Error "\'#{module}\' is not exists!"
          break

        # todo yamljs 暂不支持直接书写function，所以middleware的参数暂不支持function
        try
          @_doUseMiddleware pathname, userModule( item.options ), undefined, true
        catch e
          @_errHandle e
          break
        continue
      # 第三方npm的中间件和容器扩展的中间件
      else
        file = path.join dir, '/node_modules/', module
      try
        userModule = require file
      catch e
        @_errHandle e
        break

      options = os 
        _ws_http     : @app.http
        _app_dir     : @options.dir
        development  : @development
        _addRouter   : ( cmd, middleware ) =>
          return @defaultMiddle = middleware if 'loader' is cmd
          @routers.push { cmd, middleware }
      , item.options

      log = process?.honeycomb?.log or log
      options.log = log

      try
        user   = unify userModule, fmethod, options, log, { options: item.options }
      catch e
        @_errHandle e
        break
      
      golbal = if user.get then user.get() else user
      process.honeycomb ?= {}
      process.honeycomb[ module ] = golbal
      process.honeycomb[ options.__nickname ] = golbal if options.__nickname

      { before } = user
      if before? and 'function' is typeof before
        beforeFn = thunkify before
        try
          yield beforeFn()
          @_routerMiddleware pathname, options, user, method
        catch e
          @_errHandle e
          break
      else
        @_routerMiddleware pathname, options, user, method

  _routerMiddleware: ( pathname, options = {}, user, method ) ->

    #子路由
    subRouters = tool.normalSubExtension options.__routers, method
    for v in subRouters
      p = path.join pathname, v.pathname
      submethod = v.method
      func = v.to
      if false is tool.checkContain method, submethod
        return @_errHandle new Error "Method Conflicts: #{JSON.stringify(subRouter: v, method: method)}"
      try
        middlewareFn = user[func]()
      catch e
        { message }  = e
        errorMessage = "load:\"#{pathname}\" router:\"#{func}\" middleware error: #{message}"
        @_errHandle new Error errorMessage
      @_doUseMiddleware p, middlewareFn, submethod, undefined, true if user[func]
    @_doUseMiddleware pathname, user.middleware(), method if user.middleware

  _doUseMiddleware: ( pathname = '/', middleware, method, needPrefix, subRouter = false ) ->
    { prefixes, app } = @

    detailUrl = pathname

    # default to all kind of method
    method     ?= 'all'
    app.use coverRouter[ method ] detailUrl, middleware, { strongMatch : subRouter }

  _errHandle : ( err ) ->
    @log.error err.stack
    @err = err

  run : ( cb ) ->
    config = @config or {}
    return cb @err if @err

    { sock } = config
    @_init ( err ) =>
      return cb err if err
      extensions = tool.normalExtension config
      console.log extensions
      @_useMiddlewares extensions        
      return cb @err if @err
      @app.listen sock, =>
        cb? null, config

  defaultMiddle : ->

module.exports = ( options, log ) ->
  new App options, log
