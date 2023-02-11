// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <=0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";


contract UsersInstance {
    address public InOnePlaceWallet;
    address public PrizeDrawWallet;
    function isActive(address userAddress) public view returns (bool);
    function getReferrerAddress(address userAddress) public view returns (address);
    function isMerchant(address userAddress) public view returns (bool);
    function decrementFreeTransactions(address userAddress) public returns (bool);
}
    
contract DigitallInstance {
    function getPurchaseWithCreditCardFeeValues() public view returns (uint256[3] memory);
    function getPurchaseWithCryptoFeeValues() public view returns (uint256[3] memory);
    function getPurchaseWithEurCreditCardFeeValues() public view returns (uint256[3] memory);
    function getStorageFeeValues() public view returns (uint256[2] memory);
    function determineFeeSplit(
        uint256 fee,
        address fromReferrerAddress,
        address toReferrerAddress
        ) public pure returns (uint256[5] memory);
    function calculateTransactionFee( address userAddress, uint256 value) public view returns (uint256);
    function determineTransactionFree(address userAddress) public view returns (bool);
    function determineWinner(uint256 salt) public view returns (address);}
    
contract RefundInstance {
    function addTransaction(
        string memory transactionType,
        address sender,
        address recipient,
        address tokenAddress,
        uint256 amount
        ) public returns (uint256);
    }

