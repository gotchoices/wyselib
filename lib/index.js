//Copyright WyattERP.org; See license in root of this package
// ----------------------------------------------------------------------------

var actions = {}
const Parser = require('./parser')

Parser(actions, ['./acct', './base'].map(f=>require(f)))

//console.log("Wyselib actions", actions)
module.exports = {
  actions,
  Parser
}
