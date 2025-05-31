import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

const deployCryptoPet: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  console.log("🐾 Deploying CryptoPet contract...");

  await deploy("CryptoPet", {
    from: deployer,
    args: [], // No constructor arguments
    log: true,
    autoMine: true,
  });

  const cryptoPet = await hre.ethers.getContract<Contract>("CryptoPet", deployer);
  console.log("✅ CryptoPet deployed at:", await cryptoPet.getAddress());

  // Add initial reward funds
  const fundTx = await cryptoPet.deposit_reward_funds({
    value: hre.ethers.parseEther("0.1"),
  });
  await fundTx.wait();
  console.log("💰 Added 0.1 ETH for rewards");
};

export default deployCryptoPet;
deployCryptoPet.tags = ["CryptoPet"];
