{"changed":true,"filter":false,"title":"galaxy.sol","tooltip":"/dapp/contracts/galaxy.sol","value":"import \"std.sol\";\nimport \"../_pre/shiplib.sol\";\n\n///@title The Impermanence of Space: Galaxy Contract.\ncontract Galaxy is named(\"Galaxy\") {\n\n    /*enum TechTypes {\n        Atk,\n        Def,\n        Eng\n    }*/\n    \n    enum SectorType {\n        Empty,\n        AtkAsteriod,\n        DefAsteriod,\n        EngAsteriod,\n        AtkMonolith,\n        DefMonolith,\n        EngMonolith,\n        UnobRift,\n        AtkGreatMachine,\n        DefGreatMachine,\n        EngGreatMachine,\n        Planet,\n        Sun,\n        Wormhole,\n        AscensionGate\n    }\n    \n    struct Sector {\n        SectorType st;\n        uint8 mine;\n        uint[] sectorShips;\n    }\n    \n    struct System {\n        Sector[15][15] map;\n        string name;\n        uint[3] techLevels;\n        bool exists;\n        mapping (uint8 => bytes32) Wormholes;\n    }\n    \n    ///@dev convert an array of uints into a single uint. \n    function compressCoords(uint8[2] coords) constant returns (uint8)\n    {\n        return coords[0] + (coords[1] * 16);\n    }\n    \n    function decompressCoords(uint8 compressedCoords) \n        constant \n        returns (uint8 x, uint8 y)\n    {\n        y = compressedCoords / 16;\n        x = compressedCoords % 16;\n    }\n    \n    mapping (bytes32 => System) public galacticMap;\n    \n    // And now for a zillion helper functions. Recursive structs and \n    // getters do not mix. The good news is that calls are free.\n    \n    function getSectorType(bytes32 s, uint8 x, uint8 y) \n        constant \n        returns (SectorType) \n    {\n        return galacticMap[s].map[x][y].st;\n    }\n    \n    function getWormhole(bytes32 s, uint8[2] coords) \n        constant\n        returns (bytes32)\n    {\n        return galacticMap[s].Wormholes[compressCoords(coords)];\n    }\n\n    function getSectorShipsLength(bytes32 s, uint8 x, uint8 y)\n        constant \n        returns (uint) \n    {\n        return galacticMap[s].map[x][y].sectorShips.length;   \n    }\n\n    function getSectorShip(bytes32 s, uint8 x, uint8 y, uint i)\n        constant \n        returns (uint) \n    {\n        return galacticMap[s].map[x][y].sectorShips[i];\n    }\n\n    function Galaxy() {\n        // This is a kludge to get the address of the Galaxy.\n        log0(\"A new galaxy is born!\");\n        // 0 is no ship.\n        nextShip = 1;\n    }\n\n    event systemAdded(bytes32 indexed _systemHash);\n\n    function addSystem(string _name) {\n        // Hack alert!\n        bytes32 systemHash = sha3(_name);\n        System newSystem = galacticMap[systemHash];\n        newSystem.name = _name;\n        newSystem.exists = true;\n        generateMap(systemHash);\n        systemAdded(systemHash);\n        //galacticMap.push(newSystem);\n    }\n    \n    // We want the hash, not a pointer, because we need the hash as a seed.\n    function generateMap(bytes32 systemHash) internal {\n        System newSystem = galacticMap[systemHash];\n        newSystem.map[7][7].st = SectorType.Sun;\n        uint256 seed = uint256(systemHash);\n        uint8 x;\n        uint8 y;\n        uint8 newST;\n        for(uint8 i = 0; i < 16; i++) {\n            x = uint8(seed % 16);\n            seed /= 16;\n            y = uint8(seed % 16);\n            seed /= 16;\n            newST = uint8(seed % 16);\n            seed /= 256;\n            if((x == 15) || (y == 15)) {\n                continue; // We're off the map.\n            } else {\n                Sector chosenSector = newSystem.map[x][y];\n                if(chosenSector.st != SectorType.Empty) continue;\n                if(newST <= 2) {\n                    chosenSector.st = SectorType.AtkAsteriod;\n                } else if (newST <= 5) {\n                    chosenSector.st = SectorType.DefAsteriod;\n                } else if (newST <= 8) {\n                    chosenSector.st = SectorType.EngAsteriod;\n                } else if (newST == 9) {\n                    chosenSector.st = SectorType.AtkMonolith;\n                } else if (newST == 10) {\n                    chosenSector.st = SectorType.DefMonolith;\n                } else if (newST == 11) {\n                    chosenSector.st = SectorType.EngMonolith;\n                } else if (newST <= 13) {\n                    chosenSector.st = SectorType.UnobRift;\n                } else {\n                    chosenSector.st = SectorType.Planet;\n                }\n            }\n        }\n    }\n    \n    // TODO: Make internal.\n    function createLink(\n        bytes32 _from, \n        uint8[2] _fromCoords, \n        bytes32 _to, \n        uint8[2] _toCoords\n    ) {\n        System fromSystem = galacticMap[_from];\n        Sector fromSector = fromSystem.map[_fromCoords[0]][_fromCoords[1]];\n        if(fromSector.st != SectorType.Empty) \n            throw;\n        System toSystem = galacticMap[_to];\n        Sector toSector = toSystem.map[_toCoords[0]][_toCoords[1]];\n        if(toSector.st != SectorType.Empty) \n            throw;\n        fromSector.st = SectorType.Wormhole;\n        fromSystem.Wormholes[compressCoords(_fromCoords)] = _to;\n        toSector.st = SectorType.Wormhole;\n        toSystem.Wormholes[compressCoords(_toCoords)] = _from;\n    }\n\n    //\n    // SHIPS!\n    //\n    \n    using ShipLib for ShipLib.Ship;\n     \n    mapping (uint => ShipLib.Ship) public shipRegistry;\n    \n    uint nextShip;\n    \n    modifier onlyshipowner(uint _shipID) {\n        if(shipRegistry[_shipID].owner != msg.sender) {\n            throw;\n        } else { \n            _\n        }\n    }\n    \n    event shipActivity(\n        bytes32 indexed system, \n        uint8 indexed x, \n        uint8 indexed y,\n        uint shipID\n    );\n    \n    function getShipEnergy(uint _shipID) constant returns (uint) {\n        return shipRegistry[_shipID].getEnergy();\n    }\n\n    function getShipCargo(uint _shipID, uint8 _cargoType) constant returns (uint) {\n        return shipRegistry[_shipID].cargo[_cargoType];\n    }\n\n    function insertShip(\n        bytes32 _system, \n        uint8 _x, \n        uint8 _y, \n        uint _shipID\n    ) \n        internal \n    {\n        // Optimiziation smoptimization.\n        Sector _sector = galacticMap[_system].map[_x][_y];\n        _sector.sectorShips.push(_shipID);\n        shipActivity(_system, _x, _y, _shipID);\n    }\n    \n    function removeShip(\n        bytes32 _system, \n        uint8 _x, \n        uint8 _y, \n        uint _shipID\n    ) \n        internal \n    {\n        Sector _sector = galacticMap[_system].map[_x][_y];\n        uint i = 0;\n        while(true) {\n            if(_sector.sectorShips[i] == _shipID) {\n                _sector.sectorShips[i] = 0;\n                shipActivity(_system, _x, _y, _shipID);\n                return;\n            }\n            i++; // Yes, if we go off, we'll throw. That's the point.\n        }\n    }\n    \n    function spawnCrane(bytes32 _system, uint8 _x, uint8 _y, string _name) {\n        Sector spawnSector = galacticMap[_system].map[_x][_y];\n        if(spawnSector.st != SectorType.Planet) \n            throw; // Generally, empty space does not have an industrial base.\n        uint craneID = nextShip++;\n        ShipLib.Ship crane = shipRegistry[craneID];\n        crane.exists = true;\n        crane.currentSystem = _system;\n        crane.x = _x;\n        crane.y = _y;\n        crane.energy = 0;\n        crane.owner = msg.sender;\n        crane.lastRefreshed = now;\n        crane.def = 1;\n        crane.eng = 1;\n        crane.name = _name;\n        crane.refreshMassRatio();\n        crane.restoreHP();\n        insertShip(_system,_x, _y, craneID);\n    }\n    \n    function moveShip(\n        uint _shipID, \n        bytes32 _newSystem, \n        uint8 _newX, \n        uint8 _newY, \n        uint distance\n    ) internal\n    {\n        ShipLib.Ship mover = shipRegistry[_shipID];\n        //Sector oldSector=galacticMap[mover.currentSystem].map[mover.x][mover.y];\n        removeShip(mover.currentSystem, mover.x, mover.y, _shipID);\n        mover.move(_newSystem, _newX, _newY, distance);\n        //Sector newSector=galacticMap[_newSystem].map[_newX][_newX];\n        insertShip(_newSystem, _newX, _newY, _shipID);\n    }\n    \n    function impulse(\n        uint _shipID, \n        uint8 _newX, \n        uint8 _newY\n    ) \n        onlyshipowner(_shipID) \n    {\n        uint distance = 1;\n        ShipLib.Ship mover = shipRegistry[_shipID];\n        // Guess what, kids? absolute values are broken!\n        //distance += uint(+(int(mover.x) - int(_newX)));\n        //log2(bytes32(mover.x), bytes32(_newX), bytes32(distance));\n        //distance += uint(+(int(mover.y) - int(_newY)));\n        //log2(bytes32(mover.y), bytes32(_newY), bytes32(distance));\n        moveShip(_shipID, mover.currentSystem, _newX, _newY, distance);\n    }\n    \n    function jump(uint _shipID, uint8 destHint) onlyshipowner(_shipID) {\n        ShipLib.Ship ship = shipRegistry[_shipID];\n        uint8[2] memory homecoords;\n        homecoords[0] = ship.x;\n        homecoords[1] = ship.y;\n        bytes32 dest = galacticMap[ship.currentSystem]\n                                        .Wormholes[compressCoords(homecoords)];\n        if(dest == 0x0) \n            throw; // There wasn't a wormhole here.\n        System destSystem = galacticMap[dest];\n        if(destSystem.Wormholes[destHint] != ship.currentSystem)\n            throw; // YOU SHOULD HAVE TAKEN THAT META-LEFT TURN!\n        uint8 destx;\n        uint8 desty;\n        (destx, desty) = decompressCoords(destHint);\n        moveShip(_shipID, dest, destx, desty, 1);\n    }\n    \n    function canMine(uint _shipID, uint16 diff) constant returns (bool) {\n        //return true;\n        var ship = shipRegistry[_shipID];\n        var sector = galacticMap[ship.currentSystem].map[ship.x][ship.y];\n        return ((uint(sha3(_shipID, (block.blockhash(block.number -1)))) % diff) \n                == ((sector.mine) % diff));\n    }\n    \n    function mine(uint _shipID) {\n        var ship = shipRegistry[_shipID];\n        ship.genericAction(8);\n        var sector = galacticMap[ship.currentSystem].map[ship.x][ship.y];\n        // HORRIFING HACK TIME! It seems direct conversion from a sectortype\n        // does not actually work. So, tables.\n        uint st = uint(sector.st);\n        /*\n        if(sector.st == SectorType.AtkAsteriod) {\n            st = 1;\n        } else if(sector.st == SectorType.DefAsteriod) {\n            st = 2;\n        } else if(sector.st == SectorType.EngAsteriod) {\n            st = 3;\n        } else if(sector.st == SectorType.AtkMonolith) {\n            st = 4;\n        } else if(sector.st == SectorType.DefMonolith) {\n            st = 5;\n        } else if(sector.st == SectorType.EngMonolith) {\n            st = 6;\n        } else if(sector.st == SectorType.UnobRift) {\n            st = 7;\n        } else {\n            log1(\"I'm not throwing.\", bytes32(st));\n            return;\n        }\n        */\n        uint16 diff;\n        log1(\"This is ST:\", bytes32(st));\n        if(st == 0) {\n            //throw; // You said there was something to mine HERE?\n            log0(\"How is this even possibly?\");\n            return;\n        } else if (st < 4) {\n            diff = 16;\n        } else if (st < 7) {\n            diff = 256;\n        } else if (st == 7) {\n            diff = 32;\n        } else {\n            //throw; // I don't know if you get what mining means.\n            log0(\"I'd think it was this one?\");\n            return;\n        }\n        if(canMine(_shipID, diff)) {\n            ship.cargo[st - 1]++;\n            log1(\"New cargo:\",bytes32(ship.cargo[st - 1]));\n            ship.refreshMassRatio();\n            sector.mine++;\n            shipActivity(ship.currentSystem, ship.x, ship.y, _shipID);\n            if(st > 3) {\n                if(st < 7) {\n                    sector.st = SectorType(st - 3);\n                } else {\n                    sector.st = SectorType.Empty;\n                }\n            }\n        } else {\n            throw; // It was here a moment ago, I swear!\n        }\n    }\n    \n    function upgrade(uint _shipID, uint8 cargoType) {\n        var ship = shipRegistry[_shipID];\n        var sector = galacticMap[ship.currentSystem].map[ship.x][ship.y];\n        var system = galacticMap[ship.currentSystem];\n        ship.genericAction(1);\n        if(sector.st != SectorType.Planet)\n            throw; // What are you upgrading (with?)\n        if(cargoType > 5) {\n            throw; // I don't think that will help.\n        } else if(cargoType > 2) {\n            system.techLevels[cargoType - 3]++;\n        } else if(cargoType == 2) {\n            ship.eng += (1 + system.techLevels[2]);\n        } else if(cargoType == 1) {\n            ship.def += (1 + system.techLevels[1]);\n        } else if(cargoType == 0) {\n            ship.atk += (1 + system.techLevels[0]);\n        }\n        ship.cargo[cargoType]--;\n        shipActivity(ship.currentSystem, ship.x, ship.y, _shipID);\n        ship.refreshMassRatio();\n    }\n    \n    // Because I seriously don't want to mine while testing.\n    function cheatCargo(uint _shipID, uint8 cargoType) {\n        var ship = shipRegistry[_shipID];\n        ship.cargo[cargoType]++;\n        ship.refreshMassRatio();\n        shipActivity(ship.currentSystem, ship.x, ship.y, _shipID);        \n    }\n}","undoManager":{"mark":78,"position":100,"stack":[[{"start":{"row":393,"column":25},"end":{"row":393,"column":26},"action":"insert","lines":["1"],"id":1148}],[{"start":{"row":393,"column":26},"end":{"row":393,"column":27},"action":"insert","lines":[" "],"id":1149}],[{"start":{"row":393,"column":27},"end":{"row":393,"column":28},"action":"insert","lines":["+"],"id":1150}],[{"start":{"row":393,"column":28},"end":{"row":393,"column":29},"action":"insert","lines":[" "],"id":1151}],[{"start":{"row":393,"column":29},"end":{"row":393,"column":30},"action":"insert","lines":["s"],"id":1152}],[{"start":{"row":393,"column":30},"end":{"row":393,"column":31},"action":"insert","lines":["y"],"id":1153}],[{"start":{"row":393,"column":31},"end":{"row":393,"column":32},"action":"insert","lines":["s"],"id":1154}],[{"start":{"row":393,"column":32},"end":{"row":393,"column":33},"action":"insert","lines":["t"],"id":1155},{"start":{"row":393,"column":33},"end":{"row":393,"column":34},"action":"insert","lines":["e"]}],[{"start":{"row":393,"column":34},"end":{"row":393,"column":35},"action":"insert","lines":["m"],"id":1156}],[{"start":{"row":393,"column":35},"end":{"row":393,"column":36},"action":"insert","lines":["."],"id":1157}],[{"start":{"row":393,"column":36},"end":{"row":393,"column":37},"action":"insert","lines":["t"],"id":1158},{"start":{"row":393,"column":37},"end":{"row":393,"column":38},"action":"insert","lines":["e"]}],[{"start":{"row":393,"column":38},"end":{"row":393,"column":39},"action":"insert","lines":["c"],"id":1159}],[{"start":{"row":393,"column":39},"end":{"row":393,"column":40},"action":"insert","lines":["h"],"id":1160}],[{"start":{"row":393,"column":40},"end":{"row":393,"column":41},"action":"insert","lines":["L"],"id":1161}],[{"start":{"row":393,"column":41},"end":{"row":393,"column":42},"action":"insert","lines":["e"],"id":1162}],[{"start":{"row":393,"column":42},"end":{"row":393,"column":43},"action":"insert","lines":["v"],"id":1163},{"start":{"row":393,"column":43},"end":{"row":393,"column":44},"action":"insert","lines":["e"]},{"start":{"row":393,"column":44},"end":{"row":393,"column":45},"action":"insert","lines":["l"]}],[{"start":{"row":393,"column":45},"end":{"row":393,"column":46},"action":"insert","lines":["s"],"id":1164}],[{"start":{"row":393,"column":46},"end":{"row":393,"column":48},"action":"insert","lines":["[]"],"id":1165}],[{"start":{"row":393,"column":47},"end":{"row":393,"column":48},"action":"insert","lines":["c"],"id":1166},{"start":{"row":393,"column":48},"end":{"row":393,"column":49},"action":"insert","lines":["a"]}],[{"start":{"row":393,"column":49},"end":{"row":393,"column":50},"action":"insert","lines":["r"],"id":1167}],[{"start":{"row":393,"column":50},"end":{"row":393,"column":51},"action":"insert","lines":["g"],"id":1168}],[{"start":{"row":393,"column":51},"end":{"row":393,"column":52},"action":"insert","lines":["o"],"id":1169}],[{"start":{"row":393,"column":52},"end":{"row":393,"column":53},"action":"insert","lines":["T"],"id":1170}],[{"start":{"row":393,"column":53},"end":{"row":393,"column":54},"action":"insert","lines":["y"],"id":1171}],[{"start":{"row":393,"column":54},"end":{"row":393,"column":55},"action":"insert","lines":["p"],"id":1172}],[{"start":{"row":393,"column":55},"end":{"row":393,"column":56},"action":"insert","lines":["e"],"id":1173}],[{"start":{"row":393,"column":55},"end":{"row":393,"column":56},"action":"remove","lines":["e"],"id":1174}],[{"start":{"row":393,"column":54},"end":{"row":393,"column":55},"action":"remove","lines":["p"],"id":1175}],[{"start":{"row":393,"column":53},"end":{"row":393,"column":54},"action":"remove","lines":["y"],"id":1176}],[{"start":{"row":393,"column":52},"end":{"row":393,"column":53},"action":"remove","lines":["T"],"id":1177}],[{"start":{"row":393,"column":51},"end":{"row":393,"column":52},"action":"remove","lines":["o"],"id":1178}],[{"start":{"row":393,"column":50},"end":{"row":393,"column":51},"action":"remove","lines":["g"],"id":1179},{"start":{"row":393,"column":49},"end":{"row":393,"column":50},"action":"remove","lines":["r"]}],[{"start":{"row":393,"column":48},"end":{"row":393,"column":49},"action":"remove","lines":["a"],"id":1180}],[{"start":{"row":393,"column":47},"end":{"row":393,"column":48},"action":"remove","lines":["c"],"id":1181}],[{"start":{"row":393,"column":47},"end":{"row":393,"column":48},"action":"insert","lines":["2"],"id":1182}],[{"start":{"row":395,"column":20},"end":{"row":395,"column":22},"action":"remove","lines":["++"],"id":1183},{"start":{"row":395,"column":20},"end":{"row":395,"column":50},"action":"insert","lines":[" += (1 + system.techLevels[2])"]}],[{"start":{"row":395,"column":47},"end":{"row":395,"column":48},"action":"remove","lines":["2"],"id":1184}],[{"start":{"row":395,"column":47},"end":{"row":395,"column":48},"action":"insert","lines":["1"],"id":1185}],[{"start":{"row":397,"column":20},"end":{"row":397,"column":22},"action":"remove","lines":["++"],"id":1186},{"start":{"row":397,"column":20},"end":{"row":397,"column":50},"action":"insert","lines":[" += (1 + system.techLevels[1])"]}],[{"start":{"row":397,"column":47},"end":{"row":397,"column":48},"action":"remove","lines":["1"],"id":1187}],[{"start":{"row":397,"column":47},"end":{"row":397,"column":48},"action":"insert","lines":["0"],"id":1188}],[{"start":{"row":398,"column":9},"end":{"row":399,"column":0},"action":"insert","lines":["",""],"id":1189},{"start":{"row":399,"column":0},"end":{"row":399,"column":8},"action":"insert","lines":["        "]}],[{"start":{"row":399,"column":8},"end":{"row":399,"column":9},"action":"insert","lines":["s"],"id":1190}],[{"start":{"row":399,"column":9},"end":{"row":399,"column":10},"action":"insert","lines":["h"],"id":1191}],[{"start":{"row":399,"column":10},"end":{"row":399,"column":11},"action":"insert","lines":["i"],"id":1192}],[{"start":{"row":399,"column":11},"end":{"row":399,"column":12},"action":"insert","lines":["p"],"id":1193}],[{"start":{"row":399,"column":12},"end":{"row":399,"column":13},"action":"insert","lines":["A"],"id":1194}],[{"start":{"row":399,"column":12},"end":{"row":399,"column":13},"action":"remove","lines":["A"],"id":1195}],[{"start":{"row":399,"column":12},"end":{"row":399,"column":13},"action":"insert","lines":["A"],"id":1196}],[{"start":{"row":399,"column":13},"end":{"row":399,"column":14},"action":"insert","lines":["c"],"id":1197}],[{"start":{"row":399,"column":14},"end":{"row":399,"column":15},"action":"insert","lines":["t"],"id":1198}],[{"start":{"row":399,"column":15},"end":{"row":399,"column":16},"action":"insert","lines":["i"],"id":1199}],[{"start":{"row":399,"column":16},"end":{"row":399,"column":17},"action":"insert","lines":["p"],"id":1200}],[{"start":{"row":399,"column":0},"end":{"row":400,"column":0},"action":"remove","lines":["        shipActip",""],"id":1201},{"start":{"row":399,"column":0},"end":{"row":399,"column":66},"action":"insert","lines":["        shipActivity(ship.currentSystem, ship.x, ship.y, _shipID);"]}],[{"start":{"row":399,"column":66},"end":{"row":399,"column":74},"action":"remove","lines":["        "],"id":1202},{"start":{"row":399,"column":66},"end":{"row":400,"column":0},"action":"insert","lines":["",""]},{"start":{"row":400,"column":0},"end":{"row":400,"column":8},"action":"insert","lines":["        "]}],[{"start":{"row":398,"column":9},"end":{"row":399,"column":0},"action":"insert","lines":["",""],"id":1203},{"start":{"row":399,"column":0},"end":{"row":399,"column":8},"action":"insert","lines":["        "]}],[{"start":{"row":399,"column":8},"end":{"row":399,"column":9},"action":"insert","lines":["s"],"id":1204}],[{"start":{"row":399,"column":9},"end":{"row":399,"column":10},"action":"insert","lines":["h"],"id":1205}],[{"start":{"row":399,"column":10},"end":{"row":399,"column":11},"action":"insert","lines":["i"],"id":1206}],[{"start":{"row":399,"column":11},"end":{"row":399,"column":12},"action":"insert","lines":["p"],"id":1207}],[{"start":{"row":399,"column":12},"end":{"row":399,"column":13},"action":"insert","lines":["."],"id":1208}],[{"start":{"row":399,"column":13},"end":{"row":399,"column":14},"action":"insert","lines":["c"],"id":1209}],[{"start":{"row":399,"column":14},"end":{"row":399,"column":15},"action":"insert","lines":["a"],"id":1210}],[{"start":{"row":399,"column":15},"end":{"row":399,"column":16},"action":"insert","lines":["r"],"id":1211}],[{"start":{"row":399,"column":16},"end":{"row":399,"column":17},"action":"insert","lines":["g"],"id":1212}],[{"start":{"row":399,"column":17},"end":{"row":399,"column":18},"action":"insert","lines":["o"],"id":1213}],[{"start":{"row":399,"column":18},"end":{"row":399,"column":20},"action":"insert","lines":["[]"],"id":1214}],[{"start":{"row":399,"column":19},"end":{"row":399,"column":20},"action":"insert","lines":["c"],"id":1215}],[{"start":{"row":399,"column":20},"end":{"row":399,"column":21},"action":"insert","lines":["a"],"id":1216}],[{"start":{"row":399,"column":21},"end":{"row":399,"column":22},"action":"insert","lines":["r"],"id":1217}],[{"start":{"row":399,"column":22},"end":{"row":399,"column":23},"action":"insert","lines":["g"],"id":1218}],[{"start":{"row":399,"column":23},"end":{"row":399,"column":24},"action":"insert","lines":["o"],"id":1219}],[{"start":{"row":399,"column":24},"end":{"row":399,"column":25},"action":"insert","lines":["T"],"id":1220}],[{"start":{"row":399,"column":25},"end":{"row":399,"column":26},"action":"insert","lines":["y"],"id":1221}],[{"start":{"row":399,"column":26},"end":{"row":399,"column":27},"action":"insert","lines":["p"],"id":1222}],[{"start":{"row":399,"column":27},"end":{"row":399,"column":28},"action":"insert","lines":["e"],"id":1223}],[{"start":{"row":399,"column":29},"end":{"row":399,"column":30},"action":"insert","lines":["-"],"id":1224}],[{"start":{"row":399,"column":30},"end":{"row":399,"column":31},"action":"insert","lines":["-"],"id":1225}],[{"start":{"row":399,"column":31},"end":{"row":399,"column":32},"action":"insert","lines":[";"],"id":1226}],[{"start":{"row":385,"column":53},"end":{"row":386,"column":0},"action":"insert","lines":["",""],"id":1227},{"start":{"row":386,"column":0},"end":{"row":386,"column":8},"action":"insert","lines":["        "]}],[{"start":{"row":386,"column":8},"end":{"row":386,"column":9},"action":"insert","lines":["g"],"id":1228}],[{"start":{"row":386,"column":8},"end":{"row":386,"column":9},"action":"remove","lines":["g"],"id":1229}],[{"start":{"row":386,"column":8},"end":{"row":386,"column":9},"action":"insert","lines":["s"],"id":1230}],[{"start":{"row":386,"column":9},"end":{"row":386,"column":10},"action":"insert","lines":["h"],"id":1231},{"start":{"row":386,"column":10},"end":{"row":386,"column":11},"action":"insert","lines":["i"]}],[{"start":{"row":386,"column":11},"end":{"row":386,"column":12},"action":"insert","lines":["p"],"id":1232}],[{"start":{"row":386,"column":12},"end":{"row":386,"column":13},"action":"insert","lines":["."],"id":1233}],[{"start":{"row":386,"column":13},"end":{"row":386,"column":14},"action":"insert","lines":["g"],"id":1234}],[{"start":{"row":386,"column":14},"end":{"row":386,"column":15},"action":"insert","lines":["e"],"id":1235}],[{"start":{"row":386,"column":15},"end":{"row":386,"column":16},"action":"insert","lines":["n"],"id":1236}],[{"start":{"row":386,"column":16},"end":{"row":386,"column":17},"action":"insert","lines":["e"],"id":1237}],[{"start":{"row":386,"column":17},"end":{"row":386,"column":18},"action":"insert","lines":["r"],"id":1238}],[{"start":{"row":386,"column":18},"end":{"row":386,"column":19},"action":"insert","lines":["i"],"id":1239}],[{"start":{"row":386,"column":19},"end":{"row":386,"column":20},"action":"insert","lines":["c"],"id":1240}],[{"start":{"row":386,"column":20},"end":{"row":386,"column":21},"action":"insert","lines":["A"],"id":1241}],[{"start":{"row":386,"column":21},"end":{"row":386,"column":22},"action":"insert","lines":["c"],"id":1242}],[{"start":{"row":386,"column":22},"end":{"row":386,"column":23},"action":"insert","lines":["t"],"id":1243},{"start":{"row":386,"column":23},"end":{"row":386,"column":24},"action":"insert","lines":["i"]}],[{"start":{"row":386,"column":24},"end":{"row":386,"column":25},"action":"insert","lines":["o"],"id":1244}],[{"start":{"row":386,"column":25},"end":{"row":386,"column":26},"action":"insert","lines":["n"],"id":1245}],[{"start":{"row":386,"column":26},"end":{"row":386,"column":28},"action":"insert","lines":["()"],"id":1246}],[{"start":{"row":386,"column":27},"end":{"row":386,"column":28},"action":"insert","lines":["1"],"id":1247}],[{"start":{"row":386,"column":29},"end":{"row":386,"column":30},"action":"insert","lines":[";"],"id":1248}]]},"ace":{"folds":[],"scrolltop":6012,"scrollleft":0,"selection":{"start":{"row":386,"column":30},"end":{"row":386,"column":30},"isBackwards":false},"options":{"guessTabSize":true,"useWrapMode":false,"wrapToView":true},"firstLineState":{"row":298,"state":"start","mode":"plugins/ethergit.solidity.language/solidity_mode"}},"timestamp":1449419678350}