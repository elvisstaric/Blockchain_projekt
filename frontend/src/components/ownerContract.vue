<template>
  <div>
    <h2>Booking Owner Panel</h2>

    <div style="margin-bottom: 1em">
      <button @click="activeTab = 'create'" :disabled="activeTab === 'create'">
        Create Contract
      </button>
      <button @click="activeTab = 'manage'" :disabled="activeTab === 'manage'">
        Manage Contracts
      </button>
    </div>
    <div v-if="activeTab === 'create'">
      <h3>Create a new booking contract</h3>

      <input
        v-model="accommodationName"
        placeholder="Accommodation name"
        type="text"
      />
      <input
        v-model="pricePerNight"
        placeholder="Price per night (ETH)"
        type="number"
        step="0.0001"
        min="0"
      />

      <button @click="deployContract">Deploy Contract</button>

      <p v-if="contractAddress">
        Contract deployed at: <strong>{{ contractAddress }}</strong>
      </p>
    </div>

    <div v-if="activeTab === 'manage'">
      <h3>Your Contracts & Bookings</h3>

      <div v-if="contracts.length === 0">
        <p>No contracts deployed yet.</p>
      </div>

      <ul v-else>
        <li
          v-for="contract in contracts"
          :key="contract.address"
          style="
            margin-bottom: 1.5em;
            border-bottom: 1px solid #ccc;
            padding-bottom: 1em;
          "
        >
          <strong>{{ contract.accommodationName }}</strong> -
          {{ contract.pricePerNight }} ETH/night<br />

          <button
            @click="loadContractDetails(contract.address)"
            style="margin-top: 0.5em"
          >
            Load Booking Details
          </button>

          <div
            v-if="
              contractDetails && contractDetails.address === contract.address
            "
            style="margin-top: 1em"
          >
            <p><strong>Guest:</strong> {{ contractDetails.guest }}</p>
            <p>
              <strong>Booking Start:</strong>
              {{ formatDate(contractDetails.bookingStart) }}
            </p>
            <p>
              <strong>Booking End:</strong>
              {{ formatDate(contractDetails.bookingEnd) }}
            </p>
            <p>
              <strong>Is Booked:</strong>
              {{ contractDetails.isBooked ? "Yes" : "No" }}
            </p>
            <p>
              <strong>Is Fully Paid:</strong>
              {{ contractDetails.isFullyPaid ? "Yes" : "No" }}
            </p>
            <p>
              <strong>Deposit Paid (ETH):</strong>
              {{ formattedDeposit }}
            </p>
            <p>
              <strong>Remaining Amount (ETH):</strong>
              {{ formattedRemaining }}
            </p>
            <p>
              <strong>Withdrawn:</strong>
              {{ formattedWithdrawn }}
            </p>

            <button
              @click="withdrawPayment(contract.address)"
              :disabled="
                !contractDetails.isBooked ||
                !contractDetails.isFullyPaid ||
                !isPastBooking(contractDetails.bookingEnd) ||
                contractDetails.isWithdrawn
              "
              style="margin-top: 1em"
            >
              Withdraw Full Payment
            </button>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { ethers } from "ethers";
import BookingContractArtifact from "../../../artifacts/contracts/booking.sol/Booking_contract.json";

export default {
  data() {
    return {
      activeTab: "create",
      accommodationName: "",
      pricePerNight: "",
      contractAddress: "",
      contracts: [],
      contractDetails: null,
    };
  },
  async created() {
    await this.loadOwnerContracts();
  },
  computed: {
    formattedDeposit() {
      return this.contractDetails
        ? ethers.formatEther(this.contractDetails.depositAmount)
        : "-";
    },
    formattedRemaining() {
      if (!this.contractDetails) return "-";
      if (this.contractDetails.isFullyPaid) return "0";
      return ethers.formatEther(this.contractDetails.remainingAmount);
    },
    formattedWithdrawn() {
      if (this.contractDetails.isWithdrawn) return "Yes";
      else return "No";
    },
  },
  methods: {
    async deployContract() {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      if (!this.accommodationName || !this.pricePerNight) {
        alert("Enter accommodation name and price per night!");
        return;
      }

      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();

        const factory = new ethers.ContractFactory(
          BookingContractArtifact.abi,
          BookingContractArtifact.bytecode,
          signer
        );

        const priceInWei = ethers.parseEther(this.pricePerNight.toString());

        const contract = await factory.deploy(
          this.accommodationName,
          priceInWei
        );
        await contract.waitForDeployment();

        this.contractAddress = contract.target;

        const storedContracts = localStorage.getItem("contracts");
        const contracts = storedContracts ? JSON.parse(storedContracts) : [];

        contracts.push({
          address: this.contractAddress,
          accommodationName: this.accommodationName,
          pricePerNight: this.pricePerNight,
        });

        localStorage.setItem("contracts", JSON.stringify(contracts));
        this.contracts = contracts;

        alert("Contract deployed successfully!");
      } catch (err) {
        console.error(err);
        alert("Deploy error");
      }
    },

    async loadOwnerContracts() {
      const storedContracts = localStorage.getItem("contracts");
      this.contracts = storedContracts ? JSON.parse(storedContracts) : [];
    },

    async loadContractDetails(address) {
      if (this.contractDetails && this.contractDetails.address === address) {
        this.contractDetails = null;
        return;
      }
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const contract = new ethers.Contract(
          address,
          BookingContractArtifact.abi,
          provider
        );

        const details = await contract.getBookingDetails();

        this.contractDetails = {
          address,
          guest: details[0],
          bookingStart: parseInt(details[1]),
          bookingEnd: parseInt(details[2]),
          isBooked: details[3],
          isFullyPaid: details[4],
          depositAmount: details[5],
          remainingAmount: details[6],
          isWithdrawn: details[7],
        };
      } catch (err) {
        console.error("Failed to load contract details", err);
        alert("Failed to load contract details.");
      }
    },

    formatDate(unixTimestamp) {
      if (!unixTimestamp || unixTimestamp === 0) return "-";
      const date = new Date(unixTimestamp * 1000);
      return date.toLocaleDateString();
    },

    isPastBooking(bookingEndTimestamp) {
      if (!bookingEndTimestamp) return false;
      return Date.now() / 1000 >= bookingEndTimestamp;
    },

    async withdrawPayment(address) {
      if (!window.ethereum) {
        alert("Install MetaMask");
        return;
      }

      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();

        const contract = new ethers.Contract(
          address,
          BookingContractArtifact.abi,
          signer
        );

        const tx = await contract.withdraw();
        await tx.wait();

        alert("Withdrawal successful.");
        this.loadContractDetails(address);
      } catch (err) {
        console.error(err);
        alert("Withdrawal failed.");
      }
    },
  },
};
</script>
