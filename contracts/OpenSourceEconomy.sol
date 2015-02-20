
/*
 * The ValueDistribution contract models a distribution of integer
 * values as a map of key-value pairs.
 *
 * It allows simple iteration over keys and values by assigning each
 * key a sequential id, and tracks the total sum of values stored.
 *
 * Example:
 *
 *    // Create a new value distribution
 *    accountWeights = new ValueDistribution();
 *
 *    // Set weights for a series of addresses
 *    accountWeights.setValue(addressA, 100);
 *    accountWeights.setValue(addressB, 120);
 *    accountWeights.setValue(addressC, 85);
 *
 *    // Get the number of keys and total distribution weight
 *    var keyCount = accountWeights.keyCount();
 *    var totalWeight = accountWeights.valueTotal();
 *
 *    // Get the first and last key by id
 *    var firstKey = accountWeights.keys(1);
 *    var lastKey  = accountWeights.keys(keyCount);
 *
 *    // Get the first and last value by address
 *    var firstWeight = accountWeights.values(firstKey);
 *    var lastWeight = accountWeights.values(lastKey);
 */
contract ValueDistribution {

  // Constructs a new value distribution instance.
  function ValueDistribution() {}

  // Sets the distribution value for a given key.
  function setValue(hash key, int value) {
    addKey(key);
    var previousValue = values[key];
    var valueDelta = value - previousValue;
    values[key] = value;
    valueTotal += valueDelta;
  }

  // Adds the given key, unless already present.
  function addKey(hash key) private {
    var keyId = keyIds[key];
    if (keyId == 0)
      createKey(key);
  }

  // Creates a new key for this distribution.
  function createKey(hash key) private {
    var nextId = keyCount + 1;
    keyIds[key] = nextId;
    keyCount++;
  }

  uint public keyCount;
  int public valueTotal;
  mapping (hash => uint) public keyIds;
  mapping (uint => hash) public keys;
  mapping (hash => int) public values;
}

/*
 * The DonationService contract allows anyone to donate to multiple
 * recipients at once, by distributing the total value among them
 * in any way the sender chooses.
 *
 * Example:
 *
 *    donationService = new DonationService();
 *    donationService.donate.value(1 ether)(accountWeights);
 */
contract DonationService {

  // Sends a donation to multiple recipients, distributed according
  // to the given donation weights.
  function donate(address donationWeights) {
    var weights = ValueDistribution(donationWeights);
    var keyCount = weights.keyCount();
    var valueTotal = weights.valueTotal();
    if (valueTotal <= 0)
      return;

    for (var i = 1; i < keyCount; i++) {
      var recipient = address(weights.keys(i));
      var weight = weights.values(hash(recipient));
      var value = weight / valueTotal;
      if (value > 0)
        recipient.send(uint160(value));
    }
  }
}

/*
 * The PublicAccount contract allows owners to receive and process funds
 * with standard components in a transparent way.
 *
 * For example, this version automatically transfers 1 percent
 * of any funds received to other accounts of the owner's choice,
 * using a flexible relative distribution of donation weights.
 *
 * Example:
 *
 *    // Create a new public account
 *    publicAccount = new PublicAccount();
 *
 *    // Configure donation distribution, as the account owner
 *    publicAccount.setDonationWeight(addressA, 100);
 *    publicAccount.setDonationWeight(addressB, 25);
 *    publicAccount.setDonationWeight(addressC, 5);
 *
 *    // Send payment, as a third party.
 *    // This triggers an automatic donation!
 *    publicAccount.sendPayment.value(1 ether)();
 */
contract PublicAccount {

  // Constructs a new public account and subcontracts.
  function PublicAccount() {
    accountOwner = msg.sender;
    donationService = new DonationService();
    memberRatings = new ValueDistribution();
    donationWeights = new ValueDistribution();
  }

  // An event triggered on each payment.
  event Payment(address indexed from, uint value);

  // Sends a payment to this public account.
  function sendPayment() {
    Payment(msg.sender, msg.value);
    donationService.donate.value(msg.value / 100)(address(donationWeights));
    accountOwner.send(msg.value);
  }

  // Allows account owner to rate other ecosystem members.
  function rateMember(address member, int rating) {
    memberRatings.setValue(hash256(member), rating);
  }

  // Allows account owner to set relative weights for donations.
  function setDonationWeight(address member, uint weight) {
    donationWeights.setValue(hash256(member), int(weight));
  }

  address accountOwner;
  DonationService donationService;
  ValueDistribution memberRatings;
  ValueDistribution donationWeights;
}

