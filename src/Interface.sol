//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;

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

    function signedBy(bytes32 digest, bytes calldata signature) external pure returns (address _addr);
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
