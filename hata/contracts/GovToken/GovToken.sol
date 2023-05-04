//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GovToken is ERC1155, AccessControl {
    uint public daoMembersAmount;
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNMENT_ROLE = keccak256("MINTER_ROLE");


    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(GOVERNMENT_ROLE, msg.sender);
        daoMembersAmount = 0;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        //require(balanceOf(account, id) <= 1, "Can mint only one!");
        // id always the same, it is zero
        require(amount == 1, "Can mint only 1 NFT!");
        _grantRole(GOVERNMENT_ROLE, account);
        _mint(account, id, amount, "");
        daoMembersAmount += 1;
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getDaoMembersAmount() external view returns(uint){
        return daoMembersAmount;
    }
}