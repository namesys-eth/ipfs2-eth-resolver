// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import "src/IPFS2ETH.sol";
import "./Utils.sol";

/**
 * @title - IPFS2 Tester
 * @author - freetib.eth, sshmatrix.eth
 */
contract IPFS2Test is Test {
    function setUp() public {}

    IPFS2ETH ipfs2eth;
    Utils utils;
    CCIPTest xccip;

    constructor() {
        ipfs2eth = new IPFS2ETH();
        utils = new Utils();
        xccip = new CCIPTest();
    }

    /// @dev : Tests the Encode() function of the Utils contract. Encodes ENS name labels into an array, encodes it and verifies the result against expected name and namehash values.
    function testSetup() public {
        bytes[] memory _test = new bytes[](2);
        _test[0] = "ipfs2";
        _test[1] = "eth";
        (bytes32 _namehash, bytes memory _name) = utils.Encode(_test);
        assertEq(_name, bytes.concat(bytes1(uint8(5)), "ipfs2", bytes1(uint8(3)), "eth", bytes1(0)));
        assertEq(
            _namehash,
            keccak256(abi.encodePacked(keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))), keccak256("ipfs2")))
        );
    }

    /// @dev : Checks the default contenthash by encoding the labels of ENS name, creating a request, and verifying that the contenthash was retrieved correctly. It also tests the offchain lookup by reverting the transaction and checking if the callback function was called correctly.
    function testDefaultContenthash() public {
        bytes[] memory _name = new bytes[](2);
        _name[0] = "ipfs2";
        _name[1] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        ipfs2eth.setCCIP2Contract(address(xccip));
        bytes memory _data = ipfs2eth.DefaultContenthash();
        assertEq(abi.encode(_data), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth. It encodes the URL query (for a base32 IPFS hash) using the utils.Encode() function and then checks the resolution by calling resolve(). It also tests for a revert when calling OffchainLookup(). Finally, it asserts that the callback function returns the expected encoded data.
    function testResolveBase32() public {
        bytes[] memory _name = new bytes[](3);
        _name[0] = "bafybeieexfyfk3blzpi7g7j3aaogyvlg7qhopr7ru5x5v3nxrlx5zihnaa";
        _name[1] = "ipfs2";
        _name[2] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.decodeBase32(bytes("afybeieexfyfk3blzpi7g7j3aaogyvlg7qhopr7ru5x5v3nxrlx5zihnaa"));
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(bytes2(0xe301), _data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a ipns contenthash using IPFS2.eth. It encodes the URL query (for a base32 IPNS hash) using the utils.Encode() function and then checks the resolution by calling resolve(). It also tests for a revert when calling OffchainLookup(). Finally, it asserts that the callback function returns the expected encoded data.
    function testResolveBase32IPNS() public {
        bytes[] memory _name = new bytes[](4);
        _name[0] = "bafzaajaiaejcbk7aprbeizayw5c";
        _name[1] = "kg6uhdrz3dpndlkjbvceytvh35e7zwcoshxzz";
        _name[2] = "ipfs2";
        _name[3] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.decodeBase32(bytes("afzaajaiaejcbk7aprbeizayw5ckg6uhdrz3dpndlkjbvceytvh35e7zwcoshxzz"));
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(bytes2(0xe501), _data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for a base36 IPNS hash [similar to testResolveBase32()]
    function testResolveBase36() public {
        bytes[] memory _name = new bytes[](3);
        _name[0] = "k51qzi5uqu5dhg0onhctxbxl0cxnxsdsg5hstxn0x97gxb36tmwjluwq0l0aod";
        _name[1] = "ipfs2";
        _name[2] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data =
            ipfs2eth.decodeBase36(bytes("51qzi5uqu5dhg0onhctxbxl0cxnxsdsg5hstxn0x97gxb36tmwjluwq0l0aod"));
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);

        assertEq(abi.encode(abi.encodePacked(bytes2(0xe501), _data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type 2-level subdomain queries [1]
    function testResolveHexSubdomains2Level_1() public {
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

        assertEq(abi.encode(abi.encodePacked(bytes2(0xe501), _data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type 2-level subdomain queries [2]
    function testResolveHexSubdomains2Level_2() public {
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
        assertEq(abi.encode(abi.encodePacked(_data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type one-level Onion queries
    function testResolveHexOnion1Level() public {
        bytes[] memory _name = new bytes[](4);
        _name[0] = "bc037a716b746c7769";
        _name[1] = "34666563766f367269";
        _name[2] = "ipfs2";
        _name[3] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.hexStringToBytes(bytes("bc037a716b746c776934666563766f367269"));
        assertEq(hex"bc037a716b746c776934666563766f367269", _data);
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(_data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type 3-level Onion queries
    function testResolveHexOnion3Level() public {
        bytes[] memory _name = new bytes[](6);
        _name[0] = "bd037035336c66353771";
        _name[1] = "6f7679757677736336786e7270707970";
        _name[2] = "6c79337674716d376c3670636f626b6d";
        _name[3] = "797173696f6679657a6e667535757164";
        _name[4] = "ipfs2";
        _name[5] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.hexStringToBytes(
            bytes(
                "bd037035336c663537716f7679757677736336786e72707079706c79337674716d376c3670636f626b6d797173696f6679657a6e667535757164"
            )
        );
        assertEq(
            hex"bd037035336c663537716f7679757677736336786e72707079706c79337674716d376c3670636f626b6d797173696f6679657a6e667535757164",
            _data
        );
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(_data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type 2-level Skynet queries
    function testResolveHexSkylink2Level() public {
        bytes[] memory _name = new bytes[](5);
        _name[0] = "90b2c6050800";
        _name[1] = "4007fd43b74149b31aacbbf2784e874d";
        _name[2] = "09b086bed15fd54cacff7120cce95372";
        _name[3] = "ipfs2";
        _name[4] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data = ipfs2eth.hexStringToBytes(
            bytes("90b2c60508004007fd43b74149b31aacbbf2784e874d09b086bed15fd54cacff7120cce95372")
        );
        assertEq(hex"90b2c60508004007fd43b74149b31aacbbf2784e874d09b086bed15fd54cacff7120cce95372", _data);
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(_data)), ipfs2eth.resolve(_encoded, _request));
    }

    /// @dev : Tests the resolution of a contenthash using IPFS2.eth for hex-type 2-level Arweave queries
    function testResolveHexArweave2Level() public {
        bytes[] memory _name = new bytes[](5);
        _name[0] = "90b2ca05";
        _name[1] = "cacdf63edf2e0bb4eb5711dd38b0723a";
        _name[2] = "ca5f3c4ab62ceeb7c1110740833d4894";
        _name[3] = "ipfs2";
        _name[4] = "eth";
        (bytes32 _namehash, bytes memory _encoded) = utils.Encode(_name);
        bytes memory _data =
            ipfs2eth.hexStringToBytes(bytes("90b2ca05cacdf63edf2e0bb4eb5711dd38b0723aca5f3c4ab62ceeb7c1110740833d4894"));
        assertEq(hex"90b2ca05cacdf63edf2e0bb4eb5711dd38b0723aca5f3c4ab62ceeb7c1110740833d4894", _data);
        bytes memory _request = abi.encodePacked(iResolver.contenthash.selector, _namehash);
        assertEq(abi.encode(abi.encodePacked(_data)), ipfs2eth.resolve(_encoded, _request));
    }
}

/**
 * @dev Initialise Stuff
 */
contract CCIPTest {
    function supportsInterface(bytes4 _sig) public pure returns (bool) {
        return _sig == iCCIP.resolve.selector || _sig == iERC165.supportsInterface.selector;
    }

    /// @dev : returns default contenthash (404.html)
    function resolve(bytes calldata, bytes calldata) external view returns (bytes memory) {
        this;
        return abi.encode(hex"e50101720024080112206377fe7e59802cc7160886ef388d2eda7a1a6fbd48156153975e443ae8d00438");
    }
}
