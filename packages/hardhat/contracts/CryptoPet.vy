# @version ^0.4.0

"""
@title CryptoPet - Digital Pet Smart Contract
@notice A fun digital pet game built with Vyper
@dev Demonstrates Vyper's security-first approach
@author Tutorial Implementation
"""

# Constants - values that never change
ADOPTION_FEE: constant(uint256) = 10**16  # 0.01 ETH
MAX_HAPPINESS: constant(uint256) = 100
MAX_ENERGY: constant(uint256) = 100
REWARD_THRESHOLD: constant(uint256) = 80

# Events - to log important activities
event PetAdopted:
    owner: indexed(address)
    pet_name: String[50]
    timestamp: uint256

event PetFed:
    owner: indexed(address)
    happiness_increase: uint256
    new_happiness: uint256

event PetPlayed:
    owner: indexed(address)
    energy_increase: uint256
    new_energy: uint256

event RewardEarned:
    owner: indexed(address)
    reward_amount: uint256

# Struct to represent a pet's data
struct Pet:
    name: String[50]
    happiness: uint256
    energy: uint256
    last_fed: uint256
    last_played: uint256
    total_rewards: uint256

# State variables
pets: public(HashMap[address, Pet])
has_pet: public(HashMap[address, bool])
total_pets: public(uint256)
contract_owner: public(immutable(address))

@deploy
def __init__():
    """
    @notice Constructor - initializes the contract
    """
    contract_owner = msg.sender
    self.total_pets = 0

@external
@view
def check_has_pet(owner: address) -> bool:
    """
    @notice Check if an address has a pet
    @param owner The address to check
    @return True if the address has a pet, False otherwise
    """
    return self.has_pet[owner]

@external
@view
def get_pet_info(owner: address) -> Pet:
    """
    @notice Get detailed pet information
    @param owner The address of the pet owner
    @return Pet struct containing all pet data
    """
    assert self.has_pet[owner], "This address doesn't have a pet"
    return self.pets[owner]

@internal
@view
def _calculate_happiness_decay(last_fed: uint256) -> uint256:
    """
    @notice Calculate happiness decay over time
    @param last_fed Timestamp of when pet was last fed
    @return Amount of happiness decay
    """
    time_since_fed: uint256 = block.timestamp - last_fed
    # Happiness decreases by 1 every hour (3600 seconds)
    decay: uint256 = time_since_fed // 3600
    return decay

@internal
@view
def _calculate_energy_decay(last_played: uint256) -> uint256:
    """
    @notice Calculate energy decay over time
    @param last_played Timestamp of when pet was last played with
    @return Amount of energy decay
    """
    time_since_played: uint256 = block.timestamp - last_played
    # Energy decreases by 1 every 2 hours (7200 seconds)
    decay: uint256 = time_since_played // 7200
    return decay

@external
@payable
def adopt_pet(pet_name: String[50]):
    """
    @notice Adopt a new pet by paying the adoption fee
    @param pet_name Name for the new pet
    """
    # Error handling - check conditions
    assert not self.has_pet[msg.sender], "You already have a pet!"
    assert msg.value >= ADOPTION_FEE, "Insufficient payment for adoption"
    assert len(pet_name) > 0, "Pet name cannot be empty"
    assert len(pet_name) <= 50, "Pet name too long"
    
    # Create new pet with initial stats
    new_pet: Pet = Pet(
        name=pet_name,
        happiness=50,  # Start with medium happiness
        energy=50,     # Start with medium energy
        last_fed=block.timestamp,
        last_played=block.timestamp,
        total_rewards=0
    )
    
    # Update contract state
    self.pets[msg.sender] = new_pet
    self.has_pet[msg.sender] = True
    self.total_pets += 1
    
    # Emit event
    log PetAdopted(msg.sender, pet_name, block.timestamp)
    
    # Refund excess payment
    if msg.value > ADOPTION_FEE:
        excess: uint256 = msg.value - ADOPTION_FEE
        send(msg.sender, excess)

@external
def feed_pet():
    """
    @notice Feed your pet to increase happiness
    """
    # Check if user has a pet
    assert self.has_pet[msg.sender], "You don't have a pet to feed"
    
    # Get current pet data
    pet: Pet = self.pets[msg.sender]
    
    # Check if enough time has passed since last feeding (1 hour minimum)
    assert block.timestamp >= pet.last_fed + 3600, "You can only feed your pet once per hour"
    
    # Calculate current happiness after decay
    happiness_decay: uint256 = self._calculate_happiness_decay(pet.last_fed)
    current_happiness: uint256 = 0
    if pet.happiness > happiness_decay:
        current_happiness = pet.happiness - happiness_decay
    
    # Calculate happiness increase (random-ish based on block data)
    happiness_increase: uint256 = (block.timestamp % 20) + 10  # 10-29 points
    new_happiness: uint256 = current_happiness + happiness_increase
    
    # Cap at maximum
    if new_happiness > MAX_HAPPINESS:
        new_happiness = MAX_HAPPINESS
    
    # Update pet data
    pet.happiness = new_happiness
    pet.last_fed = block.timestamp
    self.pets[msg.sender] = pet
    
    # Emit event
    log PetFed(msg.sender, happiness_increase, new_happiness)
    
    # Check for reward
    self._check_and_reward(msg.sender)

