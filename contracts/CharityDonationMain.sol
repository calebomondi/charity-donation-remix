// SPDX-License-Identifier: MIT

import "./CharityDonationCore.sol";

pragma solidity ^0.8.26;

contract CharityDonationMain is CharityDonationCore {
    //get Campaign progress and details
    function getCampaignDetails(uint256 _campaignId, address _campaignAddress) public view returns (Campaign memory campaign, uint256 donorsNumber,CampaignDonors[] memory campaigndonors) {
        //check if campaign is active and has not reached the deadline
        require(
            block.timestamp < campaigns[_campaignAddress][_campaignId-1].deadline,
            "The Campaign Was Completed!"
        );
        require(
            !campaigns[_campaignAddress][_campaignId-1].isCancelled,
            "This Campaign Has Been Cancelled!"
        );
        require(
            !campaigns[_campaignAddress][_campaignId-1].isCompleted,
            "This Campaign Has Been Completed"
        );
        //get values
        Campaign storage thisCampaign = campaigns[_campaignAddress][_campaignId-1];

        return (
            thisCampaign, 
            donorsForCampaign[_campaignAddress][_campaignId].length,  
            donorsForCampaign[_campaignAddress][_campaignId]
        );
    }
    
    //View campaigns under this address
    function viewCampaigns() public view returns (Campaign[] memory) {
        return campaigns[msg.sender];
    }

    //Track your donations
    function viewDonations() public view returns (Donation[] memory) {
        return donors[msg.sender];
    }

    //Track withdrawals
    function viewWithdrawals(address _campaignAddress) public view returns 
    (Withdrawals[] memory withdrwals, address[] memory admins) {
        return (
            withdrawals[_campaignAddress],
            campaignAdmins[_campaignAddress]
        );
    }
}