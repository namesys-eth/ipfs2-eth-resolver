// SPDX-License-Identifier: WTFPL.ETH
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/IPFS2ETH.sol";

import "./Utils.sol";

contract IPFS2Test is Test {
    function setUp() public {}

    IPFS2ETH ipfs2eth;
    Utils utils;

    constructor() {
        ipfs2eth = new IPFS2ETH();
        utils = new Utils();
    }

    function testSetup() public {
        bytes[] memory _test = new bytes[](2);
        _test[0] = "ipfs2";
        _test[1] = "eth";
        (bytes32 _namehash, bytes memory _name) = utils.Encode(_test);
        assertEq(_name, bytes.concat(bytes1(uint8(5)), "ipfs2", bytes1(uint8(3)), "eth", bytes1(0)));
        assertEq(_name, abi.encodePacked(ipfs2eth.suffixCheck()));
        assertEq(
            _namehash,
            keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("ipfs2")))
        );
    }

    function testHomeContenthash() public {
        bytes[] memory _name = new bytes[](2);
        _name[0] = "ipfs2";
        _name[1] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        bytes memory _data = ipfs2eth.HomeContenthash();
        bytes32 _checkHash =
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(ipfs2eth), address(this), _data));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPFS2ETH.OffchainLookup.selector,
                address(ipfs2eth),
                _urls,
                _data,
                IPFS2ETH.__callback.selector,
                abi.encode(block.number - 1, _checkHash)
            )
        );
        ipfs2eth.resolve(_encoded, _request);
        assertEq(abi.encode(_data), ipfs2eth.__callback(_data, abi.encode(block.number - 1, _checkHash)));
    }

    function testResolveBase32() public {
        bytes[] memory _name = new bytes[](3);
        _name[0] = "bafybeieexfyfk3blzpi7g7j3aaogyvlg7qhopr7ru5x5v3nxrlx5zihnaa";
        _name[1] = "ipfs2";
        _name[2] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.decodeBase32(bytes("afybeieexfyfk3blzpi7g7j3aaogyvlg7qhopr7ru5x5v3nxrlx5zihnaa"));
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        bytes32 _checkHash =
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(ipfs2eth), address(this), _data));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPFS2ETH.OffchainLookup.selector,
                address(ipfs2eth),
                _urls,
                _data,
                IPFS2ETH.__callback.selector,
                abi.encode(block.number - 1, _checkHash)
            )
        );
        ipfs2eth.resolve(_encoded, _request);
        assertEq(
            abi.encode(abi.encodePacked(bytes2(0xe301), _data)),
            ipfs2eth.__callback(_data, abi.encode(block.number - 1, _checkHash))
        );
    }

    function testResolveBase36() public {
        bytes[] memory _name = new bytes[](3);
        _name[0] = "k51qzi5uqu5dhg0onhctxbxl0cxnxsdsg5hstxn0x97gxb36tmwjluwq0l0aod";
        _name[1] = "ipfs2";
        _name[2] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data =
            ipfs2eth.decodeBase36(bytes("51qzi5uqu5dhg0onhctxbxl0cxnxsdsg5hstxn0x97gxb36tmwjluwq0l0aod"));
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        bytes32 _checkHash =
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(ipfs2eth), address(this), _data));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPFS2ETH.OffchainLookup.selector,
                address(ipfs2eth),
                _urls,
                _data,
                IPFS2ETH.__callback.selector,
                abi.encode(block.number - 1, _checkHash)
            )
        );
        ipfs2eth.resolve(_encoded, _request);
        assertEq(
            abi.encode(abi.encodePacked(bytes2(0xe501), _data)),
            ipfs2eth.__callback(_data, abi.encode(block.number - 1, _checkHash))
        );
    }

    function testResolveHexSubsA() public {
        bytes[] memory _name = new bytes[](5);
        _name[0] = "f0172002408011220";
        _name[1] = "32a1a9c61c6d14bbde2bca0be1b28c28";
        _name[2] = "6be6b484fc804170e2d632b07f0c0b0d";
        _name[3] = "ipfs2";
        _name[4] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.hexStringToBytes(
            bytes("017200240801122032a1a9c61c6d14bbde2bca0be1b28c286be6b484fc804170e2d632b07f0c0b0d")
        );
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        bytes32 _checkHash =
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(ipfs2eth), address(this), _data));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPFS2ETH.OffchainLookup.selector,
                address(ipfs2eth),
                _urls,
                _data,
                IPFS2ETH.__callback.selector,
                abi.encode(block.number - 1, _checkHash)
            )
        );
        ipfs2eth.resolve(_encoded, _request);
        assertEq(
            abi.encode(abi.encodePacked(bytes2(0xe501), _data)),
            ipfs2eth.__callback(_data, abi.encode(block.number - 1, _checkHash))
        );
    }

    function testResolveHexSubsB() public {
        bytes[] memory _name = new bytes[](5);
        _name[0] = "e5010172002408011220";
        _name[1] = "32a1a9c61c6d14bbde2bca0be1b28c28";
        _name[2] = "6be6b484fc804170e2d632b07f0c0b0d";
        _name[3] = "ipfs2";
        _name[4] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.hexStringToBytes(
            bytes("e501017200240801122032a1a9c61c6d14bbde2bca0be1b28c286be6b484fc804170e2d632b07f0c0b0d")
        );
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        bytes32 _checkHash =
            keccak256(abi.encodePacked(blockhash(block.number - 1), address(ipfs2eth), address(this), _data));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPFS2ETH.OffchainLookup.selector,
                address(ipfs2eth),
                _urls,
                _data,
                IPFS2ETH.__callback.selector,
                abi.encode(block.number - 1, _checkHash)
            )
        );
        ipfs2eth.resolve(_encoded, _request);
        assertEq(
            abi.encode(abi.encodePacked(_data)),
            ipfs2eth.__callback(_data, abi.encode(block.number - 1, _checkHash))
        );
    }
}
