// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract donat {

    enum Status {COMPLETED, PENDING, CANCELED}

    address payable public to; // freelancer
    address payable public from; // employer
    uint256 public price;
    uint256 public deadline;
    uint256 public createdAt;
    uint256 public remainingPayment;
    bool locked = false;

    Status public status;

    struct donat {
        string name;
        string description;
        uint256 amount;
        bool locked;
        bool paid;
    }

    donat [] public donats;

    constructor (address payable _to, uint256 _deadline) payable {
        to = _to;
        from = payable(msg.sender);
        createdAt = block.timestamp;
        deadline = block.timestamp + _deadline;
        price = msg.value;
        remainingPayment = msg.value;
        status = Status.PENDING;
    }

    modifier onlyFreelancer () {
        require(msg.sender == to,"You are not Freelancer");
        _;
    }

    modifier onlyEmployer () {
        require(msg.sender == from,"You are not Employer");
        _;
    }

    modifier onlyPending () {
        require(status == Status.PENDING,"Status is not pending");
        _;
    }

    event requestCreated(string name ,string description, uint amount, bool locked, bool paid);
    event requestUnlocked(bool locked);
    event RequestPaid(address to, uint amount);
    event ProjectCompleted(address from, address to, uint amount, Status status);
    event ProjectCancele(uint remainingPayment, Status status);                                                                                                                                                                                              

    function createDonat (string memory _name, string memory _description, uint256 _amount) public onlyFreelancer onlyPending {
        require(_amount <= remainingPayment,"This value is more than remaining payment");
        donat memory Donat = donat({
            name: _name,
            description: _description,
            amount: _amount,
            locked: true,
            paid: false
        });

        donats.push(Donat);

        emit requestCreated(Donat.name, Donat.description, Donat.amount, Donat.locked, Donat.paid); 
    }

    function onlockReq(uint256 key) public onlyEmployer onlyPending {
        donat storage Donat = donats[key];
        require(Donat.locked,"Already onlocked!");
        Donat.locked = false;

        emit requestUnlocked(Donat.locked);
    }

    function payRequest (uint256 key) public onlyFreelancer onlyPending {
        require(!locked,"Reentrant detected!");
        donat storage Donat = donats[key];
        require(!Donat.locked,"request is locked");
        require(!Donat.paid,"Already paid");
        locked = true;
        (bool success, bytes memory transaction) = to.call{value: Donat.amount}("");
        require(success,"transaction faild");
        remainingPayment -= Donat.amount;
        Donat.paid = true;
        locked = true;
        emit RequestPaid(msg.sender, Donat.amount);
    }

    function requestCompleted () public onlyEmployer onlyPending {
        require(!locked, "Reentrant detected!");
        locked = true;
        (bool success, bytes memory transaction) = to.call{value: remainingPayment}("");
        require(success,"transaction faild");
        status = Status.COMPLETED;
        locked = false;
        emit ProjectCompleted(from, to, remainingPayment, status);
    }

    function canceledProject () public onlyEmployer onlyPending {
        require(!locked, "Reentrant detected!");
        require(block.timestamp > deadline,"Not now!");
        (bool success, bytes memory transaction) = from.call{value: remainingPayment}("");
        require(success,"transaction faild");
        status = Status.CANCELED;
        locked = false;
        emit ProjectCancele(remainingPayment, status);
    }

    function increaseDeadline (uint _deadline) public onlyEmployer onlyEmployer {
        deadline += _deadline;
    }

}