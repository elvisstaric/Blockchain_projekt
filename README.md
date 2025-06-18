# Decentralizirani sustav za rezervaciju smještaja

Elvis Starić

Fakultet informatike u Puli https://fipu.unipu.hr/

Kolegij: Blockchain aplikacije - ntankovic.unipu.hr/bc

Mentor: doc. dr. sc. Nikola Tanković (ntankovic.unipu.hr)

Ovaj projekt je **decentralizirana aplikacija** za rezervaciju smještaja, izgrađenu na Ethereum blockchainu. Korisnici mogu rezervirati smještaj plaćanjem depozita, dok vlasnici mogu upravljati ugovorima i povlačiti uplate nakon završetka rezervacije.

## Tehnologije

- **Solidity** – pametni ugovor za upravljanje rezervacijama
- **Vue.js** – frontend aplikacija
- **ethers.js** – komunikacija između frontend aplikacije i blockchaina
- **MetaMask** – autentifikacija i transakcije korisnika

## Struktura projekta

- `contracts/booking.sol` – pametni ugovor za rezervaciju smještaja
- `components/BookingUser.vue` – korisničko sučelje za pregled, rezervaciju i plaćanje
- `components/BookingOwner.vue` – vlasničko sučelje za kreiranje i upravljanje ugovorima

## Funkcionalnosti

### Vlasnik smještaja

- Kreira nove pametne ugovore sa zadanim nazivom i cijenom po noći
- Pregledava rezervacije (gost, datumi, uplate)
- Povlači sredstva nakon što rezervacija završi i bude u potpunosti plaćena

### Gost

- Pregledava dostupne smještaje
- Rezervira termine uz uplatu minimalnog depozita (minimalno 30%)
- Nadoplaćuje ostatak iznosa
- Otkazuje rezervaciju dok nije u potpunosti plaćena

## Upute za korištenje

1. Instaliraj MetaMask i poveži se s Ethereum testnetom (npr. Sepolia)
2. Pokreni lokalni razvojni blockchain (npr. Hardhat ili Ganache)
3. Deploy-aj pametni ugovor (koristi `BookingOwner.vue`)
4. Spremi adresu ugovora u `localStorage` (aplikacija to radi automatski)
5. Rezerviraj i upravljaj smještajem preko korisničkog i vlasničkog sučelja

## Napomena

- Sve rezervacije i transakcije se odvijaju na blockchainu – treba voditi računa o testnim tokenima.
- Minimalni depozit za rezervaciju iznosi **30% ukupne cijene**.
- Isplata vlasniku moguća je tek **nakon završetka rezervacije** i kada je **ukupna cijena plaćena**.
