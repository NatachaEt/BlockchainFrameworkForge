// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
        uint fundReceived; // Ajout pour gérer les fonds reçus
    }

    enum WorkflowStatus { REGISTER_CANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED }
    WorkflowStatus public currentStatus;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only the contract owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only an admin can perform this action");
        _;
    }

    modifier inStatus(WorkflowStatus _status) {
        require(currentStatus == _status, "Invalid operation at current workflow status");
        _;
    }

    modifier onlyFounder() {
        require(hasRole(FOUNDER_ROLE, msg.sender), "Only a founder can perform this action");
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FOUNDER_ROLE, msg.sender); // Assigner le rôle FOUNDER au créateur pour la démonstration
        currentStatus = WorkflowStatus.REGISTER_CANDIDATES;
    }

    function setWorkflowStatus(WorkflowStatus _status) public onlyAdmin {
        currentStatus = _status;
    }

    function addAdmin(address account) public onlyAdmin {
        grantRole(ADMIN_ROLE, account);
    }

    function addFounder(address account) public onlyAdmin {
        grantRole(FOUNDER_ROLE, account);
    }

    function addCandidate(string memory _name) public onlyAdmin inStatus(WorkflowStatus.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0, 0); // Initialiser les fonds à 0
        candidateIds.push(candidateId);
    }

    function fundCandidate(uint _candidateId) public payable onlyFounder inStatus(WorkflowStatus.FOUND_CANDIDATES) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        candidates[_candidateId].fundReceived += msg.value;
    }

    function vote(uint _candidateId) public inStatus(WorkflowStatus.VOTE) {
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public inStatus(WorkflowStatus.COMPLETED) view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}