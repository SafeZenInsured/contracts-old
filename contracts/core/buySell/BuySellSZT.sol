// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract BuySellSZT is Ownable, IBuySellSZT{
    uint256 public constant SZTBasePrice = 100;  // SZT token base price
    uint256 public tokenCounter = 0;  // SZT tokens in circulation
    uint256 private constant _SZTBasePriceWithDecimals = 100 * 1e18; // SZT token base price with decimals
    uint256 private immutable _commonRatio;  // common ratio for SZT YUVAA calculations
    IERC20 private SafeZenToken; // native SZT token
    IERC20Extended private SafeZenGovernanceToken; // native GSZT token
    IERC20 private DAI; // DAI address

    /// @dev adds the sell timer, allowing user to sell only after the specified time period
    /// @param ifTimerStarted: checks if the sell timer has started
    /// @param SZTTokenCount: record the number of tokens user wishes to sell
    /// @param canWithdrawTime: record the time when user can sell their tokens to BuySell Contract
    struct sellWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    /// @dev record the user penalty [governance, if they try to cheat in the claim and governance decisions]
    mapping (address => uint256) private userSZTPenalty; 
    /// @dev map each user address with the sellWaitPeriod struct
    mapping (address => sellWaitPeriod) private checkWaitTime;
    
    /// @dev non-changable commonRatio, needed for non-speculation part of our SZT tokens
    constructor(uint value, uint decimals) {
        _commonRatio = (value * 10e17) / (10 ** decimals);
        
    }

    /// NOTE only needed for testnet, then we can set IERC20(DAI) in the constructor itself
    function setDAITokenCA(address _DAITokenCA) external onlyOwner {
        DAI = IERC20(_DAITokenCA);
    }

    /// @dev to set the address of our SZT token
    /// @param _safeZenTokenCA: address of the SZT token
    function setSafeZenTokenCA(address _safeZenTokenCA) external onlyOwner {
        SafeZenToken = IERC20(_safeZenTokenCA);
    }

    /// @dev to set the address of our GSZT token
    /// @param _SafeZenGovernanceTokenCA: address of the GSZT token
    function setSafeZenGovernanceTokenCA(address _SafeZenGovernanceTokenCA) external onlyOwner {
        SafeZenGovernanceToken = IERC20Extended(_SafeZenGovernanceTokenCA);
    }

    
    function viewSZTCurrentPrice() view external override returns(uint) {
        uint256 SZTCommonRatio = (_commonRatio * SZTBasePrice * tokenCounter)/1e18;
        uint256 amountPerToken = (SZTBasePrice * (1e18)) + SZTCommonRatio;
        return amountPerToken;
    }
    
    function calculateSZTPrice(uint256 issuedSZTTokens, uint256 requiredTokens) view public returns(uint, uint) {
        uint256 SZTCommonRatio = _commonRatio * SZTBasePrice;
        // to avoid check everytime, we prefer to buy first token.
        // uint256 _required = requiredTokens > 1e18 ? requiredTokens - 1e18 : 1e18 - requiredTokens;
        uint256 tokenDifference = (issuedSZTTokens + (requiredTokens - 1e18));
        uint256 averageDiff = ((SZTCommonRatio * tokenDifference) / 2) / 1e18;
        uint256 amountPerToken = _SZTBasePriceWithDecimals + averageDiff;
        uint256 amountToBePaid = (amountPerToken * (requiredTokens - issuedSZTTokens))/1e18;
        return (amountPerToken, amountToBePaid);
    }

    function calculateGSZTCommonRatio(uint256 issuedSZTTokens, uint256 alpha, uint256 decimals) view internal returns(uint256) {
        uint256 GSZTcommonRatio = ((alpha * 1e18) / (10 ** decimals));
        uint256 tokenValue = (GSZTcommonRatio * SZTBasePrice * issuedSZTTokens) / 1e18;
        uint256 amountPerToken = _SZTBasePriceWithDecimals + tokenValue;
        return amountPerToken;
    }

    function demoAddPenalty(uint256 penaltyValue) external onlyOwner {
        userSZTPenalty[_msgSender()] += penaltyValue;
    }

    function calculateGSZTTokenCount(uint256 issuedSZTTokens) internal view returns(uint256) {
        uint256 commonRatioA = (SZTBasePrice * 1e36) / calculateGSZTCommonRatio(issuedSZTTokens, 17, 2);
        uint256 commonRatioB = (calculateGSZTCommonRatio(issuedSZTTokens, 22, 6) / (SZTBasePrice)) - (1e18);
        uint256 GSZTTokenCount = ((commonRatioA + commonRatioB) * issuedSZTTokens) / 1e18;
        return GSZTTokenCount;
    }
    
    error TransactionFailed();
    function mintGSZT(address _userAddress) internal {
        uint256 userSZTBalance = SafeZenToken.balanceOf(_userAddress);
        uint256 userSZTCount = userSZTBalance - userSZTPenalty[_userAddress];
        uint256 userGSZTBalance = SafeZenGovernanceToken.balanceOf(_userAddress);
        uint256 GSZTTokenCount = calculateGSZTTokenCount(userSZTCount);
        GSZTTokenCount = GSZTTokenCount > 22750 ? (userSZTBalance / 2) : GSZTTokenCount;
        uint256 toMint = (GSZTTokenCount - userGSZTBalance);
        if (toMint > 0) {
            SafeZenGovernanceToken.mint(_userAddress, toMint);
        }
    }

    function mintGSZTForInvestors(address _investorAddress, uint256 _equivalentSZTTokens) external onlyOwner {
        uint256 GSZTToMint = calculateGSZTTokenCount(_equivalentSZTTokens);
        SafeZenGovernanceToken.mint(_investorAddress, GSZTToMint);
    }

    error LowAmountError();
    function buySZTToken(uint256 _value) external override returns(bool) {
        (/*uint amountPerToken*/, uint amountToBePaid) = calculateSZTPrice(tokenCounter, (tokenCounter + _value));
        if (DAI.balanceOf(_msgSender()) < amountToBePaid) {
            revert LowAmountError();
        }
        DAI.transferFrom(_msgSender(), address(this), amountToBePaid);
        bool success = SafeZenToken.transfer( _msgSender(), _value);
        mintGSZT(_msgSender());
        tokenCounter += _value;
        if (!success) {
            revert TransactionFailedError();
        }
        emit BoughtSZT(_msgSender(), _value);
        return true;
    }

    error ZeroAddressTransactionError();
    error TransactionFailedError();

    function transferSZT(address _from, address _to, uint _value) external returns(bool) {
        if (_from == address(0) || _to == address(0) || _value == 0) {
            revert ZeroAddressTransactionError();
        }
        bool success = SafeZenToken.transferFrom(_from, _to, _value);
        mintGSZT(_to);

        if (_from != address(this)) {
            SafeZenGovernanceToken.burnFrom(_from, burnGSZTToken(_from));
        }

        if (!success) {
            revert TransactionFailedError();
        }
        emit TransferredSZT(_from, _to, _value);
        return true;
    }

    function burnGSZTToken(address _userAddress) view internal returns(uint256) {
        uint256 userSZTBalance = SafeZenToken.balanceOf(_userAddress);
        uint256 userSZTCount = userSZTBalance - userSZTPenalty[_userAddress];
        uint256 GSZTAmountToHave = calculateGSZTTokenCount(userSZTCount);
        uint256 GSZTAmountUserHave = SafeZenGovernanceToken.balanceOf(_userAddress);
        uint256 amountToBeBurned = GSZTAmountUserHave - GSZTAmountToHave;
        return amountToBeBurned;
    }

    function activateSellTimer(uint256 _value) external override returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()].SZTTokenCount < _value)
        ) {
            sellWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = _value;

            waitingTimeCountdown.canWithdrawTime = 1 days + block.timestamp;
            return true;
        }
        return false;
    }

    error LowSZTBalanceError();
    function sellSZTToken(uint256 _value) external returns(bool) {
        if (SafeZenToken.balanceOf(_msgSender()) < (_value)) {
            revert LowSZTBalanceError();
        }
        if (
            (block.timestamp >= checkWaitTime[_msgSender()].canWithdrawTime) &&
            (_value <= checkWaitTime[_msgSender()].SZTTokenCount)
        ) {
            bool SZTTransferSuccess = SafeZenToken.transferFrom(_msgSender(), address(this), _value);
            bool GSZTBurnSuccess = SafeZenGovernanceToken.burnFrom(_msgSender(), burnGSZTToken(_msgSender()));
            (/*amountPerToken*/, uint256 amountToBeReleased) = calculateSZTPrice((tokenCounter - _value), tokenCounter);
            bool DAITransferSuccess = DAI.transfer(_msgSender(), amountToBeReleased);
            if ((!DAITransferSuccess) || (!GSZTBurnSuccess) || (!SZTTransferSuccess)) {
                revert TransactionFailed();
            }
            if (checkWaitTime[_msgSender()].SZTTokenCount == _value) {
                checkWaitTime[_msgSender()].ifTimerStarted = false;
            }
            checkWaitTime[_msgSender()].SZTTokenCount -= _value;
            tokenCounter -= _value;
            return true;
        }
        return false;
    }

    function getCommonRatio() view external returns (uint256) {
        return _commonRatio;
    }

}