// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

contract CharityDonationEvents {
    //Events to emit
    event CampaignCreated(uint256 campaign_id, address campaignAddress,string title, uint256 targetAmount, uint256 deadline);
    event DonationReceived(address donor, uint256 amount, address campaignAddress, uint256 campaign_id);
    event FundsWithdrawn(uint256 amount, address by, address to, address from, uint256 campaignId);
    event CampaignCompleted(address campaignAddress,uint256 campaign_id);
    event CampaignCancelled(address campaignAddress,uint256 campaign_id);
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);
    event RefundCampaignDonors(address campaignAddress, uint256 campaignId, address to, uint256 amount);
}