@external
def play_with_pet():
    """
    @notice Play with your pet to increase energy
    """
    assert self.has_pet[msg.sender], "You don't have a pet to play with"
    
    pet: Pet = self.pets[msg.sender]
    
    # Check cooldown (30 minutes for playing)
    assert block.timestamp >= pet.last_played + 1800, "You can only play with your pet every 30 minutes"
    
    # Calculate current energy after decay
    energy_decay: uint256 = self._calculate_energy_decay(pet.last_played)
    current_energy: uint256 = 0
    if pet.energy > energy_decay:
        current_energy = pet.energy - energy_decay
    
    # Energy increase from playing
    energy_increase: uint256 = (block.timestamp % 15) + 15  # 15-29 points
    new_energy: uint256 = current_energy + energy_increase
    
    if new_energy > MAX_ENERGY:
        new_energy = MAX_ENERGY
    
    # Update pet
    pet.energy = new_energy
    pet.last_played = block.timestamp
    self.pets[msg.sender] = pet
    
    log PetPlayed(msg.sender, energy_increase, new_energy)
    
    # Check for reward
    self._check_and_reward(msg.sender)

@internal
def _check_and_reward(owner: address):
    """
    @notice Internal function to check if user deserves a reward
    @param owner Address of the pet owner
    """
    pet: Pet = self.pets[owner]
    
    # Reward if both happiness and energy are above threshold
    if pet.happiness >= REWARD_THRESHOLD and pet.energy >= REWARD_THRESHOLD:
        # Calculate reward (small amount)
        reward: uint256 = 10**15  # 0.001 ETH
        
        # Check if contract has enough balance
        if self.balance >= reward:
            # Update total rewards
            pet.total_rewards += reward
            self.pets[owner] = pet
            
            # Send reward
            send(owner, reward)
            
            log RewardEarned(owner, reward)

@external
@view
def get_current_pet_status(owner: address) -> (uint256, uint256, String[20]):
    """
    @notice Get current pet status with decay calculations
    @param owner Address of the pet owner
    @return Current happiness, energy, and mood
    """
    assert self.has_pet[owner], "Address doesn't have a pet"
    
    pet: Pet = self.pets[owner]
    
    # Calculate current stats with decay
    happiness_decay: uint256 = self._calculate_happiness_decay(pet.last_fed)
    energy_decay: uint256 = self._calculate_energy_decay(pet.last_played)
    
    current_happiness: uint256 = 0
    current_energy: uint256 = 0
    
    if pet.happiness > happiness_decay:
        current_happiness = pet.happiness - happiness_decay
    
    if pet.energy > energy_decay:
        current_energy = pet.energy - energy_decay
    
    # Determine pet mood
    mood: String[20] = "Happy"
    if current_happiness < 30 or current_energy < 30:
        mood = "Sad"
    elif current_happiness < 50 or current_energy < 50:
        mood = "Okay"
    elif current_happiness >= 80 and current_energy >= 80:
        mood = "Excellent"
    
    return (current_happiness, current_energy, mood)

@external
@view
def get_next_interaction_times(owner: address) -> (uint256, uint256):
    """
    @notice Check when user can next interact with their pet
    @param owner Address of the pet owner
    @return Next feed time and next play time
    """
    assert self.has_pet[owner], "Address doesn't have a pet"
    
    pet: Pet = self.pets[owner]
    next_feed_time: uint256 = pet.last_fed + 3600
    next_play_time: uint256 = pet.last_played + 1800
    
    return (next_feed_time, next_play_time)

@external
def withdraw_funds():
    """
    @notice Owner function to withdraw excess funds
    """
    assert msg.sender == contract_owner, "Only owner can withdraw"
    # Keep some balance for rewards
    withdrawal_amount: uint256 = self.balance - 10**17  # Keep 0.1 ETH for rewards
    if withdrawal_amount > 0:
        send(contract_owner, withdrawal_amount)

@external
@payable
def deposit_reward_funds():
    """
    @notice Anyone can add funds for rewards
    """
    assert msg.value > 0, "Must send some ETH"

@external
def emergency_feed(owner: address):
    """
    @notice Emergency function to reset pet stats (owner only)
    @param owner Address of the pet owner to help
    """
    assert msg.sender == contract_owner, "Only owner can emergency feed"
    assert self.has_pet[owner], "Address doesn't have a pet"
    
    pet: Pet = self.pets[owner]
    pet.happiness = MAX_HAPPINESS
    pet.energy = MAX_ENERGY
    pet.last_fed = block.timestamp
    pet.last_played = block.timestamp
    self.pets[owner] = pet

@external
@payable
def __default__():
    """
    @notice Function that allows the contract to receive ETH
    """
    pass 