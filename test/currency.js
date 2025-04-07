//Test for known currencies
//Copyright WyattERP.org; See license in root of this package
// -----------------------------------------------------------------------------
// TODO
//- 
const assert = require("assert");
const Fs = require('fs')
const Path = require('path')
const Fetch = require('node-fetch')
const exchangeURL = "https://open.er-api.com/v6/latest/USD"

//const Child = require('child_process')
const { TestDB, DBAdmin, DBHost, DBPort, Log, DbClient } = require('./settings')
const dbConfig = {database: TestDB, user: DBAdmin, connect: true, host: DBHost, port: DBPort}
var log = Log('test-currency')
var interTest = {}

describe("Test installed currencies", function() {
  var db

  before('Connect to schema database', function(done) {
    db = new DbClient(dbConfig, ()=>{}, ()=>{
      log.debug("Connected to DB");
      done()
    })
  })

  it('Fetch currency exchange data', function(done) {
    this.timeout(4000)
    Fetch(exchangeURL).then(res => res.json()).then(json => {
      assert.equal(json.result, 'success')
      interTest.json = json
      done()
    })
  })

  it('check for uninstalled currencies', function(done) {
    let sql = `with ex as (select * from jsonb_each($1))
      select ex.key as code, ex.value::numeric as rate, c.cur_code
        from ex left join base.currency c on c.cur_code = ex.key
        where c.cur_code isnull`
log.debug("Sql:", sql)
    db.query(sql, [interTest.json.rates], (e, res) => {if (e) done(e)
      let rows = res?.rows		//;log.debug("rows:", rows)
      if (rows.length > 0) {
        log.debug('Uninstalled currencies:', rows.map(el=>el.code).join(','))
        log.debug('See: https://en.wikipedia.org/wiki/ISO_4217')
      }
      assert.equal(rows.length, 0)
      done()
    })
  })
/* */
  after('Disconnect from test database', function(done) {
    db.disconnect()
    done()
  })
})
