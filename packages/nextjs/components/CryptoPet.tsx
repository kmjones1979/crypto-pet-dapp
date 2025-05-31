"use client";

import { useState } from "react";
import { formatEther, parseEther } from "viem";
import { useAccount } from "wagmi";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

export const CryptoPet = () => {
  const { address } = useAccount();
  const [petName, setPetName] = useState("");

  // Read if user has a pet
  const { data: hasPet } = useScaffoldReadContract({
    contractName: "CryptoPet",
    functionName: "check_has_pet",
    args: [address],
  });

  // Get pet info if user has one
  const { data: petInfo } = useScaffoldReadContract({
    contractName: "CryptoPet",
    functionName: "get_pet_info",
    args: [address],
  });

  // Get current pet status
  const { data: currentStatus } = useScaffoldReadContract({
    contractName: "CryptoPet",
    functionName: "get_current_pet_status",
    args: [address],
  });

  // Write functions
  const { writeContractAsync: writeContract } = useScaffoldWriteContract({
    contractName: "CryptoPet",
  });

  const handleAdoptPet = async () => {
    if (!petName.trim()) {
      notification.error("Please enter a pet name!");
      return;
    }

    try {
      await writeContract({
        functionName: "adopt_pet",
        args: [petName],
        value: parseEther("0.01"),
      });
      notification.success("🐾 Pet adopted successfully!");
      setPetName("");
    } catch (error) {
      notification.error("Failed to adopt pet");
    }
  };

  const handleFeedPet = async () => {
    try {
      await writeContract({
        functionName: "feed_pet",
      });
      notification.success("🍖 Pet fed successfully!");
    } catch (error) {
      notification.error("Failed to feed pet - check cooldown");
    }
  };

  const handlePlayWithPet = async () => {
    try {
      await writeContract({
        functionName: "play_with_pet",
      });
      notification.success("🎾 Played with pet successfully!");
    } catch (error) {
      notification.error("Failed to play - check cooldown");
    }
  };

  const getMoodEmoji = (mood: string) => {
    switch (mood) {
      case "Excellent":
        return "😍";
      case "Happy":
        return "😊";
      case "Okay":
        return "😐";
      case "Sad":
        return "😢";
      default:
        return "😊";
    }
  };

  if (!address) {
    return (
      <div className="text-center p-8">
        <h2 className="text-2xl mb-4">🐾 CryptoPet dApp</h2>
        <p>Please connect your wallet to adopt and care for your digital pet!</p>
      </div>
    );
  }

  if (!hasPet) {
    return (
      <div className="max-w-md mx-auto bg-base-100 shadow-xl rounded-box p-6">
        <h2 className="text-2xl font-bold text-center mb-6">Adopt a CryptoPet! 🐾</h2>
        <div className="form-control">
          <label className="label">
            <span className="label-text">Pet Name</span>
          </label>
          <input
            type="text"
            placeholder="Enter your pet's name"
            className="input input-bordered"
            value={petName}
            onChange={e => setPetName(e.target.value)}
            maxLength={50}
          />
        </div>
        <div className="mt-6 text-center">
          <p className="text-sm opacity-70 mb-4">Adoption Fee: 0.01 ETH</p>
          <button className="btn btn-primary btn-wide" onClick={handleAdoptPet}>
            Adopt Pet
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto bg-base-100 shadow-xl rounded-box p-6">
      <h2 className="text-3xl font-bold text-center mb-6">
        {petInfo?.name} {getMoodEmoji(currentStatus?.[2] || "Happy")}
      </h2>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Pet Stats */}
        <div>
          <h3 className="text-xl font-semibold mb-4">Stats</h3>
          <div className="space-y-3">
            <div>
              <label className="text-sm font-medium">Happiness</label>
              <progress
                className="progress progress-success w-full"
                value={currentStatus?.[0] ? Number(currentStatus[0]) : 0}
                max="100"
              ></progress>
              <span className="text-sm">{currentStatus?.[0]?.toString() || 0}/100</span>
            </div>
            <div>
              <label className="text-sm font-medium">Energy</label>
              <progress
                className="progress progress-info w-full"
                value={currentStatus?.[1] ? Number(currentStatus[1]) : 0}
                max="100"
              ></progress>
              <span className="text-sm">{currentStatus?.[1]?.toString() || 0}/100</span>
            </div>
            <div>
              <label className="text-sm font-medium">Mood</label>
              <p className="text-lg">
                {currentStatus?.[2]} {getMoodEmoji(currentStatus?.[2] || "Happy")}
              </p>
            </div>
            <div>
              <label className="text-sm font-medium">Total Rewards</label>
              <p>{formatEther(petInfo?.total_rewards || 0n)} ETH</p>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div>
          <h3 className="text-xl font-semibold mb-4">Actions</h3>
          <div className="space-y-3">
            <button className="btn btn-success w-full" onClick={handleFeedPet}>
              🍖 Feed Pet
            </button>
            <button className="btn btn-info w-full" onClick={handlePlayWithPet}>
              🎾 Play with Pet
            </button>
            <div className="text-xs opacity-70 mt-2">
              Note: Feeding has 1-hour cooldown, playing has 30-minute cooldown
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
