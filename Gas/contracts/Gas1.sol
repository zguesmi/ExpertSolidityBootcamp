// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";


contract GasContract is Ownable {
    uint256 public totalSupply; // cannot be updated
    uint256 public paymentCounter;
    address public contractOwner;
    address[5] public administrators;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;

    struct Payment {
        uint256 paymentID;
        bool adminUpdated;
        PaymentType paymentType;
        address recipient;
        string recipientName; // max 8 characters
        address admin; // administrators address
        uint256 amount;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == contractOwner || isAdmin(msg.sender), "E1");
        _;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 i = 0; i < administrators.length; i++) {
            if (_admins[i] != address(0)) {
                administrators[i] = _admins[i];
                if (_admins[i] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[i], totalSupply);
                } else {
                    balances[_admins[i]] = 0;
                    emit supplyChanged(_admins[i], 0);
                }
            }
        }
    }

    function isAdmin(address _user) public view returns (bool) {
        for (uint256 i = 0; i < administrators.length; i++) {
            if (administrators[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        balance_ = balances[_user];
    }

    function getTradingMode() external pure returns (bool mode_) {
        mode_ = true;
    }

    function getPayments(address _user)
        external
        view
        returns (Payment[] memory payments_)
    {
        require(_user != address(0), "E2");
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) external returns (bool status_) {
        // Check sender's balance
        require(balances[msg.sender] >= _amount, "E3");
        // Max length of the recipient name is 8 characters
        require(bytes(_name).length < 9, "E4");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        // Add payment to address
        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);
        status_ = true;
    }

    function updatePayment(
        address _user,
        uint256 _id,
        uint256 _amount,
        PaymentType _type
    ) external onlyAdminOrOwner {
        // Id must be greater than 0
        require(_id > 0, "E5");
        // Amount must be greater than 0
        require(_amount > 0, "E6");
        // Administrator must have a valid non zero address
        require(_user != address(0), "E7");
        for (uint256 i = 0; i < payments[_user].length; i++) {
            if (payments[_user][i].paymentID == _id) {
                payments[_user][i].adminUpdated = true;
                payments[_user][i].admin = _user;
                payments[_user][i].paymentType = _type;
                payments[_user][i].amount = _amount;
                emit PaymentUpdated(
                    msg.sender,
                    _id,
                    _amount,
                    payments[_user][i].recipientName
                );
            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        // Tier level should not be greater than 255
        require(_tier < 255, "E8");
        // Should be; whitelist[_userAddrs] = min(_tier, 3)
        whitelist[_userAddrs] = _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        // Sender has insufficient balance
        require(balances[msg.sender] >= _amount, "E9");
        // Amount to send have to be bigger than 3
        require(_amount > 3, "E10");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];
        emit WhiteListTransfer(_recipient);
    }
}
