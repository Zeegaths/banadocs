// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract StakingPool {
    IERC20 private stakeToken;
    IERC20 private rewardToken;
    uint256 public id;

    struct Pool {
      uint256 totalStakers;
      uint256 totalStaked;
      uint256 rewardReserve;
      uint256 rewardRate; // daily for example
      mapping(address => uint256) stakersBalances;
      mapping(address => uint256) stakerRewardPerSec;
      mapping(address => uint256) stakerStoredReward;
      mapping(address => uint256) stakerLastUpdatedTime;
    }

    struct PoolDataReturnedType {
      uint256 totalStakers;
      uint256 totalStaked;
      uint256 rewardReserve;
      uint256 rewardRate;
    }

    mapping(uint256 => Pool) internal pools;

    event poolCreated(uint256 PoolID, uint256 poolReward, uint256 at, address by);
    event Stake(uint256 poolID, address indexed account, uint256 indexed amount, uint256 at);
    event Unstake(uint256 poolID, address indexed account, uint256 indexed amount, uint256 at);
    event RewardClaim(uint256 poolID, address indexed account, uint256 indexed amount, uint256 at);

    constructor(address _stakeTokenAddress, address _rewardTokenAddress) {
      stakeToken = IERC20(_stakeTokenAddress);
      rewardToken = IERC20(_rewardTokenAddress);
    }

    function createPool(uint256 _rewardRate) public {
      // widthrawing the 100 pool reward token from the pool creator
      rewardToken.transferFrom(msg.sender, address(this), 1001E18);
      Pool storage p = pools[id];
      p.rewardRate = _rewardRate;
      p.rewardReserve = 0;
      emit poolCreated(id, 100E18, block.timestamp, msg.sender);
      id++;
    }

    function getPoolByID(uint256 _id) external view returns(PoolDataReturnedType memory _pool) {
       _pool = PoolDataReturnedType(pools[_id].totalStakers, pools[_id].totalStaked, pools[_id].rewardReserve, pools[_id].rewardRate);
    }


    function stake(uint256 _poolID, uint256 _amount) external {
      Pool storage p = pools[_poolID];
      stakeToken.transferFrom(msg.sender, address(this), _amount);
      // calculate the user's reward up until this moment and add it to storedReward;
      uint256 userPreviousBalance = p.stakersBalances[msg.sender];
      if(userPreviousBalance > 0) {
        uint256 previousReward = _getUserReward(_poolID, msg.sender);
        p.stakerStoredReward[msg.sender] = previousReward;
      }
      // increment stakers if their previous balance is 0, it signifies new staker,
      if(userPreviousBalance == 0) {
          p.totalStakers++;
      }

      p.stakersBalances[msg.sender] += _amount;
      p.totalStaked += _amount;
      p.stakerRewardPerSec[msg.sender] = _calculateRewardperSecond(_poolID,  p.stakersBalances[msg.sender]);
      p.stakerLastUpdatedTime[msg.sender] = block.timestamp;
      emit Stake(_poolID, msg.sender, _amount, block.timestamp);
    }


    function _calculateRewardperSecond(uint256 _poolID, uint256 _stakedAmount) private view returns(uint256 _rewardPerSecond) {
        uint256 secInDay = 1 days;
        _rewardPerSecond = (_stakedAmount * pools[_poolID].rewardRate) / secInDay;
    }


    function _getUserReward(uint256 _poolID, address _account) internal view returns(uint256 _userReward) {
        uint256 userRewardPerSec = pools[_poolID].stakerRewardPerSec[_account];
        uint256 timeElapsed = block.timestamp - pools[_poolID].stakerLastUpdatedTime[_account];
        _userReward = (userRewardPerSec * timeElapsed) + pools[_poolID].stakerStoredReward[_account];
    }

    function getUserClaimableReward(uint256 _poolID, address _staker) external view returns(uint _reward) {
      _reward = _getUserReward(_poolID, _staker);
    }


    function unstake(uint256 _poolID) external {
        Pool storage p = pools[_poolID];
        uint256 balance = p.stakersBalances[msg.sender];
        require(balance > 0, "Staking pool contract: You do not have any token staked in this pool");
        uint256 reward = _getUserReward(_poolID, msg.sender);
        p.stakersBalances[msg.sender] = 0;
        p.totalStakers--;
        p.stakerStoredReward[msg.sender] = 0;
        p.totalStaked -= balance;
        p.rewardReserve -= reward;
        stakeToken.transfer(msg.sender, balance);
        rewardToken.transfer(msg.sender, reward);
        emit Unstake(_poolID, msg.sender, balance, block.timestamp);
    }

    function claimReward(uint256 _poolID) external {
        Pool storage p = pools[_poolID];
        uint256 reward = _getUserReward(_poolID, msg.sender);
        require(reward > 0, "Staking pool contract: You do not have any reward to be claimed in this pool");
        p.stakerLastUpdatedTime[msg.sender] = block.timestamp;
        p.rewardReserve -= reward;
        p.stakerStoredReward[msg.sender] = 0;
        require(rewardToken.transfer(msg.sender, reward));
        emit RewardClaim(_poolID, msg.sender, reward, block.timestamp);
    }


    function getUserStakeBalance(uint256 _poolID, address _account) external view returns(uint256 _stake) {
        _stake = pools[_poolID].stakersBalances[_account];
    }

    function getUserPoolRewardPerSec(uint256 _poolID, address _account) external view returns(uint256 _rewardPerSecond) {
        _rewardPerSecond = pools[_poolID].stakerRewardPerSec[_account];
    }

}