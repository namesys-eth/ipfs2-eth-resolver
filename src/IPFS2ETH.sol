// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @title : ENS Resolver As Web3 IPFS Gateway
 * @author : freetib.eth, sshmatrix.eth
 */
import "./Interface.sol";

contract IPFS2ETH is iCCIP, iERC165, iERC173 {
    address public owner;
    iCCIP public ccip2eth;
    /// @dev : Default contenthash for error page
    bytes public DefaultContenthash;

    bytes11 public immutable nameCheck = bytes11(abi.encodePacked(uint8(5), "ipfs2", uint8(3), "eth", uint8(0)));

    /// @dev : revert on fallback
    fallback() external payable {
        revert();
    }

    event ThankYou(address indexed _from, uint256 indexed _value);

    /// @dev : revert on zero receive
    receive() external payable {
        emit ThankYou(msg.sender, msg.value);
    }

    /// @dev constructor initial setup
    constructor() {
        owner = msg.sender;
        DefaultContenthash = hex"e50101720024080112206377fe7e59802cc7160886ef388d2eda7a1a6fbd48156153975e443ae8d00438";
    }

    /**
     * @dev CCIP Resolve function
     * @param name : ENS name to resolve, DNS encoded
     * @param data : data encoding specific resolver function
     * @return : triggers offchain lookup/ direct return doresn't work for ?unknown reason
     */

    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        if (name.length == 11 && bytes11(name) == nameCheck) {
            iCCIP(ccip2eth).resolve(name, data);
        } else if (bytes4(data[:4]) != iResolver.contenthash.selector) {
            revert("Not Supported");
        }
        bytes memory _response = DefaultContenthash;
        bytes1 prefix = bytes1(name[1:2]);
        unchecked {
            uint256 len = uint8(name[0]) + 1;
            if (prefix == bytes1("f")) {
                _response = hexStringToBytes(bytes.concat(name[2:len], name[len + 1:len + 33], name[len + 34:len + 66]));
            } else if (prefix == bytes1("k")) {
                _response = decodeBase36(name[2:len]);
            } else if (prefix == bytes1("e")) {
                _response = hexStringToBytes(bytes.concat(name[1:len], name[len + 1:len + 33], name[len + 34:len + 66]));
            } else if (prefix == bytes1("b")) {
                _response = decodeBase32(name[2:len]);
            }
        }
        prefix = _response[1];
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
            return abi.encode(_response);
        }
        return abi.encode(abi.encodePacked(prefix, uint8(1), _response));
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

    // @dev : helper/management functions

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only Owner");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Interface Selector
     * @param interfaceID : interface identifier
     */

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return (
            interfaceID == iCCIP.resolve.selector || interfaceID == type(iERC173).interfaceId
                || interfaceID == iResolver.setContenthash.selector || interfaceID == iERC165.supportsInterface.selector
        );
    }

    function setContenthash(bytes32, bytes calldata _contenthash) external {
        require(msg.sender == owner, "Only Owner");
        DefaultContenthash = _contenthash;
    }
    /**
     * @notice : set ccip2.eth contract for ipfs2.eth's records redirect
     * @param _ccip2eth : CCIP2.eth contract address
     */

    function setCCIP2Contract(address _ccip2eth) external {
        require(msg.sender == owner, "Only Owner");
        ccip2eth = iCCIP(_ccip2eth);
    }

    /**
     * @dev withdraw Ether to owner
     */
    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev to be used in case some fungible tokens get locked in the contract
     * @param _token : token address
     * @param _balance : amount to release
     */
    function withdraw(address _token, uint256 _balance) external {
        iToken(_token).transferFrom(address(this), owner, _balance);
    }

    /**
     * @dev to be used in case some non-fungible tokens get locked in the contract
     * @param _token : token address
     * @param _id : token ID to release
     */
    function safeWithdraw(address _token, uint256 _id) external {
        iToken(_token).safeTransferFrom(address(this), owner, _id);
    }
}
