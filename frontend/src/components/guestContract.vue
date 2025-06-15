<template>
  <div>
    <h2>Booking System</h2>

    <div style="margin-bottom: 1em">
      <button @click="activeTab = 'new'" :disabled="activeTab === 'new'">
        New Booking
      </button>
      <button @click="activeTab = 'view'" :disabled="activeTab === 'view'">
        View Bookings
      </button>
    </div>

    <div v-if="activeTab === 'new'">
      <h3>Create a new booking</h3>

      <label>
        Choose contract:
        <select v-model="selectedContractAddress">
          <option disabled value="">Please choose contract</option>
          <option
            v-for="contract in contracts"
            :key="contract.address"
            :value="contract.address"
          >
            {{ contract.accommodationName }} - {{ contract.pricePerNight }} ETH
          </option>
        </select>
      </label>

      <div
        v-if="selectedContractAddress"
        style="margin-top: 1em"
        @change="calculateTotal"
      >
        <label>
          From:
          <input type="date" v-model="startDate" @change="calculateTotal" />
        </label>

        <label>
          To:
          <input type="date" v-model="endDate" @change="calculateTotal" />
        </label>

        <label>
          Deposit (ETH):
          <input
            type="number"
            step="0.0001"
            v-model="deposit"
            :placeholder="`Min deposit: ${minDeposit} ETH`"
          />
        </label>
        <p>Total: {{ totalPrice }} ETH</p>
        <button @click="bookContract">Book</button>
      </div>
    </div>

    <div v-if="activeTab === 'view'">
      <h3>Your bookings</h3>

      <div v-if="userBookings.length === 0">
        <p>You have no bookings.</p>
      </div>

      <ul v-else>
        <li
          v-for="contract in userBookings"
          :key="contract.address"
          style="margin-bottom: 1em"
        >
          <strong>{{ contract.accommodationName }}</strong> -
          {{ contract.pricePerNight }} ETH<br />
          <p>
            <strong>Booking From:</strong>
            {{ formatDate(contract.bookingStart) }}
          </p>
          <p>
            <strong>Booking To:</strong> {{ formatDate(contract.bookingEnd) }}
          </p>

          <p>
            <strong>Remaining:</strong>
            {{ formattedRemainingMap[contract.address] }} ETH
          </p>

          <button @click="payRemaining(contract.address)">Pay Remaining</button>

          <button @click="cancelBooking(contract.address)">
            Cancel Booking
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { ethers } from "ethers";
import BookingContractArtifact from "../../../../artifacts/contracts/booking.sol/Booking_contract.json";

