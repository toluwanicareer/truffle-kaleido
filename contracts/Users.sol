// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <=0.8.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";


contract Users is Ownable{
    using Roles for Roles.Role;

    struct User {
        address userAddress;
        bool active;
        address referrerAddress;
        bool merchant;
        uint8[2] transactionFeeValues;
        uint8[2] exchangeFeeValues;
        uint16 remainingFreeTransactions;
        bool superReferrer;
        bool superUser;
    }

    User[] public users;
    mapping(address => uint256) public addressToUserIndex;
    uint256 public usersCount;

    Roles.Role assetTokenContracts;
    Roles.Role digitallContracts;
    Roles.Role admins;

    address public InOnePlaceWallet =
        0xceaCCe738B5c4e03b45561bFB5b3796B63cFeCDD;
    address public PrizeDrawWallet = 0xa1c86295E88fCfaDEf9FB518dC7201C85699D401;

    constructor() public {
        User memory user = User({
            userAddress: address(this),
            active: false,
            referrerAddress: address(0),
            merchant: true,
            transactionFeeValues: [0, 1],
            exchangeFeeValues: [0, 1],
            remainingFreeTransactions: 0,
            superReferrer: true,
            superUser: true
        });
        uint256 newUsersCount = users.push(user);
        uint256 newUserId = newUsersCount - 1;
        usersCount = newUsersCount;
        addressToUserIndex[address(this)] = newUserId;
    }

    modifier onlyAssetTokenContracts() {
        require(
            assetTokenContracts.has(msg.sender),
            "Caller is not an asset token contract."
        );
        _;
    }

    modifier onlyAdmins() {
        require(admins.has(msg.sender), "Caller is not an admin.");
        _;
    }

    modifier userExists(address userAddress) {
        require(addressToUserIndex[userAddress] > 0, "User does not exist.");
        _;
    }

    modifier userDoesNotExist(address userAddress) {
        require(addressToUserIndex[userAddress] == 0, "User already exists.");
        _;
    }

    modifier onlyDigitallContracts() {
        require(
            digitallContracts.has(msg.sender),
            "Caller is Digitall contract."
        );
        _;
    }

    function addDigitallContracts(address[] memory newContracts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newContracts.length; i++) {
            digitallContracts.add(newContracts[i]);
        }
    }

    function addAssetTokenContracts(address[] memory newContracts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < newContracts.length; i++) {
            assetTokenContracts.add(newContracts[i]);
        }
    }

    function addAdmins(address[] memory newAdmins) public onlyOwner {
        for (uint256 i = 0; i < newAdmins.length; i++) {
            admins.add(newAdmins[i]);
        }
    }

    function createUser(bool isMerchant,address accountAddress)
        public
        userDoesNotExist(accountAddress)
        returns (uint256)
    {
        User memory user = User({
            // userAddress: msg.sender,
            userAddress: accountAddress,
            active: true,
            referrerAddress: address(0),
            merchant: isMerchant,
            transactionFeeValues: [1, 25],
            exchangeFeeValues: [3, 200],
            remainingFreeTransactions: 10,
            superReferrer: false,
            superUser: false
        });
        uint256 newUsersCount = users.push(user);
        uint256 newUserId = newUsersCount - 1;
        usersCount = newUsersCount;
        addressToUserIndex[accountAddress] = newUserId;
        // addressToUserIndex[msg.sender] = newUserId;
        return newUserId;
    }

    function isActive(address userAddress)
        public
        view
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.active;
    }

    function isSuperUser(address userAddress)
        public
        view
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.superUser;
    }

    function isSuperReferrer(address userAddress)
        public
        view
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.superReferrer;
    }

    function isMerchant(address userAddress)
        public
        view
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.merchant;
    }

    function getUserAddress(uint256 _index) public view returns (address) {
        User storage user = users[_index];
        return user.userAddress;
    }

    function getTransactionFeeValues(address userAddress)
        public
        view
        userExists(userAddress)
        returns (uint8[2] memory)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.transactionFeeValues;
    }

    function getRemainingFreeTransactions(address userAddress)
        public
        view
        userExists(userAddress)
        returns (uint16)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.remainingFreeTransactions;
    }

    function getReferrerAddress(address userAddress)
        public
        view
        userExists(userAddress)
        returns (address)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.referrerAddress;
    }

    function getExchangeFeeValues(address userAddress)
        public
        view
        userExists(userAddress)
        returns (uint8[2] memory)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        return user.exchangeFeeValues;
    }

    function setStatus(address userAddress, bool newStatus)
        public
        onlyAdmins
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        user.active = newStatus;
        return true;
    }

    function setMerchant(address userAddress, bool newMerchant)
        public
        onlyAdmins
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        user.merchant = newMerchant;
        return true;
    }

    function setSuperUser(address userAddress, bool newStatus)
        public
        onlyAdmins
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        user.superUser = newStatus;
        return true;
    }

    function setSuperReferrer(address userAddress, bool newStatus)
        public
        onlyAdmins
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        user.superReferrer = newStatus;
        return true;
    }

    function setExchangeFeeValues(
        address userAddress,
        uint8[2] memory newExchangeFeeValues
    ) public onlyAdmins userExists(userAddress) returns (bool) {
        User storage user = users[addressToUserIndex[userAddress]];
        user.exchangeFeeValues = newExchangeFeeValues;
        return true;
    }

    function setTransactionFeeValues(
        address userAddress,
        uint8[2] memory newTransactionFeeValues
    ) public onlyAdmins userExists(userAddress) returns (bool) {
        User storage user = users[addressToUserIndex[userAddress]];
        user.transactionFeeValues = newTransactionFeeValues;
        return true;
    }

    function increaseRemainingFreeTransactions(
        address userAddress,
        uint16 amount
    ) public onlyAdmins userExists(userAddress) returns (bool) {
        User storage user = users[addressToUserIndex[userAddress]];
        user.remainingFreeTransactions += amount;
        return true;
    }

    function setRemainingFreeTransactions(
        address userAddress,
        uint16 newRemainingFreeTransactions
    ) public onlyAdmins userExists(userAddress) returns (bool) {
        User storage user = users[addressToUserIndex[userAddress]];
        user.remainingFreeTransactions = newRemainingFreeTransactions;
        return true;
    }

    function setReferrerAddress(address userAddress, address referrerAddress)
        public
        onlyAdmins
        userExists(userAddress)
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];
        user.referrerAddress = referrerAddress;
        return true;
    }

    function decrementFreeTransactions(address userAddress)
        public
        onlyAssetTokenContracts
        returns (bool)
    {
        User storage user = users[addressToUserIndex[userAddress]];

        if (user.remainingFreeTransactions > 0) {
            user.remainingFreeTransactions -= 1;
        }

        return true;
    }
}
