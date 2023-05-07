// SPDX-License-Identifier: WTFPL.ETH
pragma solidity > 0.8.0 <0.9.0;

/// @title : ENS-based IPFS Gateway v0.1-alpha
/// @author : 0xc0de4c0ffee.eth, sshmatrix.eth
// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @title : ENS Off-chain Records Manager
 * @author : freetib.eth, sshmatrix.eth
 */

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iENS {
    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);
    //function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);

    function __callback(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory result);
}

interface iIPNS {
    function setContenthash(bytes32 node, bytes calldata _ch) external view returns (bytes memory);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);

    function addr(bytes32 node) external view returns (address payable);

    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);

    function text(bytes32 node, string calldata key) external view returns (string memory value);

    function name(bytes32 node) external view returns (string memory);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);

    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

    function zonehash(bytes32 node) external view returns (bytes memory);

    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);

    //function recordVersions(bytes32 node) external view returns (uint64);

    /// @dev : set contenthash
    function setContenthash(bytes32 node, bytes calldata hash) external;
}

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
}

interface iToken {
    function ownerOf(uint256 id) external view returns (address);

    function transferFrom(address from, address to, uint256 bal) external;

    function safeTransferFrom(address from, address to, uint256 bal) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setApprovalForAll(address _operator, bool _approved) external;
}

interface iERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
}