contract AssetToken is
    ERC20,
    ERC20Detailed,
    ERC20Mintable,
    ERC20Burnable,
    Ownable
    {
    
    uint8 constant DECIMALS = 6;
    address public UsersContractAddress;
    address public ExchangeContractAddress;
    address public DigitallContractAddress;
    address public RefundContractAddress;
    
    using Roles for Roles.Role;
    Roles.Role digitallContracts;
    
    constructor(
    string memory name,
    string memory symbol,
    address exchangeAddress,
    address usersAddress,
    address digitallAddress,
    address refundAddress)
    ERC20Burnable()
    ERC20Mintable()
    ERC20Detailed(name, symbol, DECIMALS)
    ERC20()
    public
    {
    ExchangeContractAddress = exchangeAddress;
    UsersContractAddress = usersAddress;
    DigitallContractAddress = digitallAddress;
    RefundContractAddress = refundAddress;
    }
    
    modifier onlyDigitallContracts() {
        require(digitallContracts.has(msg.sender), "Caller is a Digitall contract");
        _;
    }

    modifier active() {
        UsersInstance u = UsersInstance(UsersContractAddress);
        require(u.isActive(msg.sender), "User is not active.");
        _;
    }

    function addDigitallContracts(address[] memory newContracts) public onlyOwner {
        for(uint i = 0; i < newContracts.length; i++) {
            digitallContracts.add(newContracts[i]);
        }
    }

    function changeDigitallContractAddress(address oldAddress, address newAddress)
        public
        onlyOwner
        returns (bool)
    {
        digitallContracts.remove(oldAddress);
        digitallContracts.add(newAddress);
        DigitallContractAddress = newAddress;
        return true;
    }

    function changeExchangeContractAddress(address oldAddress, address newAddress)
        public
        onlyOwner
        returns (bool)
    {
        digitallContracts.remove(oldAddress);
        digitallContracts.add(newAddress);
        ExchangeContractAddress = newAddress;
        return true;
    }

    function changeUsersContractAddress(address oldAddress, address newAddress)
        public
        onlyOwner
        returns (bool)
    {
        digitallContracts.remove(oldAddress);
        digitallContracts.add(newAddress);
        UsersContractAddress = newAddress;
        return true;
    }

    function changeRefundContractAddress(address oldAddress, address newAddress)
        public
        onlyOwner
        returns (bool)
    {
        digitallContracts.remove(oldAddress);
        digitallContracts.add(newAddress);
        RefundContractAddress = newAddress;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        onlyDigitallContracts
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        uint256 allowance = allowance(sender, msg.sender);
        _approve(sender, msg.sender, allowance.sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _safeDecreaseAllowance(address owner, uint256 value)
        internal
        returns (bool)
    {
        UsersInstance u = UsersInstance(UsersContractAddress);
        uint256 allowance = allowance(owner, u.InOnePlaceWallet());

        if (allowance > value) {
            _approve(owner, u.InOnePlaceWallet(), allowance.sub(value));
        } else {
            _approve(owner, u.InOnePlaceWallet(), 0);
        }
        return true;
    }

    function purchaseTokens(address recipient, uint256 amount, uint8 source)
        public
        onlyMinter
        returns (bool)
    {
        require(source <= 2, "Source must be an int less than 3; 0 = US, 1 = EUR, 2 = Crypto.");

        UsersInstance u = UsersInstance(UsersContractAddress);
        DigitallInstance d = DigitallInstance(DigitallContractAddress);
        uint256[2] memory storageFeeValues = d.getStorageFeeValues();
        uint256[3] memory feeValues;

        if (source == 0) {feeValues = d.getPurchaseWithCreditCardFeeValues();}
        if (source == 1) {feeValues = d.getPurchaseWithEurCreditCardFeeValues();}
        if (source == 2) {feeValues = d.getPurchaseWithCryptoFeeValues();}

        uint256 allowance = allowance(recipient, u.InOnePlaceWallet());
        uint256 fee = amount.mul(feeValues[0]).div(feeValues[1]).add(feeValues[2]);
        uint256 total = amount.sub(fee);
        uint256 storageFee = total.mul(storageFeeValues[0]).div(storageFeeValues[1]);

        _mint(recipient, total);
        _mint(u.InOnePlaceWallet(), fee);
        _approve(recipient, u.InOnePlaceWallet(), allowance.add(storageFee));

        emit CreditCardPurchase(recipient, symbol(), amount, fee);
        return true;
    }

    function _transfersWithFee(
        address[3] memory addresses,
        // [0] Initial Sender
        // [1] Sender address
        // [2] Receiver address
        uint256[2] memory inputs
        // [0] amount
        // [1] salt
    )
        internal
        returns (uint256[2] memory)
    {
        UsersInstance u = UsersInstance(UsersContractAddress);
        RefundInstance r = RefundInstance(RefundContractAddress);
        DigitallInstance d = DigitallInstance(DigitallContractAddress);

        uint256 fee = d.calculateTransactionFee(addresses[2], inputs[0]);
        uint256 total = inputs[0] - fee;
        address fromReferrer = u.getReferrerAddress(addresses[0]);
        address toReferrer = u.getReferrerAddress(addresses[2]);
        uint256[5] memory values = d.determineFeeSplit(fee, fromReferrer, toReferrer);
        // amounts to be transfered for:
        // [0] fromReferrer
        // [1] toReferrer
        // [2] PrizeDrawWallet
        // [3] 'Random' winner
        // [4] InOnePlaceWallet

        if (values[0] != 0) {
            _transfer(addresses[1], fromReferrer, values[0]);
            emit MoneyEarned(fromReferrer, addresses[0], values[0], symbol());
        }
        if (values[1] != 0) {
            _transfer(addresses[1], toReferrer, values[1]);
            emit MoneyEarned(toReferrer, addresses[2], values[1], symbol());
        }
        _transfer(addresses[1], u.PrizeDrawWallet(), values[2]);
        _transfer(addresses[1], d.determineWinner(inputs[1]), values[3]);
        _transfer(addresses[1], u.InOnePlaceWallet(), values[4]);
        _transfer(addresses[1], addresses[2], total);

        uint256 transactionId = r.addTransaction('transfer', addresses[0], addresses[2], address(this), total);

        if (u.isMerchant(addresses[2])) {
            emit CustomTransfer(transactionId, symbol(), addresses[0], addresses[2], total, fee, "C2MTransfer");
        } else {
            emit CustomTransfer(transactionId, symbol(), addresses[0], addresses[2], total, fee, "C2CTransfer");
        }

        return [total, transactionId];
    }

    function cashOut(uint256 amount)
        public
        active
        returns (bool)
    {
        UsersInstance u = UsersInstance(UsersContractAddress);
        RefundInstance r = RefundInstance(RefundContractAddress);

        _transfer(msg.sender, u.InOnePlaceWallet(), amount);
        r.addTransaction('withdrawal', msg.sender, u.InOnePlaceWallet(), address(this), amount);
        return true;
    }

    function _doTransfers(
        address initialSender,
        address sender,
        address recipient,
        uint256 amount,
        uint256 salt
    )
        internal
        returns (uint256)
    {
        UsersInstance u = UsersInstance(UsersContractAddress);
        DigitallInstance d = DigitallInstance(DigitallContractAddress);

        uint256 recipientAllowance = allowance(recipient, u.InOnePlaceWallet());
        uint256[2] memory storageFeeValues = d.getStorageFeeValues();
        uint256 storageFee;
        uint256 transactionId;

        if (d.determineTransactionFree(recipient)) {
            RefundInstance r = RefundInstance(RefundContractAddress);
            _transfer(sender, recipient, amount);
            transactionId = r.addTransaction('transfer', sender, recipient, address(this), amount);
            storageFee = amount.mul(storageFeeValues[0]).div(storageFeeValues[1]);
            _safeDecreaseAllowance(sender, storageFee);
            _approve(recipient, u.InOnePlaceWallet(), recipientAllowance.add(storageFee));
            emit CustomTransfer(transactionId, symbol(), sender, recipient, amount, 0, "C2CTransfer");
        } else {
            uint256[2] memory ret = _transfersWithFee([initialSender, sender, recipient], [amount, salt]);
            transactionId = ret[1];
            storageFee = ret[0].mul(storageFeeValues[0]).div(storageFeeValues[1]);
            _safeDecreaseAllowance(sender, storageFee);
            _approve(recipient, u.InOnePlaceWallet(), recipientAllowance.add(storageFee));
        }

        u.decrementFreeTransactions(recipient);
        return transactionId;
    }

    function digitallTransfer(address to, uint256 value, uint256 salt)
        public
        active
        returns (uint256)
    {
        return _doTransfers(msg.sender, msg.sender, to, value, salt);
    }

    function transfer(address recipient, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function digitallWithdrawTo(address from, address to, uint256 value, uint256 salt)
        public
        onlyDigitallContracts
        returns (bool)
    {
        _doTransfers(from, address(this), to, value, salt);
        return true;
    }

    function withdrawTo(address recipient, uint256 amount)
        public
        onlyDigitallContracts
        returns (bool)
    {
        _transfer(address(this), recipient, amount);
        return true;
    }
}
