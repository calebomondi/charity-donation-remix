// SPDX-License-Identifier: MIT

import "./CharityDonationStorage.sol";
import "./CharityDonationEvents.sol";

pragma solidity ^0.8.26;

contract CharityDonationAdmin is CharityDonationStorage, CharityDonationEvents {
//Define the contract owner
    address private contractOwner;

    //Initialize Contract Owner
    constructor() {
        contractOwner = msg.sender;
    }

    //RBAC modifiers
    modifier onlyAdmins(address _campaignAddress,uint256 _campaignId) {
        //check if campaign exits
        require(campaigns[_campaignAddress].length > 0, "There Is No Campaign By That address!");
        //check if specified campaign exists
        require(campaigns[_campaignAddress][_campaignId-1].campaign_id == _campaignId,"The Campaign Specified Does Not Exist!");
        //check if user is an admin
        require(admins[_campaignAddress][msg.sender], "Only Admins Can Perform This Action!");
        _;
    }

    modifier  onlyContractOwner() {
        require(msg.sender == contractOwner,"Only Contract Owner Can Perform This Action!");
        _;
    }
    
    //Add campaign admins
    function addCampaignAdmin(address _admin) public {
        //campaign address cannot be admin
        require(msg.sender != _admin,"The Campaign Address Cannot Be An Admin!");
        
        //check if admin is already an admin for campaign address
        require(!admins[msg.sender][_admin], "This Address Is Already An Admin!");

        //add admin to campaign
        admins[msg.sender][_admin] = true;    
        campaignAdmins[msg.sender].push(_admin);

        //emit event
        emit AddAdmin(_admin);
    }

    //Remove Campaign Admin
    function removeCampaignAdmin(address _admin ) external {
        //check if address is an admin
        require(admins[msg.sender][_admin],"This Address Is Not An Admin!");

        //remove admin
        admins[msg.sender][_admin] = false;    

        address[] storage campaignadmins = campaignAdmins[msg.sender];
        for (uint256 i; i < campaignadmins.length; i++) {
            if (campaignadmins[i] == _admin) {
                // Replace the element to remove with the last element
                campaignadmins[i] = campaignadmins[campaignadmins.length - 1];
                // Remove the last element
                campaignadmins.pop();
                break;
            }
        }

        //emit event
        emit RemoveAdmin(_admin);
    }

    //cancel  campaign before it starts
    function cancelCampaign(uint256 _campaignId, address _campaignAddress) external  onlyAdmins(_campaignAddress, _campaignId) {
        //check if campaign has not yet raised any coins and if its still active
        Campaign memory thisCampaign = campaigns[_campaignAddress][_campaignId-1];
        require(
            thisCampaign.raisedAmount == 0, 
            "This Campaign Has Already Raised Funds! Refund First Then Cancel!"
        );
        require(
            !thisCampaign.isCompleted, 
            "This Campaign Has Already Been Completed!"
        );

        //deactivate the campaign 
        campaigns[_campaignAddress][_campaignId-1].isCancelled = true;  

        //emit event
        emit CampaignCancelled(_campaignAddress, _campaignId);
    }

    //refund donors 
    function RefundDonors(uint256 _campaignId) public  onlyAdmins(msg.sender,_campaignId) {
        Campaign memory thisCampaign = campaigns[msg.sender][_campaignId-1];

        //check if campaign raised enough money
        require(
            thisCampaign.raisedAmount < thisCampaign.targetAmount,
            "This Campaign Is Successful Cannot be Cancelled!"
        );

        // Ensure contract has sufficient balance
        require(
            address(this).balance >= thisCampaign.raisedAmount, 
            "Insufficient contract balance"
        );

        //get donor list
        CampaignDonors[] storage campaignDonors = donorsForCampaign[msg.sender][_campaignId];

        uint256 totalRefunded = 0;
        uint256 currentBalance;
        uint256 updatedBalance;

        //refund
        for (uint256 i; i < campaignDonors.length; i++) {

            uint256 refundAmount = campaignDonors[i].amount;
            address donor = campaignDonors[i].by;

            // Prevent re-entrancy and double-spending
            currentBalance = campaigns[msg.sender][_campaignId-1].raisedAmount;
            updatedBalance = currentBalance - refundAmount;
            campaigns[msg.sender][_campaignId-1].raisedAmount = updatedBalance;
            campaignDonors[i].amount = 0;

            // Transfer funds
            (bool success, ) = payable(donor).call{value: refundAmount}("");
            require(success, "Transfer failed");

            // Track total refunded
            totalRefunded += refundAmount;
        }

        //check if refund was successful
        require(
            thisCampaign.raisedAmount == totalRefunded && campaigns[msg.sender][_campaignId-1].raisedAmount == 0,
            "Refund Was Unsuccessful!"
        );

    }
}