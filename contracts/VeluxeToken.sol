// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title VeluxeToken (VLX)
 * @notice Governance-ready ERC20 token with burn, pause, role-based minting, voting power, and rescue logic.
 * @dev Security-first design:
 *      - Full premint: 100B supply minted to admin wallet at deployment.
 *      - Immutable cap: MAX_SUPPLY = 100B * 10^18.
 *      - Admin must be a contract (expected: TimelockController or multisig Safe).
 *      - Roles split (MINTER, PAUSER, OPERATOR, PARAMS).
 *      - ERC20Votes for governance and ERC20Permit for signatures.
 */
contract VeluxeToken is
    ERC20,
    ERC20Burnable,
    ERC20Votes,
    ERC20Permit,
    Pausable,
    AccessControl,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    bytes32 public constant MINTER_ROLE   = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE   = keccak256("PAUSER_ROLE");
    bytes32 public constant PARAMS_ROLE   = keccak256("PARAMS_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Immutable maximum supply of VLX (100B with 18 decimals).
    uint256 public immutable MAX_SUPPLY;

    // Rescue policy mappings
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public safeRequired;

    event TokenWhitelisted(address token);
    event TokenBlacklisted(address token);
    event TokenRescued(address token, address to, uint256 amount);

    /**
     * @notice Deploy VeluxeToken, premint full supply to admin, and assign roles.
     * @param admin Must be a contract (e.g., TimelockController or Gnosis Safe).
     */
    constructor(address admin)
        ERC20("Veluxe", "VLX")
        ERC20Permit("Veluxe") // initializes EIP712(name="Veluxe", version="1")
    {
        require(admin.code.length > 0, "Admin must be a contract");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(PARAMS_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);

        MAX_SUPPLY = 100_000_000_000 * 10 ** 18; // 100B immutable cap

        // ✅ Premint full supply to admin wallet
        _mint(admin, MAX_SUPPLY);
    }

    /// @notice Mint new VLX tokens up to the max supply (if not already fully minted).
    function mint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        nonReentrant
        whenNotPaused
    {
        uint256 currentSupply = totalSupply();
        require(currentSupply + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    /// @notice Pause all token transfers.
    function pause() external onlyRole(PAUSER_ROLE) nonReentrant {
        _pause();
    }

    /// @notice Unpause token transfers.
    function unpause() external onlyRole(PAUSER_ROLE) nonReentrant {
        _unpause();
    }

    /// @notice Whitelist a token for rescue and set SafeERC20 requirement.
    function addToWhitelist(address token, bool requireSafe) external onlyRole(PARAMS_ROLE) {
        whitelist[token] = true;
        safeRequired[token] = requireSafe;
        emit TokenWhitelisted(token);
    }

    /// @notice Remove a token from the whitelist.
    function removeFromWhitelist(address token) external onlyRole(PARAMS_ROLE) {
        whitelist[token] = false;
        safeRequired[token] = false;
    }

    /// @notice Blacklist a token from rescue.
    function addToBlacklist(address token) external onlyRole(PARAMS_ROLE) {
        blacklist[token] = true;
        emit TokenBlacklisted(token);
    }

    /// @notice Remove a token from the blacklist.
    function removeFromBlacklist(address token) external onlyRole(PARAMS_ROLE) {
        blacklist[token] = false;
    }

    /// @notice Rescue ETH or ERC20 tokens mistakenly sent to this contract.
    function rescueTokens(address token, address to, uint256 amount)
        external
        onlyRole(OPERATOR_ROLE)
        nonReentrant
    {
        require(token != address(this), "Cannot rescue VLX");
        require(whitelist[token], "Token not whitelisted");
        require(!blacklist[token], "Token blacklisted");

        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else if (safeRequired[token]) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            require(IERC20(token).transfer(to, amount), "ERC20 transfer failed");
        }

        emit TokenRescued(token, to, amount);
    }

    /// @dev Unified transfer/mint/burn hook in OZ v5.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        if (from != address(0) && to != address(0)) {
            require(!paused(), "Token transfers are paused");
        }
        super._update(from, to, value);
    }

    /// @dev Required override to resolve multiple inheritance of `nonces`.
   function nonces(address owner)
    public
    view
    override(ERC20Permit, Nonces)
    returns (uint256)
{
    return super.nonces(owner);
}



    /// @notice Accept ETH deposits (so ETH can be rescued later).
    receive() external payable {}
}
