// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Version one data structure for name migration
contract PomName {
    mapping(address => uint256[]) public theNames;
    mapping(uint256 => uint256) public theNameExpiry;
}

// .meme
contract dotMeme {
    address public owner = 0x3C6B0615d70Fc018d91d76d93a1e5e311C9fc52b;

    mapping(uint256 => uint256) public nameExpiry;
    mapping(uint256 => bool) public migrationComplete;
    mapping(uint256 => address) nameHolder;
    mapping(address => uint256) primaryName;
    mapping(uint256 => uint256) registryFees;
    mapping(uint256 => uint256) extensionFees;
    mapping(uint256 => bool) isNameForSale;
    mapping(uint256 => uint256) salePrice;

    PomName pomNameV1;

    bool public registrationActive;
    bool public migrationActive;
    uint256 migrateTempName;

    constructor() {
        for (uint k = 1; k <= 20; k++) {
            registryFees[k] = 1000000000000000000000000000; // Set initial mint fee for 1-20 characters
            extensionFees[k] = 1000000000000000000000000000; // Set initial renewal fee for 1-20 characters
        }
        registrationActive = false;
        migrationActive = true;
        pomNameV1 = PomName(0x6FE0234B5Cae49B27D960f358F0825CA1D6CeC26);
        owner = msg.sender;
    }

    function registerName(uint256 newName) public payable {
        require(
            registrationActive == true,
            ".meme registration is not currently live."
        );

        uint256 fee;

        checkNameFormat(newName);

        // Check name expiry
        require(isNameExpired(newName) == true, "That name is not expired.");

        (, uint256 letterCount) = countLetters(newName);

        // Different fees based on number of characters
        // Fees can be changed by contract owner
        if (letterCount <= 20 && letterCount > 0) {
            fee = registryFees[letterCount];

            require(
                msg.value == fee,
                "Incorrect amount of POM sent to buy name."
            );

            // Reset the primary name status of the name being registerd
            if (primaryName[nameHolder[newName]] == newName) {
                primaryName[nameHolder[newName]] = 0;
            }
            // Map the wallet to the name
            nameHolder[newName] = msg.sender;

            // Set expiry time for the name
            nameExpiry[newName] = block.timestamp + 126144000; // 4 years

            // Unlist name (it might have expired while being listed)
            isNameForSale[newName] = false;

            // Set sale price to 0 (it might have expired while being listed)
            salePrice[newName] = 0;
        }
    }

    function extendNameExpiry(uint256 nameToExtend) public payable {
        uint256 extendFee;

        checkNameFormat(nameToExtend);
        // Check if name is expired
        require(
            isNameExpired(nameToExtend) == false,
            "Can't extend an expired name."
        );

        (, uint256 extendLetters) = countLetters(nameToExtend);
        // You don't have to be the holder to extend a name
        if (extendLetters <= 20 && extendLetters > 0) {
            extendFee = extensionFees[extendLetters];
            require(
                msg.value == extendFee,
                "Incorrect amount of POM sent to extend name expiry."
            );
            nameExpiry[nameToExtend] += 126144000; // 4 years
        }
    }

    function transferName(uint256 nameToTransfer, address newAddress) public {
        // Check to ensure you hold the name you are trying to transfer.
        require(
            msg.sender == nameHolder[nameToTransfer],
            "You can't transfer this name."
        );
        // Reset the primary name of the outbound wallet if their primary name is being transferred
        if (primaryName[msg.sender] == nameToTransfer) {
            primaryName[msg.sender] = 0;
        }

        // Unlist name
        isNameForSale[nameToTransfer] = false;

        // Map the new wallet to the name
        nameHolder[nameToTransfer] = newAddress;

        // Set sale price to 0
        salePrice[nameToTransfer] = 0;
    }

    // Set the registration & extension fee per character
    function setFees(
        uint characters,
        uint256 newRegistrationFee,
        uint256 newExtensionFee
    ) public {
        require(
            msg.sender == owner,
            "Only contract owner can change .meme fees."
        );
        require(
            characters >= 1 && characters <= 20,
            "Invalid character count."
        );
        registryFees[characters] = newRegistrationFee;
        extensionFees[characters] = newExtensionFee;
    }

    // List and set price in one function
    function listName(
        uint256 nameToList,
        bool listForSale,
        uint256 listPrice
    ) public {
        checkNameFormat(nameToList);
        // Check to ensure the name isn't expired
        require(
            isNameExpired(nameToList) == false,
            "That name is expired. It can't be listed."
        );
        require(
            nameHolder[nameToList] == msg.sender,
            "Only name owner can list name."
        );
        isNameForSale[nameToList] = listForSale;
        salePrice[nameToList] = listPrice;
    }

    function buyName(uint256 nameToBuy) public payable {
        checkNameFormat(nameToBuy);
        require(
            isNameExpired(nameToBuy) == false,
            "That name is expired. Register it instead."
        );
        require(isNameForSale[nameToBuy] == true, "That name is not for sale.");
        require(
            msg.value == salePrice[nameToBuy],
            "POM sent must be equal to the sale price."
        );
        address payable pomReceiver = payable(nameHolder[nameToBuy]);
        uint256 transactionPrice = salePrice[nameToBuy];
        isNameForSale[nameToBuy] = false;
        salePrice[nameToBuy] = 0;
        if (primaryName[pomReceiver] == nameToBuy) {
            primaryName[pomReceiver] = 0;
        }
        nameHolder[nameToBuy] = msg.sender;
        (bool sent, ) = pomReceiver.call{value: transactionPrice}("");
        require(sent, "Failed to send POM.");
    }

    function countLetters(
        uint256 codedNameToCount
    ) public pure returns (uint256, uint256) {
        uint256 codedNameToCountCopy = codedNameToCount; // Copy of name used to count digits.
        uint256 letterCount;
        uint256 digitCount = 0;
        while (codedNameToCountCopy != 0) {
            codedNameToCountCopy /= 10;
            digitCount++; // Counts the digits in the number.
        }
        require(
            digitCount >= 4 && digitCount <= 61,
            "That is an invalid name length."
        );
        require(
            codedNameToCount / (10 ** (digitCount - 1)) == 1,
            "The first digit of a .meme code must be 1."
        );
        uint extra = (digitCount - 1) % 3 == 0 ? 0 : 1;
        letterCount = (digitCount - 1) / 3;
        letterCount += extra;
        return (digitCount, letterCount);
    }

    function isNameExpired(uint256 nameToCheck) public view returns (bool) {
        bool isExpired = nameExpiry[nameToCheck] < block.timestamp;
        return isExpired;
    }

    function setPrimaryName(uint256 nameToSet) public {
        if (nameToSet == 0) {
            primaryName[msg.sender] = 0;
        } else {
            checkNameFormat(nameToSet);
            require(
                nameHolder[nameToSet] == msg.sender,
                "You don't own that name."
            );
            require(isNameExpired(nameToSet) == false, "That name is expired.");
            primaryName[msg.sender] = nameToSet;
        }
    }

    function readName(address userAddress) public view returns (uint256) {
        require(
            primaryName[userAddress] != 0,
            "No primary name assigned to that address."
        );
        require(
            isNameExpired(primaryName[userAddress]) == false,
            "The primary name associated with that address is expired."
        );
        return primaryName[userAddress];
    }

    function holderOf(uint256 thisName) public view returns (address) {
        checkNameFormat(thisName);
        require(
            isNameExpired(thisName) == false,
            "That name is currently expired."
        );
        return nameHolder[thisName];
    }

    function forSale(uint256 checkName) public view returns (bool) {
        bool forSaleBool;
        checkNameFormat(checkName);
        if (isNameExpired(checkName) == true) {
            forSaleBool = false;
        } else {
            forSaleBool = isNameForSale[checkName];
        }
        return forSaleBool;
    }

    function getPrice(uint256 checkPrice) public view returns (uint256) {
        checkNameFormat(checkPrice);
        require(
            isNameExpired(checkPrice) == false,
            "Name is expired, it can be registered."
        );
        require(
            isNameForSale[checkPrice] == true,
            "Name is not listed for sale."
        );
        return salePrice[checkPrice];
    }

    function registrationFee(
        uint256 numberOfCharacters
    ) public view returns (uint256) {
        require(
            numberOfCharacters >= 1 && numberOfCharacters <= 20,
            "Invalid character count."
        );
        return registryFees[numberOfCharacters];
    }

    function extensionFee(
        uint256 numberOfCharacters
    ) public view returns (uint256) {
        require(
            numberOfCharacters >= 1 && numberOfCharacters <= 20,
            "Invalid character count."
        );
        return extensionFees[numberOfCharacters];
    }

    function checkNameFormat(uint256 codedName) private view {
        bool badCharPresent = false;
        uint256 charBeingChecked;
        (uint256 digitCountB, ) = countLetters(codedName);

        uint jump; //@audit how many digits to go to left?
        for (uint i = 0; i < (digitCountB - 1); i += jump) {
            jump = 3; //@audit consider 3 at start of the loop
            // Cycle through the 3 digit unicode values
            charBeingChecked =
                ((codedName / 10 ** i)) -
                ((codedName / 10 ** (i + jump)) * (10 ** jump)); //@audit extract the 3 digits character

            //@audit this means our letter has 2 decimals digits
            if (charBeingChecked > 122) {
                jump = 2; //@audit do not skip 3 digits, skip 2, since our character has 2 digits
                charBeingChecked %= 100; // extract 2 right digits
            }

            //@audit Edge case => 11091 or 10096, where the 3 digits ascii code has 2 zeroes which results to 11091 => 11 91 and 10096 => 10 96
            if (charBeingChecked < 100 && jump == 3) {
                jump = 2;
            }

            // Check that only allowed characters can be registered
            // Allowed: a-z (lowercase only) + a few common symbols
            // Ensure the user doesn't register three zeros in a row which could result in duplicate names
            // The objective is only 1 token id per name possible

            if (charBeingChecked >= 97 && charBeingChecked <= 122) {
                // Nothing is supposed to happen if it is a suitable character
            } else if (
                charBeingChecked >= 48 && charBeingChecked <= 57
            ) {} else if (
                charBeingChecked >= 35 && charBeingChecked <= 36
            ) {} else if (
                charBeingChecked >= 45 && charBeingChecked <= 46
            ) {} else if (
                charBeingChecked >= 63 && charBeingChecked <= 64
            ) {} else if (charBeingChecked == 61) {} else if (
                charBeingChecked == 95
            ) {} else {
                // Any other character is not suitable
                badCharPresent = true;
            }
        }
        require(badCharPresent == false, "That name has an invalid character.");
    }

    function changeOwner(address newOwner) public {
        require(
            msg.sender == owner,
            "Only owner can change contract ownership."
        );
        owner = newOwner;
    }

    function activateNameRegistration(bool activeNow) public {
        require(msg.sender == owner, "Only owner can activate registration.");
        registrationActive = activeNow;
    }

    function activateMigration(bool migrateNow) public {
        require(msg.sender == owner, "Only owner can change migration status.");
        require(migrationActive == true, "Migration is permanently inactive.");
        migrationActive = migrateNow;
    }

    function adminRegister(
        address newHolder,
        uint256 nameToRegister,
        string calldata registerReason
    ) public {
        require(msg.sender == owner, "Only owner can use this function.");

        checkNameFormat(nameToRegister);

        // Is the name expired
        require(
            isNameExpired(nameToRegister) == true,
            "That name is not expired."
        );

        (, uint256 letterCountAdmin) = countLetters(nameToRegister);

        // Different fees based on number of characters
        // Fees can be changed by public functions (see below)
        if (letterCountAdmin <= 20 && letterCountAdmin > 0) {
            // Reset the primary name status of the name being registerd
            if (primaryName[nameHolder[nameToRegister]] == nameToRegister) {
                primaryName[nameHolder[nameToRegister]] = 0;
            }
            // Map the wallet to the name
            nameHolder[nameToRegister] = newHolder;

            // Set expiry time for the name
            nameExpiry[nameToRegister] = block.timestamp + 126144000; // 4 years

            // Unlist name (it might have expired while being listed)
            isNameForSale[nameToRegister] = false;

            // Set sale price to 0 (it might have expired while being listed)
            salePrice[nameToRegister] = 0;
        }
    }

    function migrateV1Wallet(
        address v1Wallet,
        uint walletLowIndex,
        uint walletHighIndex
    ) public {
        require(
            migrationActive == true,
            ".meme contract migration is not currently active."
        );
        uint j;
        for (j = walletLowIndex; j < walletHighIndex; j++) {
            migrateTempName = pomNameV1.theNames(v1Wallet, j); // Gets the correct name from V1 contract
            if (migrationComplete[migrateTempName] == false) {
                // Ensures each name only migrates once
                nameHolder[migrateTempName] = v1Wallet; // Assigns V1 wallet to migrated name
                nameExpiry[migrateTempName] = pomNameV1.theNameExpiry(
                    migrateTempName
                ); // Migrate expiry time
                migrationComplete[migrateTempName] = true;
            }
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
