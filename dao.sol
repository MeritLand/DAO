// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IntellectualDAO is Ownable {
    using Counters for Counters.Counter;

    // Struct to represent a member's profile
    struct Member {
        address memberAddress;
        uint256 iq;
        uint256 moralScore;
        uint256 skillScore;
        uint256 empathyScore;
        bool isActive;
        bool isCitizen;
    }

    // Membership application stages
    enum ApplicationStage {
        Pending,
        UnderReview,
        Accepted,
        Rejected
    }

    // Membership application structure
    struct Application {
        address applicant;
        uint256 iq;
        uint256 moralScore;
        uint256 skillScore;
        uint256 empathyScore;
        ApplicationStage stage;
        uint256 submissionTime;
    }

    // Key parameters
    uint256 public constant MIN_IQ_THRESHOLD = 120;
    uint256 public constant MIN_MORAL_SCORE = 80;
    uint256 public constant MIN_SKILL_SCORE = 70;
    uint256 public constant MIN_EMPATHY_SCORE = 75;

    // Mappings
    mapping(address => Member) public members;
    mapping(address => Application) public applications;
    mapping(address => bool) public citizenshipGranted;

    // Counters
    Counters.Counter private memberCount;
    Counters.Counter private citizenCount;

    // Events
    event MemberApplicationSubmitted(address indexed applicant, uint256 submissionTime);
    event MemberApplicationReviewed(address indexed applicant, bool approved);
    event CitizenshipGranted(address indexed member);
    event MemberStatusChanged(address indexed member, bool isActive);

    // Modifier to check application eligibility
    modifier meetsInitialCriteria(uint256 iq, uint256 moralScore, uint256 skillScore, uint256 empathyScore) {
        require(iq >= MIN_IQ_THRESHOLD, "IQ does not meet minimum threshold");
        require(moralScore >= MIN_MORAL_SCORE, "Moral score too low");
        require(skillScore >= MIN_SKILL_SCORE, "Skill score insufficient");
        require(empathyScore >= MIN_EMPATHY_SCORE, "Empathy score below threshold");
        _;
    }

    // Submit membership application
    function submitApplication(
        uint256 iq, 
        uint256 moralScore, 
        uint256 skillScore, 
        uint256 empathyScore
    ) external meetsInitialCriteria(iq, moralScore, skillScore, empathyScore) {
        require(applications[msg.sender].stage == ApplicationStage.Pending, "Application already exists");

        applications[msg.sender] = Application({
            applicant: msg.sender,
            iq: iq,
            moralScore: moralScore,
            skillScore: skillScore,
            empathyScore: empathyScore,
            stage: ApplicationStage.UnderReview,
            submissionTime: block.timestamp
        });

        emit MemberApplicationSubmitted(msg.sender, block.timestamp);
    }

    // Review and approve membership (only by DAO governance)
    function reviewApplication(address applicant, bool approve) external onlyOwner {
        Application storage application = applications[applicant];
        require(application.stage == ApplicationStage.UnderReview, "Application not under review");

        if (approve) {
            // Create member profile
            members[applicant] = Member({
                memberAddress: applicant,
                iq: application.iq,
                moralScore: application.moralScore,
                skillScore: application.skillScore,
                empathyScore: application.empathyScore,
                isActive: true,
                isCitizen: false
            });

            memberCount.increment();
            application.stage = ApplicationStage.Accepted;
        } else {
            application.stage = ApplicationStage.Rejected;
        }

        emit MemberApplicationReviewed(applicant, approve);
    }

    // Grant citizenship (requires additional review)
    function grantCitizenship(address member) external onlyOwner {
        require(members[member].isActive, "Not an active member");
        require(!members[member].isCitizen, "Already a citizen");

        members[member].isCitizen = true;
        citizenshipGranted[member] = true;
        citizenCount.increment();

        emit CitizenshipGranted(member);
    }

    // Change member active status
    function changeMemberStatus(address member, bool status) external onlyOwner {
        require(members[member].memberAddress != address(0), "Member does not exist");
        members[member].isActive = status;

        emit MemberStatusChanged(member, status);
    }

    // View functions
    function getMemberCount() external view returns (uint256) {
        return memberCount.current();
    }

    function getCitizenCount() external view returns (uint256) {
        return citizenCount.current();
    }

    function isMember(address account) external view returns (bool) {
        return members[account].isActive;
    }

    function isCitizen(address account) external view returns (bool) {
        return members[account].isCitizen;
    }
}
