//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGovToken {
    function getDaoMembersAmount() external view returns(uint);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}