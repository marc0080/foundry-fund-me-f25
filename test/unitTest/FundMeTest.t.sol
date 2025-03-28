//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user"); // creates an address named USER
    uint256 constant SEND_VALUE = 0.1 ether; // we are setting the value we are sendion in a var named send_value = 0.1ether
    uint256 constant STARTING_BALANCE = 10 ether; // we are creating a fake balance

    function setUp() external {
        // us -> FundMeTest -> FundMe
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMINIMUM_USD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function test_RevertFailsWithoutEnoughEth() public {
        vm.expectRevert(); //hey the next line should revert
        // assert(This tx fails/reverts)
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //The next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToAnArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getfunder(0); // The funder at index 0
        assertEq(funder, USER); // we want to know whether funder at index 0 is USER
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _; // the modifier helpsus reduce the burden of funding using vm.prank multiple times
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // it means it will revert the next line i.e the one without vm
        vm.prank(USER);
        fundMe.withdraw(); //this line should be reverted coz USER is not the owner
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // checks the specific owner balance
        uint256 startingFundMeBalance = address(fundMe).balance; // cheks the balance of the address of the FundMe contract

        // Act
        vm.prank(fundMe.getOwner()); // coz only the owner can make the call
        fundMe.withdraw(); // coz we are testing the withdraw

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance; //we are checking the ending owner bal
        uint256 endingFundMeBalance = address(fundMe).balance; // we are checking the ending FundMe bal
        assertEq(endingFundMeBalance, 0); //we are assume we want to  withdraw all the money
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // we use hoax cheattcode that pranks and deal at the same time
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // checks the specific owner balance
        uint256 startingFundMeBalance = address(fundMe).balance; // cheks the balance of the address of the FundMe contract

        //Act
        vm.startPrank(fundMe.getOwner()); // coz only the owner can make the call
        fundMe.withdraw(); // coz we are testing the withdraw
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFunderscheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // we use hoax cheattcode that pranks and deal at the same time
            fundMe.fund{value: SEND_VALUE}();
            //fund the fundMe
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // checks the specific owner balance
        uint256 startingFundMeBalance = address(fundMe).balance; // cheks the balance of the address of the FundMe contract

        //Act
        vm.startPrank(fundMe.getOwner()); // coz only the owner can make the call
        fundMe.cheaperWithdraw(); // coz we are testing the withdraw
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
