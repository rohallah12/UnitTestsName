// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/name.sol";
import "../src/edited.sol";

contract nameTest is Test {
    dotMeme dm;
    dotMeme_test dmt;
    uint256 name = 10011110310199111105110;
    uint256 price = 1000000000000000000000000000;
    address other = 0xc7d82b79D1c1ba97939AEF33875C66806f28C995;

    function setUp() public {
        dm = new dotMeme();
        dm.changeOwner(address(this));
        dm.activateNameRegistration(true);
        vm.deal(address(this), ~uint256(0));
        for (uint k = 1; k <= 20; k++) {
            for (uint k = 1; k <= 20; k++) {
                dm.setFees(k, 10 ether, 10 ether);
            }
        }
        price = 10 ether;
    }

    function test_can_increaseFees() public {
        for (uint k = 1; k <= 20; k++) {
            for (uint k = 1; k <= 20; k++) {
                dm.setFees(k, 10 ether, 10 ether);
            }
        }
        price = 10 ether;
    }

    function test_can_register_a_name() public {
        dm.registerName{value: price}(name);
        assertEq(dm.holderOf(name), address(this));
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
    }

    function test_can_set_primary_name() public {
        dm.registerName{value: price}(name);
        dm.setPrimaryName(name);
        assertEq(dm.holderOf(name), address(this));
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
        assertEq(dm.readName(address(this)), name);
    }

    function testFail_can_not_set_primary_if_is_not_holder() public {
        dm.registerName{value: price}(name);
        vm.startPrank(other);
        dm.setPrimaryName(name);
    }

    function test_can_extend_name() public {
        dm.registerName{value: price}(name);
        uint expiration = dm.nameExpiry(name);
        dm.extendNameExpiry{value: price}(name);
        assertEq(dm.nameExpiry(name), expiration + 126144000);
    }

    function test_can_list_name_for_sale_if_is_holder() public {
        dm.registerName{value: price}(name);
        dm.listName(name, true, 10 ether);
    }

    function test_can_list_name_for_sale_if_is_holder_and_receives_ether_if_sold()
        public
    {
        dm.registerName{value: price}(name);
        dm.listName(name, true, 10 ether);
        uint beforeBalance = address(this).balance;
        vm.startPrank(other);
        vm.deal(other, 100 ether);
        dm.buyName{value: 10 ether}(name);
        uint256 received = address(this).balance - beforeBalance;
        assertEq(received, 10 ether);
        assertEq(dm.holderOf(name), other);
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
    }

    function testFail_can_not_buy_if_not_payed_enough() public {
        dm.registerName{value: price}(name);
        dm.listName(name, true, 10 ether);
        vm.startPrank(other);
        vm.deal(other, 100 ether);
        dm.buyName{value: 5 ether}(name);
    }

    function test_can_tranfser_if_is_holder() public {
        dm.registerName{value: price}(name);
        dm.transferName(name, other);
        assertEq(dm.holderOf(name), other);
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
    }

    function testFail_can_not_transfer_if_is_not_holder() public {
        dm.registerName{value: price}(name);
        vm.startPrank(other);
        dm.transferName(name, other);
        assertEq(dm.holderOf(name), other);
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
    }

    function testFail_can_not_register_if_is_not_expired() public {
        dm.registerName{value: price}(name);
        dm.setPrimaryName(name);
        vm.startPrank(other);
        dm.registerName{value: price}(name);
        assertEq(dm.holderOf(name), other);
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
        assertEq(dm.readName(other), 0);
    }

    function testFail_primary_name_will_be_reset_after_transfer() public {
        dm.registerName{value: price}(name);
        dm.setPrimaryName(name);
        dm.listName(name, true, 5 ether);
        vm.deal(other, 5 ether);
        vm.startPrank(other);
        dm.buyName{value: 5 ether}(name);
        assertEq(dm.holderOf(name), other);
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
        dm.readName(address(this));
    }

    function tset_admin_can_set_name_no_fee() public {
        dm.adminRegister(address(this), name, "good holder");
        assertEq(dm.holderOf(name), address(this));
        assertEq(dm.forSale(name), false);
        assertEq(dm.nameExpiry(name), block.timestamp + 126144000);
    }

    receive() external payable {}
}
