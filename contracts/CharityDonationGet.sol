// SPDX-License-Identifier: MIT

import "./CharityDonationCore.sol";

pragma solidity ^0.8.26;

contract CharityDonationGet is CharityDonationCore {

    //get Campaign balance
    function getCampaignBalance(uint256 _campaignId, address _campaignAddress)  public view returns (uint256){
        //check if campaign is still active
        require(!campaigns[_campaignAddress][_campaignId-1].isCancelled,"This Campaign Was Cancelled!");
        require(campaigns[_campaignAddress][_campaignId-1].isCompleted,"This Campaign Is Still In Progress!");

        return campaigns[_campaignAddress][_campaignId-1].raisedAmount;
    }

    //get Campaign progress
    function getCampaignProgress(uint256 _campaignId, address _campaignAddress) public view returns (uint256 goalamount,uint256 raisedAmount, uint256 donorsNumber,CampaignDonors[] memory campaigndonors) {
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
            thisCampaign.targetAmount, 
            thisCampaign.raisedAmount, 
            donorsForCampaign[_campaignAddress][_campaignId].length,  
            donorsForCampaign[_campaignAddress][_campaignId]
        );
    }

    //get particluar campaign details
    function getCampaignDetails(uint256 _campaignId, address _campaignAddress) public view returns(Campaign memory thisCampaign, uint256 donorsnumber, CampaignDonors[] memory campaigndonors) {
        Campaign memory thisCampign = campaigns[_campaignAddress][_campaignId-1];
        return  (
            thisCampign, 
            donorsForCampaign[_campaignAddress][_campaignId].length,  
            donorsForCampaign[_campaignAddress][_campaignId]
        );
    }

}