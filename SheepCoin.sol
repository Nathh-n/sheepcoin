// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract SheepCoin is ERC20 {
    // Data untuk Auto Mining
    mapping(address => uint256) public miningDeadline; 
    mapping(address => uint256) public lastClaimTime;
    
    constructor() ERC20("SheepCoin", "SHP") {
        // Mint 1 Juta Koin ke pembuat kontrak (Anda) saat deploy
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    // 1. MANUAL MINING (Gacha)
    function mineReward() external {
        // Random sederhana menggunakan hash block
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        uint256 randomInRange = (random % 41) + 50; // Angka 50 - 90
        
        // Hasil 0.5 - 0.9 SHP
        uint256 finalReward = randomInRange * (10 ** decimals()) / 100;
        _mint(msg.sender, finalReward);
    }

    // 2. BELI PAKET AUTO MINING (Bayar Pakai SHP)
    // Perhatikan: Tidak ada kata 'payable' karena kita tidak butuh ETH
    function buyPackage(uint256 packageId) external {
        uint256 priceSHP;
        uint256 duration;

        // DAFTAR HARGA (Dalam Satuan SHP)
        if (packageId == 0) { 
            priceSHP = 10 * 10**decimals();   // 10 SHP
            duration = 15 minutes; 
        } else if (packageId == 1) { 
            priceSHP = 20 * 10**decimals();   // 20 SHP
            duration = 30 minutes; 
        } else if (packageId == 2) { 
            priceSHP = 50 * 10**decimals();   // 50 SHP
            duration = 1 hours; 
        } else if (packageId == 3) { 
            priceSHP = 100 * 10**decimals();  // 100 SHP
            duration = 2 hours; 
        } else if (packageId == 4) { 
            priceSHP = 250 * 10**decimals();  // 250 SHP
            duration = 5 hours; 
        } else if (packageId == 5) { 
            priceSHP = 600 * 10**decimals();  // 600 SHP
            duration = 12 hours; 
        } else { 
            revert("Paket tidak valid!"); 
        }

        // Cek apakah User punya cukup SHP
        require(balanceOf(msg.sender) >= priceSHP, "Saldo SHP Anda tidak cukup! Mining dulu.");

        // PROSES PEMBAYARAN: Bakar Koin User
        _burn(msg.sender, priceSHP);

        // AKTIFKAN / PERPANJANG MINING
        if (miningDeadline[msg.sender] < block.timestamp) {
            // Jika baru beli / sudah mati
            miningDeadline[msg.sender] = block.timestamp + duration;
            lastClaimTime[msg.sender] = block.timestamp;
        } else {
            // Jika nambah durasi
            miningDeadline[msg.sender] += duration;
        }
    }

    // 3. STOP MINING (Berhenti Paksa)
    function stopMining() external {
        require(miningDeadline[msg.sender] > block.timestamp, "Mesin sudah mati.");
        
        // Cairkan dulu gaji yang belum diambil
        _distributeReward(block.timestamp);
        
        // Matikan mesin (Set deadline ke sekarang)
        miningDeadline[msg.sender] = block.timestamp;
    }

    // 4. KLAIM GAJI AUTO MINING
    function claimAutoReward() external {
        require(miningDeadline[msg.sender] > 0, "Belum pernah sewa!");
        
        uint256 batasWaktu = block.timestamp;
        if (batasWaktu > miningDeadline[msg.sender]) {
            batasWaktu = miningDeadline[msg.sender];
        }

        _distributeReward(batasWaktu);
    }

    // FUNGSI INTERNAL (Logic Pembagian Gaji)
    function _distributeReward(uint256 batasWaktu) internal {
        uint256 waktuTerakhir = lastClaimTime[msg.sender];
        
        if (batasWaktu > waktuTerakhir) {
            uint256 durasi = batasWaktu - waktuTerakhir;
            
            // GACHA PERFORMA MESIN (Multiplier 1x sampai 5x)
            // Ini membuat hasil mining bervariasi (0.01 - 0.05 SHP per detik)
            uint256 randomPerformance = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 5) + 1;
            uint256 ratePerDetik = randomPerformance * (10**16); 
            
            uint256 gaji = durasi * ratePerDetik;

            lastClaimTime[msg.sender] = batasWaktu;
            _mint(msg.sender, gaji);
        }
    }
}
