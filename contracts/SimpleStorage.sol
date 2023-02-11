// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <=0.8.0;

contract SimpleStorage {
    event StorageSet(string _message);

    uint public storedData;

    function set(uint x) public {
        storedData = x;

        emit StorageSet("Data stored successfully!!");
    }
}