export default {
  data() {
    return {
      contracts: null,
      userBookings: null,
      selectedContractAddress: "",
      startDate: "",
      endDate: "",
      deposit: "",
      activeTab: "new",
      totalPrice: 0,
    };
  },
  async created() {
    await this.loadAllContracts();
    await this.loadUserBookings();
  },
  computed: {
    minDeposit() {
      if (!this.selectedContractAddress || !this.startDate || !this.endDate) {
        return 0;
      }
      const contract = this.contracts.find(
        (c) => c.address === this.selectedContractAddress
      );
      if (!contract) return 0;

      const startDateUnix = Math.floor(
        new Date(this.startDate).getTime() / 1000
      );
      const endDateUnix = Math.floor(new Date(this.endDate).getTime() / 1000);
      if (endDateUnix <= startDateUnix) return 0;

      const nights = (endDateUnix - startDateUnix) / 86400;
      const totalPrice = nights * parseFloat(contract.pricePerNight);
      return totalPrice * 0.3;
    },
    formattedRemainingMap() {
      const result = {};
      if (!this.userBookings) return result;

      for (const booking of this.userBookings) {
        if (booking.isFullyPaid) {
          result[booking.address] = "0";
        } else if (booking.remainingAmount) {
          result[booking.address] = ethers.formatEther(
            booking.remainingAmount.toString()
          );
        } else {
          result[booking.address] = "0";
        }
      }

      return result;
    },
  },

  methods: {
    calculateTotal() {
      if (!this.selectedContractAddress || !this.startDate || !this.endDate) {
        this.totalPrice = 0;
        return;
      }
      const contract = this.contracts.find(
        (c) => c.address === this.selectedContractAddress
      );
      if (!contract) {
        this.totalPrice = 0;
        return;
      }

      const startDateUnix = Math.floor(
        new Date(this.startDate).getTime() / 1000
      );
      const endDateUnix = Math.floor(new Date(this.endDate).getTime() / 1000);

      if (endDateUnix <= startDateUnix) {
        this.totalPrice = 0;
        return;
      }

      const nights = (endDateUnix - startDateUnix) / 86400;
      const pricePerNight = parseFloat(contract.pricePerNight);

      this.totalPrice = nights * pricePerNight;
    },

    async bookContract() {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      if (!this.selectedContractAddress) {
        alert("Choose contract.");
        return;
      }

      if (!this.startDate || !this.endDate) {
        alert("Enter dates.");
        return;
      }

      const startDateUnix = Math.floor(
        new Date(this.startDate).getTime() / 1000
      );
      const endDateUnix = Math.floor(new Date(this.endDate).getTime() / 1000);

      if (endDateUnix <= startDateUnix) {
        alert("End date must me after start date.");
        return;
      }

      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();

        const contract = new ethers.Contract(
          this.selectedContractAddress,
          BookingContractArtifact.abi,
          signer
        );

        const priceWei = await contract.pricePerNight();
        const priceEther = parseFloat(ethers.formatEther(priceWei));

        const numberOfNights = (endDateUnix - startDateUnix) / 86400;

        const totalPriceEther = numberOfNights * priceEther;
        const minDepositEther = totalPriceEther * 0.3;

        const userDepositEth = parseFloat(this.deposit);
        if (isNaN(userDepositEth) || userDepositEth < minDepositEther) {
          alert(`Deposit must be at least 30%: minimum ${minDepositEther} ETH`);
          return;
        }

        const deposit = ethers.parseEther(userDepositEth.toString());
        console.log(deposit);
        const tx = await contract.book(startDateUnix, endDateUnix, {
          value: deposit,
        });
        await tx.wait();

        alert("Rezervation sucessfull!");
      } catch (err) {
        console.error(err);
        alert(err.reason);
      }
    },
    async cancelBooking(contractAddress) {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();

        const contract = new ethers.Contract(
          contractAddress,
          BookingContractArtifact.abi,
          signer
        );

        const tx = await contract.cancelBooking();
        await tx.wait();

        alert("Booking canceled successfully.");
        await this.loadUserBookings();
      } catch (err) {
        console.error(err);
        alert(err.reason);
      }
    },
    async loadUserBookings() {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      await window.ethereum.request({ method: "eth_requestAccounts" });
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const userAddress = (await signer.getAddress()).toLowerCase();

      const storedContracts = localStorage.getItem("contracts");
      const parsed = storedContracts ? JSON.parse(storedContracts) : [];

      const filteredContracts = [];

      for (const c of parsed) {
        const contractData = typeof c === "string" ? JSON.parse(c) : c;

        try {
          const contract = new ethers.Contract(
            contractData.address,
            BookingContractArtifact.abi,
            provider
          );

          const details = await contract.getBookingDetails();
          const guest = details[0];
          const remainingAmount = details[6];
          const isFullyPaid = details[4];
          const bookingStart = parseInt(details[1]);
          const bookingEnd = parseInt(details[2]);

          if (guest.toLowerCase() === userAddress) {
            contractData.remainingAmount = remainingAmount;
            contractData.isFullyPaid = isFullyPaid;
            contractData.bookingStart = bookingStart;
            contractData.bookingEnd = bookingEnd;
            filteredContracts.push(contractData);
          }
        } catch (err) {
          console.warn("Failed to load contract:", contractData.address, err);
        }
      }

      this.userBookings = filteredContracts;
    },
    async loadAllContracts() {
      const storedContracts = localStorage.getItem("contracts");
      this.contracts = storedContracts ? JSON.parse(storedContracts) : [];
    },
    async payRemaining(contractAddress) {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();

        const contract = new ethers.Contract(
          contractAddress,
          BookingContractArtifact.abi,
          signer
        );

        const details = await contract.getBookingDetails();
        const remainingAmount = details[6];

        const tx = await contract.payRemaining({ value: remainingAmount });
        await tx.wait();

        alert("Remaining amount paid successfully!");
        await this.loadUserBookings();
      } catch (err) {
        console.error(err);
        alert(err.reason);
      }
    },
    formatDate(unixTimestamp) {
      if (!unixTimestamp || unixTimestamp === 0) return "-";
      const date = new Date(unixTimestamp * 1000);
      return date.toLocaleDateString();
    },
  },
};
</script>
