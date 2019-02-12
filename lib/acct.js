//Action control function handlers
//Copyright WyattERP.org; See license in root of this package
// ----------------------------------------------------------------------------
//TODO:
//- Make actual action handlers rather than placeholders
//- 

// ----------------------------------------------------------------------------
function func1(info, cb, resource) {
  let error
  log.debug('Calling func1', data)
  cb(error)
  return false
}

// ----------------------------------------------------------------------------
function func2(data, cb, resource) {
  let error
  log.debug('Calling func2', data)
  cb(error)
  return false
}

module.exports = {
  'acct.acct_v': {func1, func2},
  'acct.proj_v': {func1, func2},
}