contract IPFS2ETH is iCCIP, iERC165, iERC173 {
    address public owner;

    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    bytes11 private immutable suffixCheck = bytes11(abi.encodePacked(uint8(5), "ipfs2", uint8(3), "eth", uint8(0)));

    event ThankYou(address indexed _from, uint256 indexed _value);

    /// @dev : revert on zero receive
    receive() external payable {
        if (msg.value == 0) revert();
        emit ThankYou(msg.sender, msg.value);
    }

    /// @dev constructor initial setup
    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only Owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @dev : ENSIP10 CCIP-read Off-chain Lookup method (https://eips.ethereum.org/EIPS/eip-3668)
    error OffchainLookup(
        address _addr, // callback contract
        string[] _gateways, // CCIP gateway URLs
        bytes _data, // {data} field; request value for HTTP call
        bytes4 _callbackFunction, // callback function
        bytes _extradata // callback extra data
    );

    /**
     * @dev Interface Selector
     * @param interfaceID : interface identifier
     */

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (
            interfaceID == iCCIP.resolve.selector || interfaceID == type(iERC173).interfaceId
                || interfaceID == iERC165.supportsInterface.selector
        );
    }

    bytes public DefaultContenthash =
        hex"e50101720024080112206377fe7e59802cc7160886ef388d2eda7a1a6fbd48156153975e443ae8d00438";

    /**
     * @dev core Resolve function
     * @param name : ENS name to resolve, DNS encoded
     * @param data : data encoding specific resolver function
     * @return : triggers offchain lookup so return value is never used directly
     */

    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        unchecked {
            bytes memory _contenthash;
            uint256 len = uint8(bytes1(name[:1])) + 1;
            if (len < 32) {
                __lookup(_contenthash);
            }
            require(bytes4(data[:4]) == iResolver.contenthash.selector, "Only Contehthash Supported");
            require(bytes11(name[len - 12:]) == suffixCheck, "Only *.IPFS2.ETH");
            bytes1 b1 = bytes1(name[1:2]);
            if (b1 == bytes1("b")) {
                _contenthash = decodeBase32(name[1:len]);
            } else if (b1 == bytes1("k")) {
                _contenthash = decodeBase32(name[1:len]);
            } else {
                // <bytesX>.bytes16.bytes16.ipfs2.eth.limo
                if (uint8(name[len]) != uint8(32) || uint8(name[len + 33]) != uint8(32) || len + 77 != name.length) {
                    revert("Invalid Subdomain Format");
                }
                _contenthash =
                    hexStringToBytes(bytes.concat(name[1:len], name[len + 1:len + 33], name[len + 34:len + 66]));
            }
            __lookup(_contenthash);
        }
    }

    function __lookup(bytes memory _contenthash) private view {
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:text/plain,{"data":"{data}"}';
        _urls[1] = 'data:application/json,{"data":"{data}"}';
        revert OffchainLookup(
            address(this),
            _urls,
            abi.encode(_contenthash),
            IPFS2ETH.__callback.selector,
            abi.encode(
                block.number - 1,
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), address(this), msg.sender, abi.encode(_contenthash))
                )
            )
        );
    }

    /**
     * @dev callback function
     * @param response : response of HTTP call
     * @param extradata: extra data from resolve function
     */

    function __callback(bytes calldata response, bytes calldata extradata)
        external
        view
        returns (bytes memory result)
    {
        (uint256 _blocknumber, bytes32 _checkHash) = abi.decode(extradata, (uint256, bytes32));
        require(
            block.number < _blocknumber + 3
                && _checkHash == keccak256(abi.encodePacked(blockhash(_blocknumber), address(this), msg.sender, response)),
            "Invalid Checkhash"
        );
        return response;
    }

    // @dev : decoder functions
    // @notice : decoders won't revert for bad char in input, GI-GO

    function hexStringToBytes(bytes memory input) public pure returns (bytes memory output) {
        require(input.length % 2 == 0, "BAD_LENGTH");
        uint8 a;
        uint8 b;
        uint8 c;
        unchecked {
            uint256 len = input.length / 2;
            output = new bytes(len);
            while (c < len) {
                b = uint8(input[2 * c]) - 48;
                a = (b < 10) ? b : b - 39;
                b = uint8(input[2 * c + 1]) - 48;
                b = (b < 10) ? b : b - 39;
                output[c++] = bytes1((a * 16) + b);
            }
        }
    }

    function decodeBase32(bytes memory input) public pure returns (bytes memory) {
        require(input[0] == bytes1("b"), "Invalid Base32 Prefix");
        uint256 value;
        uint256 bits;
        uint256 index;
        uint256 len = input.length;
        uint8 b;
        unchecked {
            bytes memory output = new bytes(((len - 1) * 5) / 8);
            for (uint256 i = 1; i < len; ++i) {
                b = uint8(input[i]) - 97;
                value = (value << 5) | ((b < 27) ? b : b + 73);
                bits += 5;
                if (bits >= 8) {
                    output[index++] = bytes1(uint8(value >> (bits -= 8)));
                }
            }
            return format(output);
        }
    }

    function decodeBase36(bytes memory input) public pure returns (bytes memory output) {
        require(input[0] == bytes1("k"), "Invalid Base36 Prefix");
        uint256 slen = input.length;
        uint256 carry;
        uint256 index;
        uint256 len;
        uint8 b;
        unchecked {
            for (uint256 i = 1; i < slen;) {
                b = uint8(input[i++]) - 48;
                carry = b < 10 ? b : b - 39;
                //require(carry < 36, "Invalid Base36 Char");
                len = output.length;
                for (uint256 j = 0; j < len; j++) {
                    // TODO: Optimize, 500k view gas is too much
                    index = len - 1 - j;
                    carry = uint256(uint8(output[index])) * 36 + carry;
                    output[index] = bytes1(uint8(carry));
                    carry = carry >> 8;
                }
                if (carry > 0) {
                    output = bytes.concat(bytes1(uint8(carry)), output);
                }
            }
        }
        return format(output);
    }

    function format(bytes memory input) private pure returns (bytes memory) {
        bytes1 b = input[1];
        bytes1 prefix;
        if (b == 0x72) {
            //IPNS, libp2p-key
            prefix = 0xe5;
        } else if (b == 0x70) {
            //IPFS, dag-pb
            prefix = 0xe3;
        } else if (b == 0x71) {
            // IPLD, dag-cbor
            prefix = 0xe2;
        } else {
            revert("Unsupported Format");
        }
        return abi.encodePacked(prefix, uint8(1), input);
    }
}
