//Test communication tables
//Copyright WyattERP.org; See license in root of this package
// -----------------------------------------------------------------------------
// TODO
//- 
const assert = require("assert");
const Fs = require('fs')
const Path = require('path')
const Child = require('child_process')
const { TestDB, DBAdmin, Log, DbClient, SchemaDir, SchemaFile, WmItems } = require('./settings')
const dbConfig = {database: TestDB, user: DBAdmin, connect: true}
var log = Log('test-schema')
var PrimSql = "select comm_seq,comm_type,comm_cmt,comm_prim from base.comm_v where comm_ent = 'o100' and comm_type = 'phone' and comm_prim;"

describe("Test DB communication schema", function() {
  var db

  before('Connect to schema database', function(done) {
    db = new DbClient(dbConfig, ()=>{}, ()=>{
      log.debug("Connected to DB");
      done()
    })
  })

  it('delete any users other than admin', function(done) {
    let sql = "delete from base.ent where id != 'r1'"
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.ok(!e)
      done()
    })
  })

  it('insert sample user with addresses', function(done) {
    let sql = `INSERT INTO base.ent (ent_num, ent_type, ent_name, born_date, country, tax_id)
        VALUES (100, 'o', 'Ahoy Chips', '2017-01-01', 'US', '234-56-7890') returning id;
      INSERT INTO base.comm (comm_ent, comm_seq, comm_spec, comm_type, comm_prim, comm_cmt, comm_inact)
        VALUES ('o100', 1, '901-346-6789', 'phone', false, 'Main', false)
        , ('o100', 2, '800-555-5555', 'phone', false, 'Customer Service', false)
        , ('o100', 3, 'info@ahoy.chip', 'email', false, NULL, false)
        , ('o100', 4, 'www.ahoy.chip', 'web', false, NULL, false)
        , ('o100', 5, '1234', 'phone', false, NULL, false)
        , ('o100', 6, '12345', 'phone', false, NULL, true);`
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.length, 2)		//ent, addr
log.debug('res:', res[0].rows[0])
      assert.equal(res[0].rowCount, 1)
      assert.equal(res[0].rows[0].id, 'o100')
      assert.equal(res[1].rowCount, 6)
      done()
    })
  })

  it('should mark correct record as primary', function(done) {
    db.query(PrimSql, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 1)
      assert.equal(res.rows[0].comm_seq, 1)
      done()
    })
  })

  it('can change primary record', function(done) {
    let sql = `update base.comm_v set comm_prim = true where comm_ent = 'o100' and comm_seq = 2; ${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res[1].rows.length, 1)
      assert.equal(res[1].rows[0].comm_seq, 2)
      done()
    })
  })

  it('setting inactive moves primary away from record', function(done) {
    let sql = `update base.comm_v set comm_inact = true where comm_ent = 'o100' and comm_type = 'phone' and comm_seq < 5; ${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res[1].rows.length, 1)
      assert.equal(res[1].rows[0].comm_seq, 5)
      done()
    })
  })

  it('attempt to clear primary fails', function(done) {
    let sql = `update base.comm_v set comm_inact = false where comm_ent = 'o100';
               update base.comm_v set comm_prim = false where comm_ent = 'o100' and comm_seq = 5;${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res.length, 3)
      assert.equal(res[2].rows.length, 1)
      assert.equal(res[2].rows[0].comm_seq, 5)
      done()
    })
  })

  after('Disconnect from test database', function(done) {
    db.disconnect()
    done()
  })
})
