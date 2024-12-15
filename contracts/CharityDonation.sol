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
        uint256 deadline;
        bool isCompleted;
    }

    //Define the donation structure
    struct Donation {
        address campaignAddress;
        uint256 campaignId;
        string title;
        uint256 amount;
    }

    //Define the  Withdrawal structure
    struct Withdrawals {
        uint256 campaignId;
        string title;
        uint256 amount;
        address by;
        address to;
    }

    //Map multiple campaigns to a single address
    mapping  (address => Campaign[]) public campaigns;

    //Map campaign address to the campaign admins
    mapping  (address => mapping (address => bool)) public admins;

    //Map campaign address to campaign admins
    mapping  (address => address[]) public  campaignAdmins;

    //Map multiple donations to a donor
    mapping (address => Donation[]) public donors;

    //Map withdrawals to a campaign address
    mapping (address => Withdrawals[]) public withdrawals;

    //Map donors to a particular campign from a particular campaigna address
    mapping (address => mapping (uint256 => address[])) public donorsForCampaign;

    //Events to emit
    event CampaignCreated(uint256 campaign_id, address campaignAddress,string title, uint256 targetAmount, uint256 deadline);
    event DonationReceived(address donor, uint256 amount, address campaignAddress, uint256 campaign_id);
    event FundsWithdrawn(uint256 amount, address by, address to, address from, uint256 campaignId);
    event CampaignCompleted(address campaignAddress,uint256 campaign_id);
    event CampaignCancelled(address campaignAddress,uint256 campaign_id);
    event AddAdmin(address admin);

    //Initialize Contract Owner
    constructor() {
        contractOwner = msg.sender;
    }

    //Add campaign admins
    function addCampaignAdmins(address _admin) public {
        //campaign address cannot be admin
        require(msg.sender != _admin,"The Campaign Address Cannot Be An Admin!");
        
        //check if admin is already an admin for campaign address
        require(!admins[msg.sender][_admin], "You Are Already An Admin!");

        //add admin to campaign
        admins[msg.sender][_admin] = true;    
        campaignAdmins[msg.sender].push(_admin);

        //emit event
        emit AddAdmin(_admin);
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
                isCompleted: false
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
            !campaigns[_campaignAddress][_campaignId-1].isCompleted, 
            string(abi.encodePacked("'",campaigns[_campaignAddress][_campaignId-1].title, "' Campaign Was Cancalled!"))
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

        donorsForCampaign[_campaignAddress][_campaignId].push(msg.sender);

        //emit event
        emit DonationReceived(msg.sender, _amount, _campaignAddress, _campaignId);
    }

    //get contract balance by contract owner
    function getContractBalance() public view onlyContractOwner returns (uint256) {
        return address(this).balance;
    }

    //get Campaign balance
    function getCampaignBalance(uint256 _campaignId, address _campaignAddress)  public view returns (uint256){
        //check if campaign is still active
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
            !campaigns[_campaignAddress][_campaignId-1].isCompleted,
            "This Campaign Has Been Cancelled!"
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
        campaigns[_campaignAddress][_campaignId-1].raisedAmount -= _amount;

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
            "This Campaign Has Already Been Cancelled!"
        );

        //deactivate the campaign 
        campaigns[_campaignAddress][_campaignId-1].isCompleted = true;  

         //emit event
        emit CampaignCancelled(_campaignAddress, _campaignId);
    }

    //refund donors if campaign fails
    function refundDonors(uint256 _campaignId, address _campaignAddress) external onlyAdmins(_campaignAddress, _campaignId){
        
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
