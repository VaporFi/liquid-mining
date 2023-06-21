"use strict";
exports.__esModule = true;
exports.generateFullABI = void 0;
var fs_1 = require("fs");
function generateFullABI() {
    var folders = (0, fs_1.readdirSync)('./abis/');
    var fullAbi = [];
    for (var _i = 0, folders_1 = folders; _i < folders_1.length; _i++) {
        var folder = folders_1[_i];
        var fileName = "".concat(folder).split('.')[0] + '.json';
        var fileData = (0, fs_1.readFileSync)("./abis/".concat(folder, "/").concat(fileName), 'utf8');
        var abi = JSON.parse(fileData).abi;
        abi === null || abi === void 0 ? void 0 : abi.map(function (i) { return ((fullAbi === null || fullAbi === void 0 ? void 0 : fullAbi.includes(i)) ? null : fullAbi === null || fullAbi === void 0 ? void 0 : fullAbi.push(i)); });
    }
    (0, fs_1.writeFileSync)('./abi/fullDiamond.json', JSON.stringify(fullAbi, null, 4));
}
exports.generateFullABI = generateFullABI;
generateFullABI();
