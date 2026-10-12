// SPDX-License-Identifier: MIT

pragma solidity 0.8.37;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {

    
    constructor() Ownable(msg.sender) {} // Le deployeur du contrat devient le owner (administrateur)

    event Voted (address voter, uint proposalId);
    event VoterRegistered(address voterAddress);
    event ProposalRegistered(uint proposalId);
    event WorkflowStatusChange(
    WorkflowStatus previousStatus,
    WorkflowStatus newStatus);

    // Une structure pour garder les informations de chaque votant
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Une structure pour les propositions et leur nombre de votes
    struct Proposal {

    string description;
    uint voteCount;

    }

    Proposal[] public Proposition;

    // L'adresse du votant permettant de retrouver ses info
    mapping(address => Voter) public ListeVote;

    // Les differentes etapes du vote dans l'ordre
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public EtatDesVotes = WorkflowStatus.RegisteringVoters; 

    uint public winningProposalId; // variable pour le vainqueur 


    // Etape 1 : enregistrement des votants par l'admin

    function ElecteurWhiteList(address _address) public onlyOwner {
        require(!ListeVote[_address].isRegistered, "deja whitelist");

        ListeVote[_address].isRegistered = true;
        ListeVote[_address].hasVoted = false;
        ListeVote[_address].votedProposalId = 0;

        emit VoterRegistered(_address);
    }


    function OuvertureSessionProposition() public onlyOwner {
        require(EtatDesVotes == WorkflowStatus.RegisteringVoters, "Inscription des electeurs pas terminee");

        WorkflowStatus ancienEtat = EtatDesVotes;
        EtatDesVotes = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(ancienEtat, EtatDesVotes); // evenement changement de status
    }


    function EnvoiDesProposition (string calldata _Proposition) public {
        // le require permet que seul un votant inscrit en etape 1 peut proposer une idee pendant cette etape
        require(ListeVote[msg.sender].isRegistered == true && EtatDesVotes == WorkflowStatus.ProposalsRegistrationStarted, "Vous ne repondez pas aux exigences");

        Proposition.push(Proposal({
            description: _Proposition,
            voteCount: 0
        }));

        emit ProposalRegistered(Proposition.length-1); // length - 1 = index de la derniere proposition
    }


    function FermetureDesProposition () public onlyOwner {
        require(EtatDesVotes == WorkflowStatus.ProposalsRegistrationStarted, "La session de propositions n'est pas ouverte");

        WorkflowStatus ancienEtat = EtatDesVotes;
        EtatDesVotes = WorkflowStatus.ProposalsRegistrationEnded;

        emit WorkflowStatusChange(ancienEtat,EtatDesVotes); // evenement changement de status
    }


    function LancementVote () public onlyOwner {
        require(EtatDesVotes == WorkflowStatus.ProposalsRegistrationEnded, "La session des votes n'est pas ouverte");

        WorkflowStatus ancienEtat = EtatDesVotes;
        EtatDesVotes = WorkflowStatus.VotingSessionStarted;

        emit WorkflowStatusChange(ancienEtat,EtatDesVotes); // evenement changement de status
    }


    function Vote(uint256 _NumeroDeVote) public {

        // Verification que le votant est inscrit, n'a pas deja vote et que le vote est ouvert
        require(ListeVote[msg.sender].isRegistered &&
        !ListeVote[msg.sender].hasVoted &&
        EtatDesVotes == WorkflowStatus.VotingSessionStarted, "addresse non autorise ou session de vote fermer");

        // Verifie que l'index choisi existe dans le tableau
        require(_NumeroDeVote < Proposition.length,"Numero de vote incorrect");

        ListeVote[msg.sender].hasVoted = true;
        ListeVote[msg.sender].votedProposalId = _NumeroDeVote;

        Proposition[_NumeroDeVote].voteCount++; // ajoute un vote a la proposition choisie

        emit Voted(msg.sender, _NumeroDeVote);
    }


    function FermetureVote() public onlyOwner {

    require(EtatDesVotes == WorkflowStatus.VotingSessionStarted, "La session de vote n'est pas ouverte");

        WorkflowStatus ancienEtat = EtatDesVotes;
        EtatDesVotes = WorkflowStatus.VotingSessionEnded;

     emit WorkflowStatusChange(ancienEtat,EtatDesVotes); // evenement changement de status
    }


    function CompteurVoteGagnant () public onlyOwner returns (uint256) {
    require(EtatDesVotes == WorkflowStatus.VotingSessionEnded, "La session de vote est en cours");

        uint VoteMax = 0;
        uint IndicePropositionGagnante = 0;

 // On compare les votes de chaque proposition pour trouver celle qui en a le plus

    for (uint256 i = 0; i < Proposition.length; i++) {

    if (VoteMax < Proposition[i].voteCount) {
            VoteMax = Proposition[i].voteCount;
            IndicePropositionGagnante = i;
            }
        }

        // On garde l'index de la proposition gagnante
        winningProposalId = IndicePropositionGagnante;

        WorkflowStatus ancienEtat = EtatDesVotes;
        EtatDesVotes = WorkflowStatus.VotesTallied;

        emit WorkflowStatusChange(ancienEtat,EtatDesVotes);

        return winningProposalId;
    }

}