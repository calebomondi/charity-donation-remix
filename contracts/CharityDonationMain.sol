// SPDX-License-Identifier: MIT

import "./CharityDonationCore.sol";

pragma solidity ^0.8.26;

contract CharityDonationMain is CharityDonationCore {
    //get Campaign details
    function getCampaignDetails(uint256 _campaignId, address _campaignAddress) public view returns 
    (Campaign memory campaign, uint256 donorsNumber,CampaignDonors[] memory campaigndonors) {
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