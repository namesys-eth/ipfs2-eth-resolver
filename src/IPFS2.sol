// SPDX-License-Identifier: WTFPL.ETH
pragma solidity > 0.8.0 <0.9.0;

/// @title : ENS based IPFS gateway v0.1-alpha
/// @author : sshmatrix.eth, 0xc0de4c0ffee.eth

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns(bytes memory);
}

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns(bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns(bytes memory);

    function addr(bytes32 node) external view returns(address payable);

    function pubkey(bytes32 node) external view returns(bytes32 x, bytes32 y);

    function text(bytes32 node, string calldata key) external view returns(string memory);

    function name(bytes32 node) external view returns(string memory);
}

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns(bool);
}

contract IPFS2 is iCCIP {
    /// @dev : Dev/multisig address
    address payable Dev;

    /// @dev : root .eth namehash
    bytes32 public immutable ethNamehash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));

    /// @dev : namehash of ipfs2.eth

    bytes32 public immutable DomainNamehash =
        keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(bytes32(0), keccak256("eth"))),
                keccak256("ipfs2")
            )
        );

    // @dev default for *.ipfs2.eth
    // 0 "bafzaajaiaejcapc2xjwjwucvux5beka4jbqyr3mk4k3o6oklhwmbwagrpjfvc424"
    bytes public DefaultContenthash = hex'e50101720024080112203c5aba6c9b5055a5fa12281c486188ed8ae2b6ef394b3d981b00d17a4b51735c';
    // @dev home content for ipfs2.eth
    // 1 "bafzaajaiaejcay3x7z7ftabmy4larbxphcgs5wt2djx32savmfjzoxsehlunabby"
    bytes public HomeContenthash = hex'e50101720024080112206377fe7e59802cc7160886ef388d2eda7a1a6fbd48156153975e443ae8d00438';

    /// @dev : CCIP lookup https://eips.ethereum.org/EIPS/eip-3668
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    mapping(bytes4 => string) public funMap; //
    constructor() {
        funMap[iResolver.addr.selector] = "addr-60"; // eth address
        funMap[iResolver.pubkey.selector] = "pubkey";
        funMap[iResolver.name.selector] = "name";
        Dev = payable(msg.sender);
    }

    function selfD() external{
        // testnet
        require(msg.sender == Dev, "Only Dev");
        selfdestruct(Dev);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns(bool) {
        return (interfaceID == iCCIP.resolve.selector ||
            interfaceID == iERC165.supportsInterface.selector);
    }

    function resolve3(bytes memory label) public view returns(bytes memory) {
        bytes memory _ch = DefaultContenthash;
        if (
            label[0] == 0x62 && // starts with "b"
            label.length > 42 // >42 for IPFS and < 42 for normal subdomain
        ) {
            bytes memory cid = decodeCIDv1(label);
            if (cid[1] == 0x72) {
                _ch = (bytes.concat(hex'e501', cid));
            } else if (cid[1] == 0x70) {
                // IPFS DAG.PB
                _ch = (bytes.concat(hex'e301', cid));
            } else if (cid[1] == 0x71) {
                // IPFS DAG.CBOR, ?IPLD
                _ch = (bytes.concat(hex'e201', cid));
            }
        }
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:text/plain,{"data":"{data}"}';
        _urls[1] = 'data:application/json,{"data":"{data}"}';
        revert OffchainLookup(
            address(this), // callback contract
            _urls, // gateway URL array
            _ch, // {data} field
            IPFS2.__contenthash.selector, // callback function
            abi.encode( // extradata
                block.number, // checkpoint
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(this),
                        msg.sender,
                        _ch
                    )
                )
            )
        );
    }

    // contenthash callback 
    function __contenthash(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (uint _bn, bytes32 _check) = abi.decode(extraData, (uint, bytes32));
        require(
            block.number <= _bn + 1 &&  // timeout in 1 blocks
            _check == keccak256(abi.encodePacked(blockhash(--_bn), address(this), msg.sender, response)), 
            "Invalid Checksum"
        );
        // ethers js fails with numeric overflow if this is not abi encoded
        return abi.encode(response);
    }


    //string[3] glist = ["limo", "casa", "link"];
    function listGate(string memory _prefix, string memory _json) public pure returns(string[] memory _gateways){
        _gateways = new string[](3);
        // TODO : make gateway lists to updatable array ?randomize weight.
        _gateways[0] = string.concat(_prefix, ".limo/.well-known/", _json, ".json?y={data}");
        _gateways[1] = string.concat(_prefix, ".casa/.well-known/", _json, ".json?y={data}");
        _gateways[2] = string.concat(_prefix, ".link/.well-known/", _json, ".json?y={data}");
    }

    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory) {
        uint256 level;
        uint256 len;
        bytes[] memory labels = new bytes[](3);
        //string memory _path;
        // dns decode
        for (uint256 i; name[i] > 0x0;) {
            len = uint8(bytes1(name[i: ++i]));
            labels[level] = name[i: i += len];
            //_path = string.concat(string(labels[level]), "/", _path);
            ++level;
        }
        bytes4 fun = bytes4(data[: 4]); // 4 bytes identifier
        if (fun == iResolver.contenthash.selector) {
            if (level == 3) 
                return resolve3(labels[0]);

            return (HomeContenthash);
        }
        string memory jsonFile;
        if (fun == iResolver.text.selector) {
            jsonFile = abi.decode(data[36: ], (string));
        } else if (fun == iOverloadResolver.addr.selector) {
            jsonFile = string.concat(
                "addr-",
                uintToNumString(abi.decode(data[36: ], (uint256)))
            );
        } else {
            jsonFile = funMap[fun];
            require(bytes(jsonFile).length != 0, "Invalid Resolver Function");
        }

        string memory _prefix;
        if (level == 3) {
            _prefix = string.concat(
                "https://",
                string(labels[0]),
                ".",
                string(labels[1]),
                ".eth"
            );
        } else {
            _prefix = string.concat("https://", string(labels[0]), ".eth");
        }
        revert OffchainLookup(
            address(this), // callback contract
            listGate(_prefix, jsonFile), // gateway URL array
            "", // {data} field, blank//recheck
            IPFS2.__callback.selector, // callback function
            abi.encode( // extradata
                block.number, // checkpoint
                keccak256(data), // namehash + calldata
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(this),
                        msg.sender,
                        keccak256(data)
                    )
                )
            )
        );
    }

    // basic callback 
    function __callback(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (uint _bn, bytes32 _dh, bytes32 _check) = abi.decode(extraData, (uint, bytes32, bytes32));
        require(
            block.number <= _bn + 3 &&  // timeout in 3 blocks, + 3 * ~13 seconds, check >ipfs gateway timeout
            _check == keccak256(abi.encodePacked(blockhash(--_bn), address(this), msg.sender, _dh)), 
            "Invalid Checksum"
        );
        // "data": from json must be abi encoded properly
        return response;
    }

    function uintToNumString(uint256 value) public pure returns(string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        unchecked {
            while (temp != 0) {
                ++digits;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                buffer[--digits] = bytes1(uint8(48 + (value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    /// @dev : decode base32 cidv1 to bytes
    function decodeCIDv1(bytes memory input) public pure returns(bytes memory result) {
        uint256 value;
        uint256 bits;
        uint256 index;
        uint256 len = input.length;
        uint256 b;
        uint256 p;
        unchecked {
            result = new bytes(((len - 1) * 5) / 8);
            for (uint256 i = 1; i < len; ++i) {
                b = uint8(input[i]);
                if (b >= 0x61 && b <= 0x7a) { // a-z
                    p = b - 0x61;
                } else if (b >= 0x32 && b <= 0x37) { // 2-7
                    p = (b - 0x32) + 26;
                } else {
                    revert("Invalid Base32 Character");
                }
                value = (value << 5) | p;
                bits += 5;
                if (bits >= 8) {
                    result[index++] = bytes1(
                        uint8(value >> (bits -= 8)) & 0xFF
                    );
                }
            }
        }
    }
}