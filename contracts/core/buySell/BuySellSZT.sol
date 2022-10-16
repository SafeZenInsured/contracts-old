// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/ICoveragePool.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";
import "./../../dependencies/openzeppelin/ReentrancyGuard.sol";

/// @title Buy Sell SZT Contract
/// @author Anshik Bansal <anshik@safezen.finance>

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract BuySellSZT is Ownable, IBuySellSZT, Pausable, ReentrancyGuard {
    // SZT token base price
    uint256 private constant SZT_BASE_PRICE = 100;
    // SZT token base price with decimals
    uint256 private constant SZT_BASE_PRICE_WITH_DEC = 100 * 1e18;
    // SZT tokens in circulation
    uint256 private _tokenCounter;
    // common ratio for SZT YUVAA calculations
    uint256 private immutable _commonRatio;
    // native SZT token
    IERC20 private _safezenToken;
    // native GSZT token
    IERC20Extended private _safezenGovernanceToken;
    // DAI token
    IERC20 private immutable _tokenDAI;
    // SZT Staking Contract
    ISZTStaking private _staking;
    // Coverage Pool Contract
    ICoveragePool private _coveragePool;
    
    /// @dev immutable commonRatio, needed for non-speculation part of our SZT tokens & initializing _tokenDAI
    /// @param _value: value of the common Ratio
    /// @param _decimals: decimals against the value of the commmon ratio
    /// @param __tokenDAIaddress: address of the _tokenDAI token
    constructor(uint256 _value, uint256 _decimals, address __tokenDAIaddress) {
        _commonRatio = (_value * 10e17) / (10 ** _decimals); 
        _tokenDAI = IERC20(__tokenDAIaddress); 
    }

    error LowAmountError();
    error LowSZTBalanceError();
    error GSZTBurnFailedError();
    error GSZTMintFailedError();
    error TransactionFailedError();
    error ZeroAddressTransactionError();

    /// @dev to set the address of our SZT token
    /// @param safeZenTokenAddress: address of the SZT token
    function setSafeZenTokenCA(address safeZenTokenAddress) external onlyOwner {
        _safezenToken = IERC20(safeZenTokenAddress);
    }

    /// @dev to set the address of SZT staking contract
    /// @param stakingContractAddress: address of the SZT staking contract
    function setSZTStakingCA(address stakingContractAddress) external onlyOwner {
        _staking = ISZTStaking(stakingContractAddress);
    }

    /// @dev to set the address of the pay-as-you-go-coverage pool contract
    /// @param coveragePoolAddress: address of the coverage pool contract
    function setCoveragePoolCA(address coveragePoolAddress) external onlyOwner {
        _coveragePool = ICoveragePool(coveragePoolAddress);
    }

    /// @dev to set the address of our GSZT token
    /// @param safezenGovernanceTokenCA: address of the GSZT token
    function setSafeZenGovernanceTokenCA(
        address safezenGovernanceTokenCA
    ) external onlyOwner {
        _safezenGovernanceToken = IERC20Extended(safezenGovernanceTokenCA);
    }

    /// @dev buying our native non-speculative SZT token
    /// @param value: amount of SZT tokens user wishes to purchase
    function buySZTToken(uint256 value) external override nonReentrant returns(bool) {
        if ((_tokenCounter < 1e18) && (value < 1e18)) {
            revert LowAmountError();
        }
        (/*uint256 amountPerToken*/, uint256 amountToBePaid) = calculateSZTPrice(
            _tokenCounter, (_tokenCounter + value)
        );
        if (_tokenDAI.balanceOf(_msgSender()) < amountToBePaid) {
            revert LowAmountError();
        }
        _tokenCounter += value;
        bool transferSuccess_tokenDAI = _tokenDAI.transferFrom(_msgSender(), address(this), amountToBePaid);
        bool transferSuccessSZT = _safezenToken.transfer(_msgSender(), value);
        bool mintSuccessGSZT = mintGSZT(_msgSender());
        if ((!transferSuccess_tokenDAI) || (!transferSuccessSZT) || (!mintSuccessGSZT)) {
            revert TransactionFailedError();
        }
        emit BoughtSZT(_msgSender(), value);
        return true;
    }
    
    /// NOTE: approve SZT and GSZT amount to BuySellContract before calling this function
    /// @dev selling the SZT tokens
    /// @param value: the amounnt of SZT tokens user wishes to sell
    function sellSZTToken(uint256 value) external override whenNotPaused nonReentrant returns(bool) {
        if (_safezenToken.balanceOf(_msgSender()) < (value)) {
            revert LowSZTBalanceError();
        }
        uint256 tokenCount = getSZTTokenCount();
        (/*amountPerToken*/, uint256 amountToBeReleased) = calculateSZTPrice(
            (tokenCount - value), tokenCount
        );
        _tokenCounter -= value;
        bool transferSuccessSZT = _safezenToken.transferFrom(_msgSender(), address(this), value);
        bool burnSuccessGSZT = _safezenGovernanceToken.burnFrom(
            _msgSender(), burnGSZTToken(_msgSender())
        );
        bool _tokenDAITransferSuccess = _tokenDAI.transfer(_msgSender(), amountToBeReleased);
        if ((!_tokenDAITransferSuccess) || (!burnSuccessGSZT) || (!transferSuccessSZT)) {
            revert TransactionFailedError();
        }
        emit SoldSZT(_msgSender(), value);
        return true;
    }

    /// @dev minting the tokens to investors based on the price of equivalent SZT token
    /// @param investorAddress: wallet address of the investors (can be a Gnosis Safe account)
    /// @param equivalentSZTTokens: equivalent SZT tokens based on the amount invested
    function mintGSZTForInvestors(
        address investorAddress, 
        uint256 equivalentSZTTokens
    ) external onlyOwner returns(bool) {
        uint256 toMintGSZT = calculateGSZTTokenCount(equivalentSZTTokens);
        bool success = _safezenGovernanceToken.mint(investorAddress, toMintGSZT);
        if (!success) {
            revert TransactionFailedError();
        }
        emit GSZTMint(investorAddress, toMintGSZT);
        return true;
    }

    /// @dev transferring tokens from one investor to a new investor
    /// @param investorAddress: address of the initial investor
    /// @param newInvestorAddress: address of the new investor
    function transferGSZTforInvestors(
        address investorAddress, 
        address newInvestorAddress
    ) external onlyOwner returns(bool){
        uint256 balanceGSZT = _safezenGovernanceToken.balanceOf(investorAddress);
        bool burnSuccessGSZT = _safezenGovernanceToken.burnFrom(investorAddress, balanceGSZT);
        bool mintSuccessGSZT = _safezenGovernanceToken.mint(newInvestorAddress, balanceGSZT);
        if ((!burnSuccessGSZT) || (!mintSuccessGSZT)) {
            revert TransactionFailedError();
        }
        emit GSZTOwnershipTransferred(investorAddress, newInvestorAddress, balanceGSZT);
        return true;
    }

    /// @dev minting the GSZT tokens to the provided user address
    /// @param userAddress: user address
    function mintGSZT(address userAddress) internal returns(bool) {
        uint256 userSZTBalance = _safezenToken.balanceOf(userAddress);
        uint256 amountStaked = _staking.getUserStakedSZTBalance() + _coveragePool.getUnderwriteSZTBalance();
        uint256 tokenCountGSZT = calculateGSZTTokenCount(userSZTBalance + amountStaked);
        tokenCountGSZT = (tokenCountGSZT > (22750 * 1e18)) ? (userSZTBalance / 2) : tokenCountGSZT;
        uint256 userGSZTBalance = _safezenGovernanceToken.balanceOf(userAddress);
        uint256 toMint = tokenCountGSZT - userGSZTBalance;
        bool success = _safezenGovernanceToken.mint(userAddress, toMint);
        if (!success) {
            revert GSZTMintFailedError(); 
        }
        emit GSZTMint(userAddress, toMint);
        return true;
    }

    /// @dev check the current SZT token price
    function viewSZTCurrentPrice() external view override returns(uint256) {
        uint256 SZTCommonRatio = (_commonRatio * SZT_BASE_PRICE * _tokenCounter)/1e18;
        uint256 amountPerToken = (SZT_BASE_PRICE * (1e18)) + SZTCommonRatio;
        return amountPerToken;
    }
    
    /// @dev calculate the SZT token value for the asked amount of SZT tokens
    /// @param issuedSZTTokens: the amount of SZT tokens currently in circulation
    /// @param requiredTokens: issuedSZTTokens + the amount of SZT tokens required
    function calculateSZTPrice(
        uint256 issuedSZTTokens, 
        uint256 requiredTokens
    ) public view override returns(uint256, uint256) {
        uint256 commonRatioSZT = _commonRatio * SZT_BASE_PRICE;
        // to avoid check everytime, we prefer to buy first token.
        // uint256 _required = requiredTokens > 1e18 ? requiredTokens - 1e18 : 1e18 - requiredTokens;
        uint256 tokenDifference = (issuedSZTTokens + (requiredTokens - 1e18));
        uint256 averageDiff = ((commonRatioSZT * tokenDifference) / 2) / 1e18;
        uint256 amountPerToken = SZT_BASE_PRICE_WITH_DEC + averageDiff;
        uint256 amountToBePaid = (amountPerToken * (requiredTokens - issuedSZTTokens))/1e18;
        return (amountPerToken, amountToBePaid);
    }

    /// @dev calculate the common ratio for the GSZT token calculation
    /// @param issuedSZTTokens: amount of SZT tokens currently in circulation
    /// @param alpha: alpha value for the calculation of GSZT token
    /// @param decimals: to calculate the actual alpha value for GSZT tokens 
    function calculateGSZTCommonRatio(
        uint256 issuedSZTTokens, 
        uint256 alpha, 
        uint256 decimals
    ) internal pure returns(uint256) {
        uint256 mantissa = 10 ** decimals;
        uint256 tokenValue = (alpha * SZT_BASE_PRICE * issuedSZTTokens) / mantissa;
        uint256 amountPerToken = SZT_BASE_PRICE_WITH_DEC + tokenValue;
        return amountPerToken;
    }

    /// @dev Burning the GSZT token
    /// @param userAddress: wallet address of the user
    function burnGSZTToken(address userAddress) internal view returns(uint256) {
        uint256 userSZTBalance = _safezenToken.balanceOf(userAddress);
        uint256 amountStaked = _staking.getUserStakedSZTBalance() + _coveragePool.getUnderwriteSZTBalance();
        uint256 GSZTAmountToHave = calculateGSZTTokenCount(userSZTBalance + amountStaked);
        uint256 GSZTAmountUserHave = _safezenGovernanceToken.balanceOf(userAddress);
        uint256 amountToBeBurned = GSZTAmountUserHave - GSZTAmountToHave;
        return amountToBeBurned;
    }

    /// @dev calculating the GSZT token to be awarded to user based on the amount of SZT token user have
    /// @param issuedSZTTokens: amount of issued SZT tokens to user    
    function calculateGSZTTokenCount(
        uint256 issuedSZTTokens
    ) internal pure returns(uint256) {
        uint256 commonRatioA = (
            (SZT_BASE_PRICE * 1e36) / 
            calculateGSZTCommonRatio(issuedSZTTokens, 17, 2)
        );
        uint256 commonRatioB = (
            (calculateGSZTCommonRatio(issuedSZTTokens, 22, 6) / 
            (SZT_BASE_PRICE)) - (1e18)
        );
        uint256 GSZTTokenCount = ((commonRatioA + commonRatioB) * issuedSZTTokens) / 1e18;
        return GSZTTokenCount;
    }

    /// @dev to check the common ratio used in the price calculation of SZT token 
    function getCommonRatio() external view returns (uint256) {
        return _commonRatio;
    }

    /// @dev returns the token in circulation - tokens staked [IMP.]
    function getSZTTokenCount() public view override returns(uint256) {
        uint256 tokenCount = (
            (_tokenCounter - _staking.totalTokensStaked()) - 
            _coveragePool.totalTokensStaked()
        );
        return tokenCount;
    }

    function getTokenCounter() public view returns(uint256) {
        return _tokenCounter;
    }

    function getSZTBasePrice() public pure returns(uint256) {
        return SZT_BASE_PRICE_WITH_DEC;
    }
}