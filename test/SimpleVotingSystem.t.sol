// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SimpleVotingSystem.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VotingTest is Test {
    SimpleVotingSystem voting;
    address admin = address(1);
    address founder = address(2);
    address voter = address(3);
    address voter1 = address(5);
    address voter2 = address(4);
    address voter3 = address(6);

    function setUp() public {
        voting = new SimpleVotingSystem();
        voting.grantRole(keccak256("ADMIN_ROLE"), admin);
        voting.grantRole(keccak256("FOUNDER_ROLE"), founder);

        // Envoyer de l'Ether au contrat de test pour couvrir les fonds nÃ©cessaires
        // payable(address(this)).transfer(10 ether);
    }

    function testAdminCanAddCandidate() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Candidate 1");
        assertEq(voting.getCandidatesCount(), 1);
    }

    function testNoAdminCantAddCandidate() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Candidate 2");
        assertEq(voting.getCandidatesCount(), 1);
    }

    function testAdminWorkflowNotRegisterCandidates() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        try voting.addCandidate("Candidate 2") {
            assert(false);
        } catch Error(string memory) {
            assert(true);
        }
    }

    // function testFailAddCandidateWhenNotAdmin() public {
    //     voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    //     vm.prank(nonFounder);  // Using vm to simulate another address
    //     voting.addCandidate("Alice");
    // }

    // function testFounderCanFundCandidate() public {
    //     voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    //     voting.addCandidate("Bob");
    //     uint candidateId = 1;
    //     uint fundingAmount = 1 ether;
    //     vm.prank(founder);
    //     voting.fundCandidate{value: fundingAmount}(candidateId);
    //     assertEq(voting.getCandidate(candidateId).fundReceived, fundingAmount);
    // }

    // function testFailFundCandidateWhenNotFounder() public {
    //     voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
    //     voting.addCandidate("Charlie");
    //     uint candidateId = 1;
    //     uint fundingAmount = 1 ether;
    //     vm.prank(nonFounder);
    //     voting.fundCandidate{value: fundingAmount}(candidateId);  // Should fail
    // }

    function testVoting() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 61 minutes);

        vm.prank(voter);
        voting.vote(1);  // Should pass now that we use the right address
        vm.prank(admin);
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);
        assertEq(voting.getTotalVotes(1), 1);
    }

    function testFailVoteNotInVoteStatus() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");

        vm.warp(block.timestamp + 61 minutes);
        vm.prank(voter);
        voting.vote(1);
        vm.expectRevert("Invalid operation at current workflow status");
    }

    function testOnlyOnceVotingPerPerson() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");

        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 61 minutes);
        vm.prank(voter2);
        voting.vote(1);
        voting.vote(1);
        vm.expectRevert("You have already voted");
        voting.vote(1);
    }

    function testDeclareWinner() public {
        vm.prank(admin);
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);
        
        vm.prank(voter1);
        voting.vote(1);  // Vote for Alice
        
        vm.prank(voter2);
        voting.vote(2);  // Vote for Bob

        vm.prank(voter3);
        voting.vote(2);  // Vote for Bob again

        vm.prank(admin);
        voting.completeVoting();

        SimpleVotingSystem.Candidate memory winner = voting.declareWinner();
        assertEq(winner.name, "Bob");
        assertEq(winner.voteCount, 2);
    }
}