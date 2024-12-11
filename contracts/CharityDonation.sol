// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract CharityDonation {
    //Define the contract owner
    address private contractOwner;

    //Define campaign admin and donor role names
    string private constant ADMIN_ROLE = "ADMIN";
    string private constant DONOR_ROLE = "DONOR";

    //Define the campaign structure
    struct Campaign {
        uint256 campaign_id;
        string title;
        string description;
        address owner;
        uint256 targetAmount;
        uint256 raisedAmount;
        bool isCompleted;
    }

    //Map multiple campaigns to a single address
    mapping  (address => Campaign[]) public campaigns;

    //Map address to make  campaign admin
    mapping  (address => mapping (string => bool)) public adminRoles;

    //Events to emit
    event CampaignCreated(uint256 campaign_id, address owner,string title, uint256 targetAmount);
    event  DonationReceived(address donor, uint256 amount);
    event FundsWithdrawn(uint256 amount);
    event CampaignCompleted(uint256 campaign_id);

    //Initialize Contract Owner
    constructor() {
        contractOwner = msg.sender;
    }

    //Create Campaign Method
    function createCampaign(string memory _title, string memory _description, uint256 _target) public  {
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
                owner: msg.sender, 
                targetAmount: _target, 
                raisedAmount  :  0, 
                isCompleted: false
            }
        );
        campaigns[msg.sender].push(newCampaign);

        //make the campaign creator an admin 
        adminRoles[msg.sender][ADMIN_ROLE] = true;

        //emit event
        emit CampaignCreated(campaigns[msg.sender].length, msg.sender, _title, _target);
    }

    //Donate to Campaign Method
    function donateToCampaign(address payable  _campaignAddress, uint256 _campaignId, uint256 _amount) public payable  {
        //check if donation campaign exists and if its active or not
        require(
            campaigns[_campaignAddress][_campaignId-1].campaign_id == _campaignId, 
            string(abi.encodePacked("The Campaign ", _campaignId , " Does NOT Exist!"))
        );
        require(
            campaigns[_campaignAddress][_campaignId-1].isCompleted == false, 
            string(abi.encodePacked("'",campaigns[_campaignAddress][_campaignId-1].title, "' Campaign Was Completed!"))
        );

        //check if donation amount is greater than 0 and that _amount  == msg.value
        require(_amount > 0 , "Amount Cannot be Zero");
        require(msg.value == _amount, "The Amount doesn't Match!");

        //transfer ether to the campaign address
        _campaignAddress.transfer(_amount);

        //update the campaign raised  amount and close campaign if targeted amount is equal to or is exceeded
        campaigns[_campaignAddress][_campaignId-1].raisedAmount += _amount;
        if (campaigns[_campaignAddress][_campaignId-1].raisedAmount >= campaigns[_campaignAddress][_campaignId-1].targetAmount) {
            campaigns[_campaignAddress][_campaignId-1].isCompleted = true;    
        }

        //emit event
        emit DonationReceived(msg.sender, _amount);

    }
}