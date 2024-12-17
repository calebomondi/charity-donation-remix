// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract CharityDonationStorage {
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
        bool isCancelled;
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

    //Define Campign Donors Structure
    struct CampaignDonors {
        address by;
        uint256 amount;
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
    mapping (address => mapping (uint256 => CampaignDonors[])) public donorsForCampaign; 
}