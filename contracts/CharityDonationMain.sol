// SPDX-License-Identifier: MIT

import "./CharityDonationCore.sol";

pragma solidity ^0.8.26;

contract CharityDonationView is CharityDonationCore {
    //get contract balance by contract owner
    function getContractBalance() public view onlyContractOwner returns (uint256) {
        return address(this).balance;
    }

    //get Campaign balance
    function getCampaignBalance(uint256 _campaignId, address _campaignAddress)  public view returns (uint256){
        //check if campaign is still active
        require(!campaigns[_campaignAddress][_campaignId-1].isCancelled,"This Campaign Was Cancelled!");
        require(campaigns[_campaignAddress][_campaignId-1].isCompleted,"This Campaign Is Still In Progress!");

        return campaigns[_campaignAddress][_campaignId-1].raisedAmount;
    }

    //get Campaign progress
    function getCampaignProgress(uint256 _campaignId, address _campaignAddress) public view returns (uint256 goalamount,uint256 raisedAmount, uint256 donorsNumber,address[] memory campaigndonors) {
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
    function campaignDetails(uint256 _campaignId, address _campaignAddress) public view returns(Campaign memory thisCampaign, uint256 donorsnumber, address[] memory campaigndonors) {
        Campaign memory thisCampign = campaigns[_campaignAddress][_campaignId-1];
        return  (
            thisCampign, 
            donorsForCampaign[_campaignAddress][_campaignId].length,  
            donorsForCampaign[_campaignAddress][_campaignId]
        );
    }
    
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