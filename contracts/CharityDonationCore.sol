// SPDX-License-Identifier: MIT

import "./CharityDonationAdmin.sol";

pragma solidity ^0.8.26;

contract CharityDonationCore is CharityDonationAdmin {
    //Create Campaign Method
    function createCampaign(string memory _title, string memory _description,uint256 _target, uint256 _durationdays) public  {
        //check if campaign already exists
        unchecked {
            for(uint256 i; i < campaigns[msg.sender].length; i++) {
                string storage campaignTitle = campaigns[msg.sender][i].title;
                bool exists = keccak256(abi.encodePacked(campaignTitle)) == keccak256(abi.encodePacked(_title));
                if (exists) {
                    revert(string(abi.encodePacked("Campaign ", _title, " already exists!")));
                }
            }
        }

        //create campaign
        Campaign memory newCampaign =  Campaign(
            {
                campaign_id : campaigns[msg.sender].length + 1,
                title: _title,
                description: _description, 
                campaignAddress: msg.sender,
                targetAmount: _target, 
                raisedAmount  :  0, 
                deadline: block.timestamp + (_durationdays * 1 days),
                isCompleted: false,
                isCancelled: false
            }
        );
        campaigns[msg.sender].push(newCampaign);

        //emit event
        emit CampaignCreated(campaigns[msg.sender].length, msg.sender, _title, _target, block.timestamp + (_durationdays * 1 days));
    }

    //Donate to Campaign Method
    function donateToCampaign(address payable  _campaignAddress, uint256 _campaignId, uint256 _amount) public payable  {
        //check if donation campaign exists and if its active or not and deadline has not been reached
        require(
            campaigns[_campaignAddress][_campaignId-1].campaign_id == _campaignId, 
            string(abi.encodePacked("The Campaign ", _campaignId , " Does NOT Exist!"))
        );
        require(
            block.timestamp < campaigns[_campaignAddress][_campaignId-1].deadline,
            "This Campaign's Deadline Has Passed!"
        );
        require(
            !campaigns[_campaignAddress][_campaignId-1].isCancelled, 
            string(abi.encodePacked("'",campaigns[_campaignAddress][_campaignId-1].title, "' Campaign Was Cancalled!"))
        );
        require(
            !campaigns[_campaignAddress][_campaignId-1].isCompleted, 
            string(abi.encodePacked("'",campaigns[_campaignAddress][_campaignId-1].title, "' Campaign Was Completed!"))
        );

        //check if donation amount is greater than 0 and that _amount  == msg.value
        require(_amount > 0 , "Donation Amount Cannot be Zero");
        require(msg.value == _amount, "The Amount And Value Don't Match!");

        //update the campaign raised  amount
        campaigns[_campaignAddress][_campaignId-1].raisedAmount += _amount;

        //check if the campaign target has been achieved and deactivate it
        if (campaigns[_campaignAddress][_campaignId-1].raisedAmount >= campaigns[_campaignAddress][_campaignId-1].targetAmount) {
            campaigns[_campaignAddress][_campaignId-1].isCompleted = true;    
            emit CampaignCompleted(_campaignAddress, _campaignId);
        }

        //add donation to donor records
        Donation memory newDonation = Donation({
            campaignAddress: _campaignAddress,
            campaignId: _campaignId,
            title:  campaigns[_campaignAddress][_campaignId-1].title,
            amount: _amount
        });
        donors[msg.sender].push(newDonation);

        CampaignDonors memory thisDonor = CampaignDonors({
            by:msg.sender,
            amount: _amount
        });

        donorsForCampaign[_campaignAddress][_campaignId].push(thisDonor);

        //emit event
        emit DonationReceived(msg.sender, _amount, _campaignAddress, _campaignId);
    }

    //withdraw funds
    function withdrawFunds(uint256 _campaignId, address _campaignAddress,uint256 _amount, address payable _to) external onlyAdmins(_campaignAddress, _campaignId) {
        //check if campaign is completed, amount to withdraw is greater than 0 and contaract balance is greater than amount being withdrawn
        require(
            campaigns[_campaignAddress][_campaignId-1].isCompleted,
            "You Can't Withdraw Funds from an Active Campaign"
        );
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance"
        );
        require(
            _amount > 0 && _amount <= campaigns[_campaignAddress][_campaignId-1].raisedAmount, 
            "Amount Cannot be Zero Or Exceed The Raised Amount!"
        );
        //update campaigns balance
        uint256 currentbalance = campaigns[_campaignAddress][_campaignId-1].raisedAmount;
        uint256 updatedbalance = currentbalance - _amount;
        campaigns[_campaignAddress][_campaignId-1].raisedAmount = updatedbalance;

        //transfer funds to specified address
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");

        //add withdrawal to withdrawal records
        Withdrawals memory newWithdrawal = Withdrawals ({
            campaignId: _campaignId,
            title: campaigns[_campaignAddress][_campaignId-1].title,
            amount: _amount,
            by: msg.sender,
            to: _to
        });
        withdrawals[_campaignAddress].push(newWithdrawal);

        //emit event 
        emit FundsWithdrawn(_amount,msg.sender,_to,_campaignAddress,_campaignId);
    }
}