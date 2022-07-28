import { deployContract } from "../utils";
import { Lottery } from "../../../build/typechain";

export const contractNames = () => ["lottery"];

export const constructorArguments = () => [
  process.env.VRFCOORDINATOR, 
  process.env.LINK_ADDRESS,
  process.env.KEY_HASH
];

export const deploy = async (deployer, setAddresses) => {
  console.log("deploying Lottery");
  const lottery: Lottery = (await deployContract(
    "Lottery",
    constructorArguments(),
    deployer,
    1
  )) as Lottery;
  console.log(`deployed Lottery to address ${lottery.address}`);
  setAddresses({ lottery: lottery.address });
  return lottery;
};