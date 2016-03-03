var assert = require('chai').assert;
var universe = require('../src/universe');
var system = require('../src/system');

describe('system', function() {
  this.timeout(0);
  
  var System;

  before('setup universe', function(done) {
    var u = universe(web3);
    u.createUniverse().then(function(galaxy) {
      System = system(web3, galaxy);
      done();
    });
  })

  describe('#empty systems', function() {
    var tauceti;

    before('create empty system', function() {
      tauceti = new System("tauceti");
    });

    it('has a name', function() {
      assert.equal(tauceti.name, "tauceti");
    });

    it('has the right hash', function() {
      assert.equal(tauceti.hash, "0x69807b079150d6528543919a437c8090cc59608e48ff072186c2edbc469c6cb1");
    }); 

    it('has nothing in the map', function() {
      assert.deepEqual(tauceti.map, Array.from({length: 256}, () => 0));
    });
  });

  describe('#created system', function() {
    var polaris;
    
    before('create polaris', function(done) {
      polaris = new System('polaris');
      polaris.create().then(function() {done()});
    });

    it.only('is identical to itself', function() {
      var polaris2 = new System(polaris.name);
      assert.deepEqual(polaris.map, polaris2.map);
    });

    it.skip('doesn\'t have an empty map', function() {
      // TODO: Set this to the actual map.
      assert.notDeepEqual(polaris.map, Array.from({length: 256}, () => 0));
    });
  })
});
