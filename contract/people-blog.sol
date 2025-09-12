// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PeoplesBlog
 * @dev A decentralized blogging platform where users can create, manage and interact with blog posts
 * @author Peoples Blog Team
 */
contract PeoplesBlog {
    
    // Structure to represent a blog post
    struct BlogPost {
        uint256 id;
        address author;
        string title;
        string content;
        string ipfsHash; // For storing large content on IPFS
        uint256 timestamp;
        uint256 likes;
        bool isActive;
        mapping(address => bool) likedBy;
    }
    
    // Structure for user profiles
    struct UserProfile {
        string username;
        string bio;
        string profileImageHash; // IPFS hash for profile image
        uint256 postCount;
        uint256 totalLikes;
        bool isRegistered;
    }
    
    // State variables
    mapping(uint256 => BlogPost) public blogPosts;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => uint256[]) public userPosts;
    
    uint256 public totalPosts;
    uint256 public totalUsers;
    address public owner;
    
    // Events
    event PostCreated(uint256 indexed postId, address indexed author, string title);
    event PostLiked(uint256 indexed postId, address indexed liker);
    event PostUnliked(uint256 indexed postId, address indexed unliker);
    event UserRegistered(address indexed user, string username);
    event PostDeactivated(uint256 indexed postId, address indexed author);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User must be registered");
        _;
    }
    
    modifier validPostId(uint256 _postId) {
        require(_postId > 0 && _postId <= totalPosts, "Invalid post ID");
        require(blogPosts[_postId].isActive, "Post is not active");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalPosts = 0;
        totalUsers = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new user profile
     * @param _username Unique username for the user
     * @param _bio User's biography
     * @param _profileImageHash IPFS hash for profile image
     */
    function registerUser(
        string memory _username, 
        string memory _bio, 
        string memory _profileImageHash
    ) external {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_username).length <= 50, "Username too long");
        
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            profileImageHash: _profileImageHash,
            postCount: 0,
            totalLikes: 0,
            isRegistered: true
        });
        
        totalUsers++;
        emit UserRegistered(msg.sender, _username);
    }
    
    /**
     * @dev Core Function 2: Create a new blog post
     * @param _title Title of the blog post
     * @param _content Content of the blog post
     * @param _ipfsHash IPFS hash for extended content storage
     */
    function createPost(
        string memory _title, 
        string memory _content, 
        string memory _ipfsHash
    ) external onlyRegisteredUser {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_content).length > 0, "Content cannot be empty");
        require(bytes(_title).length <= 200, "Title too long");
        
        totalPosts++;
        
        BlogPost storage newPost = blogPosts[totalPosts];
        newPost.id = totalPosts;
        newPost.author = msg.sender;
        newPost.title = _title;
        newPost.content = _content;
        newPost.ipfsHash = _ipfsHash;
        newPost.timestamp = block.timestamp;
        newPost.likes = 0;
        newPost.isActive = true;
        
        // Update user profile
        userProfiles[msg.sender].postCount++;
        userPosts[msg.sender].push(totalPosts);
        
        emit PostCreated(totalPosts, msg.sender, _title);
    }
    
    /**
     * @dev Core Function 3: Like or unlike a blog post
     * @param _postId ID of the post to like/unlike
     */
    function toggleLike(uint256 _postId) external onlyRegisteredUser validPostId(_postId) {
        BlogPost storage post = blogPosts[_postId];
        
        if (post.likedBy[msg.sender]) {
            // Unlike the post
            post.likedBy[msg.sender] = false;
            post.likes--;
            userProfiles[post.author].totalLikes--;
            emit PostUnliked(_postId, msg.sender);
        } else {
            // Like the post
            post.likedBy[msg.sender] = true;
            post.likes++;
            userProfiles[post.author].totalLikes++;
            emit PostLiked(_postId, msg.sender);
        }
    }
    
    // Additional utility functions
    
    /**
     * @dev Get post details (excluding mapping data)
     * @param _postId ID of the post to retrieve
     */
    function getPost(uint256 _postId) external view validPostId(_postId) returns (
        uint256 id,
        address author,
        string memory title,
        string memory content,
        string memory ipfsHash,
        uint256 timestamp,
        uint256 likes,
        bool isActive
    ) {
        BlogPost storage post = blogPosts[_postId];
        return (
            post.id,
            post.author,
            post.title,
            post.content,
            post.ipfsHash,
            post.timestamp,
            post.likes,
            post.isActive
        );
    }
    
    /**
     * @dev Check if user has liked a specific post
     * @param _postId ID of the post
     * @param _user Address of the user
     */
    function hasUserLikedPost(uint256 _postId, address _user) external view validPostId(_postId) returns (bool) {
        return blogPosts[_postId].likedBy[_user];
    }
    
    /**
     * @dev Get user's post IDs
     * @param _user Address of the user
     */
    function getUserPosts(address _user) external view returns (uint256[] memory) {
        return userPosts[_user];
    }
    
    /**
     * @dev Deactivate a post (only by author or owner)
     * @param _postId ID of the post to deactivate
     */
    function deactivatePost(uint256 _postId) external validPostId(_postId) {
        BlogPost storage post = blogPosts[_postId];
        require(
            msg.sender == post.author || msg.sender == owner, 
            "Only author or owner can deactivate post"
        );
        
        post.isActive = false;
        emit PostDeactivated(_postId, post.author);
    }
    
    /**
     * @dev Update user profile
     * @param _bio New biography
     * @param _profileImageHash New profile image hash
     */
    function updateProfile(string memory _bio, string memory _profileImageHash) external onlyRegisteredUser {
        UserProfile storage profile = userProfiles[msg.sender];
        profile.bio = _bio;
        profile.profileImageHash = _profileImageHash;
    }
    
    /**
     * @dev Get platform statistics
     */
    function getPlatformStats() external view returns (uint256, uint256) {
        return (totalPosts, totalUsers);
    }
    
    /**
     * @dev Emergency function to pause the contract (owner only)
     */
    function emergencyPause() external onlyOwner {
        // Implementation for emergency pause functionality
        // This is a placeholder for more complex pause mechanisms
    }
}
##contract
"C:\Users\kavya\OneDrive\Pictures\Screenshots\Screenshot 2025-09-10 133608.png"
