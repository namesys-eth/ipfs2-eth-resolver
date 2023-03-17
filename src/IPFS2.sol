// SPDX-License-Identifier: WTFPL.ETH
pragma solidity > 0.8 .0 < 0.9 .0;

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
    bytes public DefaultContenthash;
    // @dev home content for ipfs2.eth
    bytes public HomeContenthash;

    /// @dev : CCIP lookup https://eips.ethereum.org/EIPS/eip-3668
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    constructor() {
        funMap[iResolver.addr.selector] = "addr-60"; // eth address
        funMap[iResolver.pubkey.selector] = "pubkey";
        funMap[iResolver.name.selector] = "name";
    }

    bytes4 public ch = iResolver.contenthash.selector;
    bytes4 public addr = iResolver.contenthash.selector;

    function supportsInterface(bytes4 interfaceID) external pure returns(bool) {
        return (interfaceID == iCCIP.resolve.selector ||
            interfaceID == iERC165.supportsInterface.selector);
    }

    function resolve3(bytes memory label) public view returns(bytes memory) {
        if (
            label[0] == 0x62 && // starts with "b"
            label.length > 42 // >42 for IPFS and < 42 for normal subdomain
        ) {
            bytes memory cid = decodeCIDv1(label);
            if (cid[1] == 0x72) {
                return (bytes.concat(hex 'e501', cid));
            } else if (cid[1] == 0x70) {
                // IPFS DAG.PB
                return (bytes.concat(hex 'e301', cid));
            } else if (cid[1] == 0x71) {
                // IPFS DAG.CBOR, ?IPLD
                return (bytes.concat(hex 'e201', cid));
            }
        }

        // check *.domain.eth here
        // return default if no contenthash set
        return (DefaultContenthash);
    }

    function resolve(bytes calldata name, bytes calldata data) external view returns(bytes memory) {
        uint256 level;
        uint256 len;
        bytes[] memory labels = new bytes[](3);
        string memory _path;
        // dns decode
        for (uint256 i; name[i] > 0x0;) {
            len = uint8(bytes1(name[i: ++i]));
            labels[level] = name[i: i += len];
            _path = string.concat(string(labels[level]), "/", _path);
            ++level;
        }
        bytes4 fun = bytes4(data[: 4]); // 4 bytes identifier
        if (fun == iResolver.contenthash.selector) {
            if (level == 3) {
                // TEST : use ccip revert if direct return fails to resolve on ethers.js
                if (
                    label[0] == 0x62 && // starts with "b"
                    label.length > 42 // >42 for IPFS and < 42 for normal subdomain 
                    // ToDo : double check for proper length cutoff
                    // ToDo : more cid-v1 support
                ) {
                    bytes memory cid = decodeCIDv1(label);
                    if (cid[1] == 0x72) {
                        // IPNS libp2p key
                        return (bytes.concat(hex 'e501', cid));
                    } else if (cid[1] == 0x70) {
                        // IPFS DAG.PB
                        return (bytes.concat(hex 'e301', cid));
                    } else if (cid[1] == 0x71) {
                        // IPFS DAG.CBOR, ?IPLD
                        return (bytes.concat(hex 'e201', cid));
                    }
                }
                // ToDo : check *.ipfs2.eth here
                // return default profile if no contenthash set
                return (DefaultContenthash);
            } else {
                // ipfs2.eth home 
                return (HomeContenthash);
            }
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

        string[] memory _gateways = new string[](3);
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

        // TODO : make gateway lists to updatable array ?randomize weight.
        _gateways[0] = string.concat(_prefix, ".limo/.well-known/", _path, "/", jsonFile, ".json?{data}");
        _gateways[1] = string.concat(_prefix, ".casa/.well-known/", _path, "/", jsonFile, ".json?{data}");
        _gateways[2] = string.concat(_prefix, ".link/.well-known/", _path, "/", jsonFile, ".json?{data}");

        revert OffchainLookup(
            address(this), // callback contract
            _gateways, // gateway URL array
            "", // {data} field, blank//recheck
            IPFS2.__callback.selector, // callback function
            abi.encode( // extradata
                data[:4], // func identifier 
                data[4:], // namehash + calldata
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(this),
                        msg.sender,
                        data
                    )
                ),
                block.number // checkpoint
            )
        );
    }

    function __callback(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (bytes4 _f, bytes32 _nh, uint _check, bytes32 _bn) = abi.decode(extraData, (bytes4, bytes32, bytes32, uint));
        require(
            block.number < _bn + 5, // timeout in 5 blocks, 5 *~13 seconds, check >ipfs gateway timeout
            _check == keccak256(abi.encodePacked(blockhash(_bn), address(this), msg.sender, _f, _nh)), 
            "Invalid Checksum"
        );
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
    function decodeCIDv1(bytes memory input) public view returns(bytes memory) {
        uint256 value;
        uint256 bits;
        uint256 index;
        uint256 len = input.length;
        uint256 b;
        uint256 p;
        unchecked {
            bytes memory result = new bytes(((len - 1) * 5) / 8);
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
            if (result[1] == 0x72) {
                return (bytes.concat(hex "e501", result));
            } else if (result[1] == 0x71) {
                return (bytes.concat(hex "e201", result));
            } else { // fallback to IPFS, NO IPLD Support
                return (bytes.concat(hex "e301", result));
            }
        }
    }

    /// @dev : encode ENS contenthash bytes to base32 cidv1 string
    function encodeCIDv1(bytes memory input) public pure returns(string memory _cidv1String, bytes1 _namespace) {
        uint256 len = input.length;
        if (len < 38) revert("Invalid Length"); // 32 bytes + 4 bytes identifiers + 2 bytes namespace
        uint256 value;
        uint256 bits;
        uint256 index;
        bytes memory BASE32 = "abcdefghijklmnopqrstuvwxyz234567";
        unchecked {
            uint256 bitCount = (len - 2) * 8;
            bytes memory result = new bytes((bitCount + (bitCount % 5)) / 5);
            for (uint256 i = 2; i < len; ++i) {
                value = (value << 8) | uint8(input[i]);
                bits += 8;
                while (bits >= 5) {
                    result[index++] = BASE32[(value >> (bits -= 5)) & 0x1F];
                }
            }
            if (bits > 0) {
                result[index] = BASE32[(value << (5 - bits)) & 0x1F];
            }
            return (string.concat("b", string(result)), input[0]);
        }
    }
}