//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >=0.8.4;

interface iERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface iResolver {
    function contenthash(bytes32 node) external view returns (bytes memory);
}

interface iOverloadResolver {
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory);
}

interface iToken {
    function transferFrom(address from, address to, uint256 bal) external;
    function safeTransferFrom(address from, address to, uint256 bal) external;
}

interface iCCIP {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
    function __callback(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory result);
}

interface iERC173 {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
