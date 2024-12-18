// SPDX-License-Identifier: MIT

import "./CharityDonationGet.sol";

pragma solidity ^0.8.26;

contract CharityDonationMain is CharityDonationGet {
    
    //View campaigns under this address
    function viewCampaigns() public view returns (Campaign[] memory) {
        return campaigns[msg.sender];
    }

    //View campaign admins
    function viewCampaignAdmins(address _campaignAddress) public view returns (address[] memory ){
        return campaignAdmins[_campaignAddress];
    }

    //Track your donations
    function viewDonations() public view returns (Donation[] memory) {
        return donors[msg.sender];
    }

    //Track withdrawals
    function viewWithdrawals(address _campaignAddress) public view returns (Withdrawals[] memory) {
        return withdrawals[_campaignAddress];
    }
}