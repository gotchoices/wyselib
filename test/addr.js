//Test address tables
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
var PrimSql = "select addr_seq,addr_type,addr_cmt,addr_prim from base.addr_v where addr_ent = 'o100' and addr_type = 'ship' and addr_prim;"

describe("Test DB address schema", function() {
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
      INSERT INTO base.addr
          (addr_ent, addr_seq, addr_spec, addr_type, addr_prim, addr_cmt, addr_inact, city, state, pcode, country) 
        VALUES ('o100', 1, '2345 Corporate Way', 'ship', true, 'Headquarters', false, 'Bigtown', 'NY', '12345', 'US')
          , ('o100', 2, '5432 Back Way', 'ship', false, 'Alternate Plant', false, 'Littletown', 'NM', '23456', 'US')
          , ('o100', 3, '6543 Side Way', 'ship', false, 'Job Site', false, 'Sometown', 'CA', '34567', 'US')
          , ('o100', 4, 'PO Box 4567', 'bill', true, 'Mailing address', false, 'Bigtown', 'Ny', '12345-4567', 'US');`
    db.query(sql, null, (e, res) => {if (e) done(e)
      assert.equal(res.length, 2)		//ent, addr
log.debug('res:', res[0].rows[0])
      assert.equal(res[0].rowCount, 1)
      assert.equal(res[0].rows[0].id, 'o100')
      assert.equal(res[1].rowCount, 4)
      done()
    })
  })

  it('should mark correct record as primary', function(done) {
    db.query(PrimSql, (e, res) => {if (e) done(e)
      assert.equal(res.rows.length, 1)
      assert.equal(res.rows[0].addr_seq, 1)
      done()
    })
  })

  it('can change primary record', function(done) {
    let sql = `update base.addr_v set addr_prim = true where addr_ent = 'o100' and addr_seq = 2; ${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res[1].rows.length, 1)
      assert.equal(res[1].rows[0].addr_seq, 2)
      done()
    })
  })

  it('setting inactive moves primary away from record', function(done) {
    let sql = `update base.addr_v set addr_inact = true where addr_ent = 'o100' and addr_type = 'ship' and addr_seq < 3; ${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res[1].rows.length, 1)
      assert.equal(res[1].rows[0].addr_seq, 3)
      done()
    })
  })

  it('attempt to clear primary fails', function(done) {
    let sql = `update base.addr_v set addr_inact = false where addr_ent = 'o100';
               update base.addr_v set addr_prim = false where addr_ent = 'o100' and addr_seq = 3;${PrimSql}`
    db.query(sql, (e, res) => {if (e) done(e)
log.debug('res:', res)
      assert.equal(res.length, 3)
      assert.equal(res[2].rows.length, 1)
      assert.equal(res[2].rows[0].addr_seq, 3)
      done()
    })
  })

  after('Disconnect from test database', function(done) {
    db.disconnect()
    done()
  })
})
