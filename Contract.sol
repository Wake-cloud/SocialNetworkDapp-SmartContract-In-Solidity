// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    constructor() {}

    struct User {
        string image;
        string name;
        string bio;
        uint256 id;
    }

    struct Notification {
        string message;
        uint256 timestamp;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
    }

    struct Posts {
        string image;
        string text;
        uint256 timestamp;
        uint256 likes;
        uint256 views;
        uint256 commentsCount;
        address[] taggedUsers; // Added tagged users array
    }

    struct Messages {
        string text;
        string image;
        uint256 timestamp;
    }

    // State Variables
    mapping(address => Posts[]) public userPosts; // Maps a wallet address to multiple posts.
    mapping(address => User) public users; // Maps a wallet address to the User struct.
    mapping(address => mapping(address => Messages[])) public messages; // Messages between users.
    mapping(address => address[]) public followers; // Tracks followers of each user.
    mapping(address => address[]) public following; // Tracks users each address is following.
    mapping(address => bool) public isProfilePrivate;
    mapping(uint256 => mapping(address => string)) public postReactions; // Maps post ID to user reactions
    mapping(address => Notification[]) public notifications;
    mapping(address => uint256) public reputation;
    mapping(uint256 => bool) public isPostNFT;
    mapping(address => Report[]) public reportedProfiles;
    mapping(address => mapping(uint256 => Report[])) public reportedPosts;
    mapping(address => uint256) public tokens;

    // Function to check if image and name are set for a user
    function isUserValid(address user) public view returns (bool) {
        User memory u = users[user];
        require(
            bytes(u.image).length > 0 && bytes(u.name).length > 0,
            "Image or name is missing"
        );
        return true;
    }

    // Function to fetch all posts of a specific user
    function fetchAllPosts(address user) public view returns (Posts[] memory) {
        return userPosts[user];
    }

    // Display all posts of all users
    function displayAllPosts() public view returns (Posts[] memory) {
        uint256 totalPosts;
        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            totalPosts += userPosts[following[msg.sender][i]].length;
        }

        Posts[] memory allPosts = new Posts[](totalPosts);
        uint256 index = 0;

        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            address user = following[msg.sender][i];
            Posts[] memory posts = userPosts[user];

            for (uint256 j = 0; j < posts.length; j++) {
                allPosts[index] = posts[j];
                index++;
            }
        }
        return allPosts;
    }

    // Send a message to another user
    function sendMessage(
        address to,
        string memory text,
        string memory image
    ) public {
        messages[msg.sender][to].push(
            Messages({text: text, image: image, timestamp: block.timestamp})
        );
    }

    // See messages between sender and a specific user
    function seeMessages(
        address withUser
    ) public view returns (Messages[] memory) {
        return messages[msg.sender][withUser];
    }

    // See all user profiles
    function seeAllProfiles() public view returns (User[] memory) {
        uint256 totalUsers = following[msg.sender].length;
        User[] memory allUsers = new User[](totalUsers);

        for (uint256 i = 0; i < totalUsers; i++) {
            allUsers[i] = users[following[msg.sender][i]];
        }
        return allUsers;
    }

    // Follow another user
    function followUser(address userToFollow) public {
        require(userToFollow != msg.sender, "You cannot follow yourself.");

        // Check if already following
        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            require(
                following[msg.sender][i] != userToFollow,
                "Already following this user."
            );
        }

        followers[userToFollow].push(msg.sender);
        following[msg.sender].push(userToFollow);
        notifyUser(userToFollow, "You have a new follower!");
    }

    // Comment on a post (increase comment count)
    function commentPost(address user, uint256 postIndex) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        userPosts[user][postIndex].commentsCount++;
    }

    // Share a post
    function sharePost(address user, uint256 postIndex) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        userPosts[msg.sender].push(userPosts[user][postIndex]);
    }

    // Get views for a specific post
    function getPostViews(
        address user,
        uint256 postIndex
    ) public view returns (uint256) {
        require(postIndex < userPosts[user].length, "Invalid post index");
        return userPosts[user][postIndex].views;
    }

    // Get all followers of a user
    function getAllFollowers(
        address user
    ) public view returns (address[] memory) {
        return followers[user];
    }

    // Check if the current user follows another user
    function userFollow(address user) public view returns (bool) {
        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            if (following[msg.sender][i] == user) {
                return true;
            }
        }
        return false;
    }

    // Unfriend a user (remove from following list)
    function unFriend(address user) public {
        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            if (following[msg.sender][i] == user) {
                following[msg.sender][i] = following[msg.sender][
                    following[msg.sender].length - 1
                ];
                following[msg.sender].pop();
                break;
            }
        }

        for (uint256 i = 0; i < followers[user].length; i++) {
            if (followers[user][i] == msg.sender) {
                followers[user][i] = followers[user][
                    followers[user].length - 1
                ];
                followers[user].pop();
                break;
            }
        }
    }

    // Add a friend (mutual following)
    function addFriend(address user) public {
        followUser(user);
        followers[msg.sender].push(user);
    }

    // Function to retrieve the caller's wallet address
    function seeWalletAddress() public view returns (address) {
        return msg.sender; // Returns the address of the caller
    }

    // Function to display the profile of the caller
    function displayProfile() public view returns (User memory) {
        User memory user = users[msg.sender];
        require(bytes(user.name).length > 0, "Profile does not exist.");
        return user;
    }

    // Function to update the profile of the caller
    function updateProfile(
        string memory _image,
        string memory _name,
        string memory _bio
    ) public {
        require(bytes(_name).length > 0, "Name cannot be empty.");
        require(bytes(_image).length > 0, "Image cannot be empty.");

        users[msg.sender] = User({
            image: _image,
            name: _name,
            bio: _bio,
            id: uint256(uint160(msg.sender)) // Example ID based on wallet address
        });
    }

    function setProfilePrivacy(bool _isPrivate) public {
        isProfilePrivate[msg.sender] = _isPrivate;
    }

    function getProfile(address user) public view returns (User memory) {
        if (isProfilePrivate[user]) {
            require(isFollower(msg.sender, user), "This profile is private.");
        }
        return users[user];
    }

    function isFollower(
        address follower,
        address user
    ) internal view returns (bool) {
        for (uint256 i = 0; i < followers[user].length; i++) {
            if (followers[user][i] == follower) {
                return true;
            }
        }
        return false;
    }

    function createPost(
        string memory image,
        string memory text,
        address[] memory taggedUsers
    ) public {
        userPosts[msg.sender].push(
            Posts({
                image: image,
                text: text,
                timestamp: block.timestamp,
                likes: 0,
                views: 0,
                commentsCount: 0,
                taggedUsers: taggedUsers // Added tagged users
            })
        );
    }

    function viewPost(address user, uint256 postIndex) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        userPosts[user][postIndex].views++;
    }

    function reactToPost(
        address user,
        uint256 postIndex,
        string memory emoji
    ) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        postReactions[postIndex][msg.sender] = emoji;
    }

    function notifyUser(address user, string memory message) internal {
        notifications[user].push(
            Notification({message: message, timestamp: block.timestamp})
        );
    }

    function increaseReputation(address user, uint256 amount) internal {
        reputation[user] += amount;
    }

    function likePost(address user, uint256 postIndex) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        userPosts[user][postIndex].likes++;
        increaseReputation(user, 10); // Reward reputation for likes
    }

    function mintPostAsNFT(uint256 postIndex) public {
        require(postIndex < userPosts[msg.sender].length, "Invalid post index");
        isPostNFT[postIndex] = true;
    }

    function reportProfile(address user, string memory reason) public {
        reportedProfiles[user].push(
            Report({
                reporter: msg.sender,
                reason: reason,
                timestamp: block.timestamp
            })
        );
    }

    function reportPost(
        address user,
        uint256 postIndex,
        string memory reason
    ) public {
        reportedPosts[user][postIndex].push(
            Report({
                reporter: msg.sender,
                reason: reason,
                timestamp: block.timestamp
            })
        );
    }

    function rewardUser(address user, uint256 amount) internal {
        tokens[user] += amount;
    }

    
    function likePostAndReward(address user, uint256 postIndex) public {
        require(postIndex < userPosts[user].length, "Invalid post index");
        userPosts[user][postIndex].likes++;
        rewardUser(user, 5); // Reward tokens for getting likes
    }

    function getMostLikedPost(address user) public view returns (Posts memory) {
        Posts[] memory posts = userPosts[user];
        uint256 maxLikes = 0;
        uint256 maxIndex = 0;

        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].likes > maxLikes) {
                maxLikes = posts[i].likes;
                maxIndex = i;
            }
        }
        return posts[maxIndex];
    }
}
