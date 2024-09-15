// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BLOBzChapter3 is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    IERC20 public token;
    mapping(address => uint256) public claimableTokens;
    uint256 public totalClaimable = 0;
    bool public claimEnabled = false;
    uint256 public claimLimit;

    // events
    event CanClaim(address indexed recipient, uint256 amount);
    event HasClaimed(address indexed recipient, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    // setup contract (owner)
    function setToken(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }
    function setClaimLimit(uint256 newLimit) external onlyOwner {
        claimLimit = newLimit;
    }
    function setRecipients(address[] calldata _recipients, uint256[] calldata _claimableAmount)
        external
        onlyOwner
    {
        require(
            _recipients.length == _claimableAmount.length, "invalid array length"
        );
        uint256 sum = totalClaimable;
        for (uint256 i = 0; i < _recipients.length; i++) {
            claimableTokens[_recipients[i]] = _claimableAmount[i];
            emit CanClaim(_recipients[i], _claimableAmount[i]);
            unchecked {
                sum += _claimableAmount[i];
            }
        }
        totalClaimable = sum;
    }
    function toggleClaim() external onlyOwner {
        claimEnabled = !claimEnabled;
    }
    function resetTotalClaimable() external onlyOwner {
        totalClaimable = 0;
    }
    function withdraw(uint256 amount) external onlyOwner {
        require(token.transfer(msg.sender, amount), "fail transfer token");
        emit Withdrawal(msg.sender, amount);
    }

    // claim token
    function claim() external {
        require(claimEnabled, "claim is not enabled");

        uint256 amount = claimableTokens[msg.sender];
        require(amount > 0, "nothing to claim");
        require(amount <= claimLimit, "over claim limit");
        require(amount <= token.balanceOf(address(this)), "not enough token");

        claimableTokens[msg.sender] = 0;

        // we don't use safeTransfer since impl is assumed to be OZ
        require(token.transfer(msg.sender, amount), "fail token transfer");
        emit HasClaimed(msg.sender, amount);
    }

}
