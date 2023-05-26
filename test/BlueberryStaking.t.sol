// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../src/BlueberryStaking.sol";
import "../src/BlueberryToken.sol";
import "../src/MockbToken.sol";

contract BlueberryStakingTest is Test {
    BlueberryStaking blueberryStaking;
    BlueberryToken blb;
    IERC20 mockbToken1;
    IERC20 mockbToken2;
    IERC20 mockbToken3;

    address public endUser = address(0x1);

    address[] public existingBTokens;
    
    function setUp() public {
        mockbToken1 = new MockbToken();
        mockbToken2 = new MockbToken();
        mockbToken3 = new MockbToken();

        blb = new BlueberryToken(address(this), address(this), block.timestamp + 30);

        existingBTokens = new address[](3);

        existingBTokens[0] = address(mockbToken1);
        existingBTokens[1] = address(mockbToken2);
        existingBTokens[2] = address(mockbToken3);

        blueberryStaking = new BlueberryStaking(address(blb), 1_209_600, existingBTokens);

        blb.setMinter(address(blueberryStaking));
    }

    function testSetVestLength() public {
        blueberryStaking.setVestLength(69_420);
        assertEq(blueberryStaking.vestLength(), 69_420);
    }

    function testSetRewardDuration() public {
        blueberryStaking.setRewardDuration(5_318_008);
        assertEq(blueberryStaking.rewardDuration(), 5_318_008);
    }

    function testAddBTokens() public {
        IERC20 mockbToken4 = new MockbToken();
        IERC20 mockbToken5 = new MockbToken();
        IERC20 mockbToken6 = new MockbToken();

        address[] memory bTokens = new address[](3);

        bTokens[0] = address(mockbToken4);
        bTokens[1] = address(mockbToken5);
        bTokens[2] = address(mockbToken6);

        blueberryStaking.addBTokens(bTokens);

        assertEq(blueberryStaking.isBToken(address(mockbToken4)), true);

        assertEq(blueberryStaking.isBToken(address(mockbToken5)), true);

        assertEq(blueberryStaking.isBToken(address(mockbToken6)), true);
    }

    function testRemoveBTokens() public {
        assertEq(blueberryStaking.isBToken(address(existingBTokens[0])), true);

        assertEq(blueberryStaking.isBToken(address(existingBTokens[1])), true);

        assertEq(blueberryStaking.isBToken(address(existingBTokens[2])), true);

        blueberryStaking.removeBTokens(existingBTokens);

        assertEq(blueberryStaking.isBToken(address(existingBTokens[0])), false);

        assertEq(blueberryStaking.isBToken(address(existingBTokens[1])), false);

        assertEq(blueberryStaking.isBToken(address(existingBTokens[2])), false);
    }

    function testPausing() public {
        blueberryStaking.pause();
        assertEq(blueberryStaking.paused(), true);

        blueberryStaking.unpause();
        assertEq(blueberryStaking.paused(), false);
    }

    function testNotifyRewardAmount() public {
        uint256[] memory amounts = new uint256[](3);

        amounts[0] = 1e19;
        amounts[1] = 1e19 * 4;
        amounts[2] = 1e23 * 4;

        blueberryStaking.notifyRewardAmount(existingBTokens, amounts);

        assertEq(blueberryStaking.rewardRate(existingBTokens[0]), 1e19 / blueberryStaking.rewardDuration());
        assertEq(blueberryStaking.rewardRate(existingBTokens[1]), 1e19 * 4 / blueberryStaking.rewardDuration());
        assertEq(blueberryStaking.rewardRate(existingBTokens[2]), 1e23 * 4 / blueberryStaking.rewardDuration());
    }

    function testChangeEpochLength() public {
        blueberryStaking.changeEpochLength(70_420_248_412);
        assertEq(blueberryStaking.epochLength(), 70_420_248_412);
    }

    function testChangeBLB() public {
        BlueberryToken newBLB = new BlueberryToken(address(this), address(this), block.timestamp + 30);
        blueberryStaking.changeBLB(address(newBLB));
        assertEq(blueberryStaking.getBLB(), address(newBLB));
    }

    function testStake() public {
        uint256[] memory amounts = new uint256[](3);

        amounts[0] = 1e16;
        amounts[1] = 1e16 * 4;
        amounts[2] = 1e16 * 4;

        blueberryStaking.notifyRewardAmount(existingBTokens, amounts);

        mockbToken1.approve(address(blueberryStaking), amounts[0]);
        mockbToken2.approve(address(blueberryStaking), amounts[1]);
        mockbToken3.approve(address(blueberryStaking), amounts[2]);

        blueberryStaking.stake(existingBTokens, amounts);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken1)), 1e16);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken2)), 1e16 * 4);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken3)), 1e16 * 4);
    }

    function testUnstake() public {
        uint256[] memory amounts = new uint256[](3);

        amounts[0] = 1e16;
        amounts[1] = 1e16 * 4;
        amounts[2] = 1e16 * 4;

        blueberryStaking.notifyRewardAmount(existingBTokens, amounts);

        mockbToken1.approve(address(blueberryStaking), amounts[0]);
        mockbToken2.approve(address(blueberryStaking), amounts[1]);
        mockbToken3.approve(address(blueberryStaking), amounts[2]);

        blueberryStaking.stake(existingBTokens, amounts);

        blueberryStaking.unstake(existingBTokens, amounts);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken1)), 0);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken2)), 0);

        assertEq(blueberryStaking.balanceOf(address(this), address(mockbToken3)), 0);
    }

    function testFullyVest() public {
        uint256[] memory amounts = new uint256[](3);

        amounts[0] = 1e16;
        amounts[1] = 1e16 * 4;
        amounts[2] = 1e16 * 4;

        blueberryStaking.notifyRewardAmount(existingBTokens, amounts);

        mockbToken1.approve(address(blueberryStaking), amounts[0]);
        mockbToken2.approve(address(blueberryStaking), amounts[1]);
        mockbToken3.approve(address(blueberryStaking), amounts[2]);

        blueberryStaking.stake(existingBTokens, amounts);

        // The epoch passes and it becomes claimable
        vm.warp(block.timestamp + 14 days);

        blueberryStaking.startVesting(existingBTokens);

        // 1 year passes, all rewards should be fully vested
        vm.warp(block.timestamp + 366 days);
        
        uint256[] memory indexes = new uint256[](3);
        indexes[0] = 0;
        indexes[1] = 1;
        indexes[2] = 2;

        blueberryStaking.completeVesting(indexes);

        console.log("BLB balance: %s", blb.balanceOf(address(this)));
    }

    function testAccelerateVesting() public {

        uint256[] memory amounts = new uint256[](3);

        amounts[0] = 1e16;
        amounts[1] = 1e16 * 4;
        amounts[2] = 1e16 * 4;

        blueberryStaking.notifyRewardAmount(existingBTokens, amounts);

        mockbToken1.approve(address(blueberryStaking), amounts[0]);
        mockbToken2.approve(address(blueberryStaking), amounts[1]);
        mockbToken3.approve(address(blueberryStaking), amounts[2]);

        blueberryStaking.stake(existingBTokens, amounts);

        // The epoch passes and it becomes claimable
        vm.warp(block.timestamp + 14 days);

        blueberryStaking.startVesting(existingBTokens);

        // half a year passes, early unlock penalty should be 50%
        vm.warp(block.timestamp + 180 days);
        
        uint256[] memory indexes = new uint256[](3);
        indexes[0] = 0;
        indexes[1] = 1;
        indexes[2] = 2;

        blueberryStaking.accelerateVesting(indexes);

        console.log("BLB balance: %s", blb.balanceOf(address(this)));
    }
}