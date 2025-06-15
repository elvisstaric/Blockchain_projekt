// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Booking_contract {
    address public owner;
    string public accommodationName;
    uint public pricePerNight;
    uint public bookingStart;
    uint public bookingEnd;
    address public guest;
    bool public isBooked;
    bool public isFullyPaid;
    bool public isWithdrawn;

    uint public depositAmount;
    uint public remainingAmount;

    event Booked(address indexed guest, uint depositPaid, uint startDate, uint endDate);
    event FinalPaymentMade(address indexed guest, uint amount);
    event PaymentWithdrawn(address indexed owner, uint totalAmount);
    event BookingCancelled(address indexed guest, uint refundAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner only.");
        _;
    }

    modifier onlyGuest() {
        require(msg.sender == guest, "Guest only.");
        _;
    }

    modifier notBooked() {
        require(!isBooked, "Accomodation already booked.");
        _;
    }

    constructor(string memory _name, uint _pricePerNight) {
        owner = msg.sender;
        accommodationName = _name;
        pricePerNight = _pricePerNight;
    }


    function book(uint _startDate, uint _endDate) external payable notBooked {
        require(_endDate > _startDate, "Date error.");
        uint numberOfNights = (_endDate - _startDate) / 1 days;
        require(numberOfNights > 0, "One noght minimum.");
        
        uint totalPrice = numberOfNights * pricePerNight;
        uint requiredDeposit = (totalPrice * 30) / 100;

        require(msg.value >= requiredDeposit, "Insufficient deposit (30% minimum).");

        guest = msg.sender;
        bookingStart = _startDate;
        bookingEnd = _endDate;
        depositAmount = requiredDeposit;
        remainingAmount = totalPrice - depositAmount;
        isBooked = true;

        emit Booked(msg.sender, msg.value, _startDate, _endDate);
    }

    function payRemaining() external payable onlyGuest {
        require(isBooked, "No reservation.");
        require(!isFullyPaid, "Already payed.");
        require(msg.value >= remainingAmount, "Insufficient funds.");

        isFullyPaid = true;

        emit FinalPaymentMade(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        require(isBooked, "No reservation.");
        require(isFullyPaid, "Reservation not paid in full.");

        require(block.timestamp >= bookingEnd, "Reservation did not end.");

        uint balance = address(this).balance;
        require(balance > 0, "No funds.");

        payable(owner).transfer(balance);

        emit PaymentWithdrawn(owner, balance);
        isWithdrawn=true;
    }

    function cancelBooking() external onlyGuest {
        require(isBooked, "No reservation.");
        require(!isFullyPaid, "Cannot be canceled after full payment.");

        uint refund = address(this).balance;

        guest = address(0);
        bookingStart = 0;
        bookingEnd = 0;
        isBooked = false;
        depositAmount = 0;
        remainingAmount = 0;

        payable(msg.sender).transfer(refund);

        emit BookingCancelled(msg.sender, refund);
    }

    function getBookingDetails() external view returns (
        address currentGuest,
        uint startDate,
        uint endDate,
        bool bookingStatus,
        bool fullyPaid,
        uint paidDeposit,
        uint remainingToPay,
        bool withdrawn
    ) {
        return (
            guest,
            bookingStart,
            bookingEnd,
            isBooked,
            isFullyPaid,
            depositAmount,
            remainingAmount,
            isWithdrawn
        );
    }
}


