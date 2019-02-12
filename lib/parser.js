//Parse bundles into a single struct of all action control functions
//Copyright WyattERP.org; See license in root of this package
// ----------------------------------------------------------------------------

module.exports = function(actions, bundles) {
  bundles.forEach(bundle=>{
    for (let view in bundle) {
      if (!(view in actions)) actions[view] = {}
      Object.assign(actions[view], bundle[view])
    }
  })
}
