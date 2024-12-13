// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract CharityDonation {
    //Define the contract owner
    address private contractOwner;

    //Define the campaign structure
    struct Campaign {
        uint256 campaign_id;
        string title;
        string description;
        address campaignAddress;
        uint256 targetAmount;
        uint256 raisedAmount;
        bool isCompleted;
    }

    //Map multiple campaigns to a single address
    mapping  (address => Campaign[]) public campaigns;

    //Map campaign address to the campaign admins
    mapping  (address => mapping (address => bool)) public admins;

    //Events to emit
    event CampaignCreated(uint256 campaign_id, address campaignAddress,string title, uint256 targetAmount);
    event DonationReceived(address donor, uint256 amount, address campaignAddress, uint256 campaign_id);
    event FundsWithdrawn(uint256 amount, address by, address to, address from, uint256 campaignId);
    event CampaignCompleted(address campaignAddress,uint256 campaign_id);
    event AddAdmin(address admin);

    //Initialize Contract Owner
    constructor() {
        contractOwner = msg.sender;
    }

    //Add campaign admins
    function addCampaignAdmins(address _admin) public {
        //check if campaign exists
        require(campaigns[msg.sender].length > 0,"The Campaigned Specified Does Not Exist!");
        //add admin to campaign
        admins[msg.sender][_admin] = true;    
        //emit event
        emit AddAdmin(_admin);
    }

    //RBAC modifiers
    modifier onlyWithdraw(address _campaignAddress,uint256 _campaignId) {
        //check if campaign exits
        require(campaigns[_campaignAddress].length > 0, "There Is No Campaign By That address!");
        //check if specified campaign exists
        require(campaigns[_campaignAddress][_campaignId-1].campaign_id == _campaignId,"The Campaign Specified Does Not Exist!");
        //check if user is an admin
        require(admins[_campaignAddress][msg.sender], "Only Admins Can Perform This Action!");
        _;
    }

    //Create Campaign Method
    function createCampaign(string memory _title, string memory _description,uint256 _target) public  {
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
                isCompleted: false
            }
        );
        campaigns[msg.sender].push(newCampaign);

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

        //check if campaign is still active
        require(!campaigns[_campaignAddress][_campaignId-1].isCompleted , "The Campaign Was Completed!");

        //check if donation amount is greater than 0 and that _amount  == msg.value
        require(_amount > 0 , "Amount Cannot be Zero");
        require(msg.value == _amount, "The Amount doesn't Match!");

        //update the campaign raised  amount
        campaigns[_campaignAddress][_campaignId-1].raisedAmount += _amount;

        //check if the campaign target has been achieved and deactivate it
        if (campaigns[_campaignAddress][_campaignId-1].raisedAmount >= campaigns[_campaignAddress][_campaignId-1].targetAmount) {
            campaigns[_campaignAddress][_campaignId-1].isCompleted = true;    
            emit CampaignCompleted(_campaignAddress, _campaignId);
        }

        //emit event
        emit DonationReceived(msg.sender, _amount, _campaignAddress, _campaignId);

    }

    //get  contract balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //withdraw funds
    function withdrawFunds(uint256 _campaignId, address _campaignAddress,uint256 _amount, address payable _to) external onlyWithdraw(_campaignAddress, _campaignId) {
        //check if campaign is completed, amount to withdraw is greater than 0 and contaract balance is greater than amount being withdrawn
        require(
            _amount > 0 && _amount <= campaigns[_campaignAddress][_campaignId-1].raisedAmount, 
            "Amount Cannot be Zero Or Exceed The Raised Amount!"
        );
        require(
            campaigns[_campaignAddress][_campaignId-1].isCompleted,
            "You Can't Withdraw Funds from an Active Campaign"
        );
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance"
        );
        //update campaigns balance
        campaigns[_campaignAddress][_campaignId-1].raisedAmount -= _amount;
        //transfer funds to specified address
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
        //emit event
        emit FundsWithdrawn(_amount,msg.sender,_to,_campaignAddress,_campaignId);
    }

}