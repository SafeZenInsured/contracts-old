// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./../../../interfaces/IERC20.sol";
import "./../../../interfaces/IERC20Extended.sol";
import "./../../../interfaces/IBuySellSZT.sol";
import "./../../../interfaces/ISZTStaking.sol";
import "./../../../interfaces/ICoveragePool.sol";
import "./../../dependencies/openzeppelin/Ownable.sol";
import "./../../dependencies/openzeppelin/Pausable.sol";

/// Report any bug or issues at:
/// @custom:security-contact anshik@safezen.finance
contract BuySellSZT is Ownable, IBuySellSZT, Pausable {
    uint256 public constant SZTBasePrice = 100;  // SZT token base price
    uint256 public tokenCounter = 0;  // SZT tokens in circulation
    uint256 public constant SZTBasePriceWithDecimals = 100 * 1e18; // SZT token base price with decimals
    uint256 private immutable _commonRatio;  // common ratio for SZT YUVAA calculations
    IERC20 private SafeZenToken; // native SZT token
    IERC20Extended private SafeZenGovernanceToken; // native GSZT token
    IERC20 private DAI; // DAI address
    ISZTStaking private SZTStaking; 
    ICoveragePool private CoveragePool;

    /// @dev adds the sell timer, allowing user to sell only after the specified time period
    /// @param ifTimerStarted: checks if the sell timer has started
    /// @param SZTTokenCount: record the number of tokens user wishes to sell
    /// @param canWithdrawTime: record the time when user can sell their tokens to BuySell Contract
    struct SellWaitPeriod{
        bool ifTimerStarted;
        uint256 SZTTokenCount;
        uint256 canWithdrawTime;
    }

    /// @dev record the user penalty [governance, if they try to cheat in the claim and governance decisions]
    mapping (address => uint256) private userSZTPenalty; 
    /// @dev map each user address with the sellWaitPeriod struct
    mapping (address => SellWaitPeriod) private checkWaitTime;
    
    /// @dev non-changable commonRatio, needed for non-speculation part of our SZT tokens
    /// @param value: value of the common Ratio
    /// @param decimals: decimals against the value of the commmon ratio
    constructor(uint value, uint decimals) {
        _commonRatio = (value * 10e17) / (10 ** decimals);  
    }

    /// @dev to set the address of the DAI token
    /// NOTE: DAI to be an immutable variable, created function for testing purposes
    /// @param _DAIaddress: address of the DAI token
    function setDAIAddress(address _DAIaddress) external onlyOwner {
        DAI = IERC20(_DAIaddress);
    }

    /// @dev to set the address of our SZT token
    /// @param _safeZenTokenCA: address of the SZT token
    function setSafeZenTokenCA(address _safeZenTokenCA) external onlyOwner {
        SafeZenToken = IERC20(_safeZenTokenCA);
    }

    /// @dev to set the address of SZT staking contract
    /// @param _SZTStakingCA: address of the SZT staking contract
    function setSZTStakingCA(address _SZTStakingCA) external onlyOwner {
        SZTStaking = ISZTStaking(_SZTStakingCA);
    }

    /// @dev to set the address of the pay-as-you-go-coverage pool contract
    /// @param _coveragePoolCA: address of the coverage pool contract
    function setCoveragePoolCA(address _coveragePoolCA) external onlyOwner {
        CoveragePool = ICoveragePool(_coveragePoolCA);
    }

    /// @dev to set the address of our GSZT token
    /// @param _SafeZenGovernanceTokenCA: address of the GSZT token
    function setSafeZenGovernanceTokenCA(address _SafeZenGovernanceTokenCA) external onlyOwner {
        SafeZenGovernanceToken = IERC20Extended(_SafeZenGovernanceTokenCA);
    }

    /// @dev check the current SZT token price
    function viewSZTCurrentPrice() view external override returns(uint) {
        uint256 SZTCommonRatio = (_commonRatio * SZTBasePrice * tokenCounter)/1e18;
        uint256 amountPerToken = (SZTBasePrice * (1e18)) + SZTCommonRatio;
        return amountPerToken;
    }
    
    /// @dev calculate the SZT token value for the asked amount of SZT tokens
    /// @param issuedSZTTokens: the amount of SZT tokens currently in circulation
    /// @param requiredTokens: issuedSZTTokens + the amount of SZT tokens required
    function calculateSZTPrice(uint256 issuedSZTTokens, uint256 requiredTokens) view public returns(uint, uint) {
        uint256 SZTCommonRatio = _commonRatio * SZTBasePrice;
        // to avoid check everytime, we prefer to buy first token.
        // uint256 _required = requiredTokens > 1e18 ? requiredTokens - 1e18 : 1e18 - requiredTokens;
        uint256 tokenDifference = (issuedSZTTokens + (requiredTokens - 1e18));
        uint256 averageDiff = ((SZTCommonRatio * tokenDifference) / 2) / 1e18;
        uint256 amountPerToken = SZTBasePriceWithDecimals + averageDiff;
        uint256 amountToBePaid = (amountPerToken * (requiredTokens - issuedSZTTokens))/1e18;
        return (amountPerToken, amountToBePaid);
    }

    /// @dev calculate the common ratio for the GSZT token calculation
    /// @param issuedSZTTokens: amount of SZT tokens currently in circulation
    /// @param alpha: alpha value for the calculation of GSZT token
    /// @param decimals: to calculate the actual alpha value for GSZT tokens 
    function calculateGSZTCommonRatio(uint256 issuedSZTTokens, uint256 alpha, uint256 decimals) pure internal returns(uint256) {
        uint256 GSZTcommonRatio = ((alpha * 1e18) / (10 ** decimals));
        uint256 tokenValue = (GSZTcommonRatio * SZTBasePrice * issuedSZTTokens) / 1e18;
        uint256 amountPerToken = SZTBasePriceWithDecimals + tokenValue;
        return amountPerToken;
    }

    /// @dev for assigning the penalty incase user cheats or give false info in our governance or claim processing
    /// @param penaltyValue: amount of tokens the user will be penalized [based on our whitepaper]
    function demoAddPenalty(uint256 penaltyValue) external onlyOwner {
        userSZTPenalty[_msgSender()] += penaltyValue;
    }

    /// @dev calculating the GSZT token to be awarded to user based on the amount of SZT token user have
    /// @param issuedSZTTokens: amount of issued SZT tokens to user    
    function calculateGSZTTokenCount(uint256 issuedSZTTokens) internal pure returns(uint256) {
        uint256 commonRatioA = (SZTBasePrice * 1e36) / calculateGSZTCommonRatio(issuedSZTTokens, 17, 2);
        uint256 commonRatioB = (calculateGSZTCommonRatio(issuedSZTTokens, 22, 6) / (SZTBasePrice)) - (1e18);
        uint256 GSZTTokenCount = ((commonRatioA + commonRatioB) * issuedSZTTokens) / 1e18;
        return GSZTTokenCount;
    }
    
    error TransactionFailed();
    /// @dev minting the GSZT tokens to the provided user address
    /// @param _userAddress: user address
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

    /// @dev minting the tokens to investors based on the price of equivalent SZT token
    /// NOTE: few withdraw implementations needed to be made
    /// @param _investorAddress: wallet address of the investors (can be a Gnosis Safe account)
    /// @param _equivalentSZTTokens: equivalent SZT tokens based on the amount invested
    function mintGSZTForInvestors(address _investorAddress, uint256 _equivalentSZTTokens) external onlyOwner {
        uint256 GSZTToMint = calculateGSZTTokenCount(_equivalentSZTTokens);
        SafeZenGovernanceToken.mint(_investorAddress, GSZTToMint);
    }

    function transferGSZTforInvestors(address _investorAddress, address _newInvestorAddress) external onlyOwner {
        uint256 GSZTBalance = SafeZenGovernanceToken.balanceOf(_investorAddress);
        SafeZenGovernanceToken.burnFrom(_investorAddress, GSZTBalance);
        SafeZenGovernanceToken.mint(_newInvestorAddress, GSZTBalance);
    }

    error LowAmountError();
    /// @dev buying our native non-speculative SZT token
    /// @param _value: amount of SZT tokens user wishes to purchase
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
    /// @dev transfer function for SZT [and GSZT tokens]
    /// @param _from: sending user address
    /// @param _to: receiving user address
    /// @param _value: amount of SZT tokens user [sending address] wishes to transfer to other user [receiving address]
    function transferSZT(address _from, address _to, uint _value) external override returns(bool) {
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

    modifier onlySZTStakingContract() {
        require(_msgSender() == address(SZTStaking));
        _;
    }

    function stakingTransferSZT(address _from, address _to, uint _value) external override onlySZTStakingContract returns(bool) {
        bool success = SafeZenToken.transferFrom(_from, _to, _value);
        if (_to != address(SZTStaking)) {
          mintGSZT(_to);  
        }
        return success;
    }

    /// @dev Burning the GSZT token
    /// @param _userAddress: wallet address of the user
    function burnGSZTToken(address _userAddress) view internal returns(uint256) {
        uint256 userSZTBalance = SafeZenToken.balanceOf(_userAddress);
        uint256 userSZTCount = userSZTBalance - userSZTPenalty[_userAddress];
        uint256 GSZTAmountToHave = calculateGSZTTokenCount(userSZTCount);
        uint256 GSZTAmountUserHave = SafeZenGovernanceToken.balanceOf(_userAddress);
        uint256 amountToBeBurned = GSZTAmountUserHave - GSZTAmountToHave;
        return amountToBeBurned;
    }

    uint256 public sellTimer = 1 minutes;
    /// NOTE: Changing minutes to day [minutes done for testing purpose]
    function setWithdrawTime(uint256 _time) external onlyOwner {
        sellTimer = _time * 1 minutes;
    }
    /// @dev activating the timer if the user wishes to sell his/her/their tokens [to prevent front running]
    /// @param _value: the amount of token user wishes to withdraw
    function activateSellTimer(uint256 _value) external override returns(bool) {
        if (
            (!(checkWaitTime[_msgSender()].ifTimerStarted)) || 
            (checkWaitTime[_msgSender()].SZTTokenCount < _value)
        ) {
            SellWaitPeriod storage waitingTimeCountdown = checkWaitTime[_msgSender()];
            waitingTimeCountdown.ifTimerStarted = true;
            waitingTimeCountdown.SZTTokenCount = _value;

            waitingTimeCountdown.canWithdrawTime = sellTimer + block.timestamp;
            return true;
        }
        return false;
    }

    error LowSZTBalanceError();
    /// NOTE: approve SZT and GSZT amount to BuySellContract before calling this function
    /// @dev selling the SZT tokens
    /// @param _value: the amounnt of SZT tokens user wishes to sell
    function sellSZTToken(uint256 _value) external whenNotPaused returns(bool) {
        if (SafeZenToken.balanceOf(_msgSender()) < (_value)) {
            revert LowSZTBalanceError();
        }
        if (
            (block.timestamp >= checkWaitTime[_msgSender()].canWithdrawTime) &&
            (_value <= checkWaitTime[_msgSender()].SZTTokenCount)
        ) {
            uint256 tokenCount = getSZTTokenCount();
            bool SZTTransferSuccess = SafeZenToken.transferFrom(_msgSender(), address(this), _value);
            bool GSZTBurnSuccess = SafeZenGovernanceToken.burnFrom(_msgSender(), burnGSZTToken(_msgSender()));
            (/*amountPerToken*/, uint256 amountToBeReleased) = calculateSZTPrice((tokenCount - _value), tokenCount);
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

    /// @dev to check the common ratio used in the price calculation of SZT token 
    function getCommonRatio() view external returns (uint256) {
        return _commonRatio;
    }

    /// @dev returns the token in circulation - tokens staked [IMP.]
    function getSZTTokenCount() public view override returns(uint256) {
        uint256 tokenCount = ((tokenCounter - SZTStaking.totalTokensStaked()) - CoveragePool.totalTokensStaked());
        return tokenCount;
    }

}