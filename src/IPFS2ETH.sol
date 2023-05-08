// SPDX-License-Identifier: WTFPL.ETH
pragma solidity > 0.8.0 <0.9.0;

/**
 * @title : ENS Resolver As Web3 IPFS Gateway
 * @author : freetib.eth, sshmatrix.eth
 */
import "./Interface.sol";

contract IPFS2ETH is iCCIP, iERC165, iERC173 {
    address public owner;

    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    bytes11 public immutable suffixCheck = bytes11(abi.encodePacked(uint8(5), "ipfs2", uint8(3), "eth", uint8(0)));

    event ThankYou(address indexed _from, uint256 indexed _value);

    /// @dev : revert on zero receive
    receive() external payable {
        if (msg.value == 0) revert();
        emit ThankYou(msg.sender, msg.value);
    }

    /// @dev constructor initial setup
    constructor() {
        owner = msg.sender;
        HomeContenthash = hex"e50101720024080112206377fe7e59802cc7160886ef388d2eda7a1a6fbd48156153975e443ae8d00438";
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

    bytes public HomeContenthash;

    function setContenthash(bytes32 node, bytes calldata _contenthash) external {
        require(msg.sender == owner, "Only Owner");
        HomeContenthash = _contenthash;
    }
    /**
     * @dev core Resolve function
     * @param name : ENS name to resolve, DNS encoded
     * @param data : data encoding specific resolver function
     * @return : triggers offchain lookup so return value is never used directly
     */

    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        require(bytes4(data[:4]) == iResolver.contenthash.selector, "Only Contehthash Supported");
        bytes memory _response;
        unchecked {
            uint256 len = uint8(name[0]) + 1;
            bytes1 b1 = bytes1(name[1:2]);
            if (b1 == bytes1("f")) {
                // f<bytesX>.bytes16.bytes16.ipfs2.eth.limo
                //require(
                //    uint8(name[len]) == uint8(32) && uint8(name[len + 33]) == uint8(32) && len + 77 == name.length,
                //    "Invalid Subdomain Format"
                //);
                _response = hexStringToBytes(bytes.concat(name[2:len], name[len + 1:len + 33], name[len + 34:len + 66]));
            } else if (b1 == bytes1("e")) {
                _response = hexStringToBytes(bytes.concat(name[1:len], name[len + 1:len + 33], name[len + 34:len + 66]));
            } else if (b1 == bytes1("b")) {
                //require(bytes11(name[len:]) == suffixCheck, "Invalid Subdomain Format");
                _response = decodeBase32(name[2:len]);
            } else if (b1 == bytes1("k")) {
                //require(bytes11(name[len:]) == suffixCheck, "Invalid Subdomain Format");
                _response = decodeBase36(name[2:len]);
            } else {
                __lookup(HomeContenthash);
            }
        }
        __lookup(_response);
    }
    /**
     * @dev
     * @param _contenthash :
     */

    function __lookup(bytes memory _contenthash) private view {
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:application/json,{"data":"{data}"}';
        _urls[1] = 'data:text/plain,{"data":"{data}"}';
        revert OffchainLookup(
            address(this),
            _urls,
            _contenthash,
            IPFS2ETH.__callback.selector,
            abi.encode(
                block.number - 1,
                keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), msg.sender, _contenthash))
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
        bytes1 prefix = response[1];
        if (prefix == 0x72) {
            //IPNS, libp2p-key
            prefix = 0xe5;
        } else if (prefix == 0x70) {
            //IPFS, dag-pb
            prefix = 0xe3;
        } else if (prefix == 0x71) {
            //?IPLD, dag-cbor
            prefix = 0xe2;
        } else {
            return abi.encode(response);
        }
        return abi.encode(abi.encodePacked(prefix, uint8(1), response));
    }

    // @dev : decoder functions
    // @notice : decoders won't revert for bad char in input, GIGO

    function hexStringToBytes(bytes memory input) public pure returns (bytes memory output) {
        require(input.length % 2 == 0, "BAD_LENGTH");
        uint8 a;
        uint8 b;
        uint256 c;
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

    function decodeBase32(bytes memory input) public pure returns (bytes memory output) {
        uint256 value;
        uint256 bits;
        uint256 index;
        uint256 len = input.length;
        uint8 b;
        unchecked {
            output = new bytes((len * 5) / 8);
            for (uint256 i; i < len; ++i) {
                b = uint8(input[i]) - 97;
                value = (value << 5) | ((b < 27) ? b : b + 73);
                bits += 5;
                if (bits > 7) {
                    output[index++] = bytes1(uint8(value >> (bits -= 8)));
                }
            }
            return output;
        }
    }

    function decodeBase36(bytes memory input) public pure returns (bytes memory output) {
        uint256 slen = input.length;
        uint256 carry;
        uint256 index;
        uint256 len;
        uint8 b;
        unchecked {
            for (uint256 i; i < slen;) {
                b = uint8(input[i++]) - 48;
                carry = b < 10 ? b : b - 39;
                len = output.length;
                for (uint256 j = 0; j < len; j++) {
                    // TODO: Optimize loop steps, ~500k view gas is too much
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
    }
}
