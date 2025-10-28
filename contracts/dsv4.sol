// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SkillVerify
 * @dev Decentralized platform for issuing and verifying professional skills and credentials
 */
contract SkillVerify {
    
    struct Credential {
        uint256 id;
        address holder;
        address issuer;
        string skillName;
        string credentialURI; // IPFS hash or metadata URI
        uint256 issueDate;
        uint256 expiryDate;
        bool isValid;
    }
    
    struct Issuer {
        bool isAuthorized;
        string organizationName;
        uint256 credentialsIssued;
    }
    
    // State variables
    uint256 private credentialCounter;
    address public admin;
    
    mapping(uint256 => Credential) public credentials;
    mapping(address => Issuer) public issuers;
    mapping(address => uint256[]) public holderCredentials;
    
    // Events
    event IssuerAuthorized(address indexed issuer, string organizationName);
    event CredentialIssued(uint256 indexed credentialId, address indexed holder, address indexed issuer, string skillName);
    event CredentialRevoked(uint256 indexed credentialId);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedIssuer() {
        require(issuers[msg.sender].isAuthorized, "Not an authorized issuer");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Authorize an organization to issue credentials
     * @param _issuer Address of the issuing organization
     * @param _organizationName Name of the organization
     */
    function authorizeIssuer(address _issuer, string memory _organizationName) 
        external 
        onlyAdmin 
    {
        require(!issuers[_issuer].isAuthorized, "Issuer already authorized");
        
        issuers[_issuer] = Issuer({
            isAuthorized: true,
            organizationName: _organizationName,
            credentialsIssued: 0
        });
        
        emit IssuerAuthorized(_issuer, _organizationName);
    }
    
    /**
     * @dev Issue a new credential to a holder
     * @param _holder Address of the credential holder
     * @param _skillName Name of the skill being certified
     * @param _credentialURI URI containing credential metadata
     * @param _expiryDate Expiry timestamp (0 for non-expiring)
     */
    function issueCredential(
        address _holder,
        string memory _skillName,
        string memory _credentialURI,
        uint256 _expiryDate
    ) 
        external 
        onlyAuthorizedIssuer 
        returns (uint256)
    {
        require(_holder != address(0), "Invalid holder address");
        require(bytes(_skillName).length > 0, "Skill name required");
        
        credentialCounter++;
        
        credentials[credentialCounter] = Credential({
            id: credentialCounter,
            holder: _holder,
            issuer: msg.sender,
            skillName: _skillName,
            credentialURI: _credentialURI,
            issueDate: block.timestamp,
            expiryDate: _expiryDate,
            isValid: true
        });
        
        holderCredentials[_holder].push(credentialCounter);
        issuers[msg.sender].credentialsIssued++;
        
        emit CredentialIssued(credentialCounter, _holder, msg.sender, _skillName);
        
        return credentialCounter;
    }
    
    /**
     * @dev Verify if a credential is valid
     * @param _credentialId ID of the credential to verify
     * @return isValid Whether the credential is valid
     * @return holder Address of the credential holder
     * @return issuer Address of the issuer
     * @return skillName Name of the skill
     * @return issueDate When the credential was issued
     */
    function verifyCredential(uint256 _credentialId) 
        external 
        view 
        returns (
            bool isValid,
            address holder,
            address issuer,
            string memory skillName,
            uint256 issueDate
        )
    {
        Credential memory cred = credentials[_credentialId];
        
        bool valid = cred.isValid && 
                     (cred.expiryDate == 0 || cred.expiryDate > block.timestamp);
        
        return (
            valid,
            cred.holder,
            cred.issuer,
            cred.skillName,
            cred.issueDate
        );
    }
    
    /**
     * @dev Revoke a credential (only by issuer)
     * @param _credentialId ID of the credential to revoke
     */
    function revokeCredential(uint256 _credentialId) external {
        Credential storage cred = credentials[_credentialId];
        require(cred.issuer == msg.sender, "Only issuer can revoke");
        require(cred.isValid, "Credential already revoked");
        
        cred.isValid = false;
        
        emit CredentialRevoked(_credentialId);
    }
    
    /**
     * @dev Get all credentials for a holder
     * @param _holder Address of the holder
     * @return Array of credential IDs
     */
    function getHolderCredentials(address _holder) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return holderCredentials[_holder];
    }
}
