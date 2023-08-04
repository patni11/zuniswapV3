import { Signer } from "ethers";
import { ethers } from "ethers";

interface LiquidityProps {
  token0Addr: string;
  ERC20ABI: any; // You should use the correct type for your ERC20 ABI, this is just a placeholder.
  signer: Signer; // Assuming 'signer' is of type 'Signer' from the ethers library.
}

const addLiquidity = (
  account,
  { token0, token1, manager },
  { managerAddress, poolAddress }
) => {
  const amount0 = ethers.utils.parseEther("");
  const amount1 = ethers.utils.parseEther("");
};

export default function Liquidity({
  token0Addr,
  ERC20ABI,
  signer,
}: LiquidityProps) {
  const token0 = new ethers.Contract(token0Addr, ERC20ABI, signer);

  return (
    <div className="p-12 rounded-lg flex flex-col space-y-4 items-center bg-blue-800 h-auto">
      <form className="flex flex-col space-y-4 text-purple">
        <div className="flex space-x-2">
          <input
            type="number"
            placeholder="Token 1 Amount"
            className="rounded-md px-4 py-2 text-black"
          />
          <select
            name="cars"
            id="cars"
            className="rounded-lg text-gray-700 font-medium p-2"
          >
            <option value="USDT">USDT</option>
            <option value="ETH">ETH</option>
          </select>
        </div>
        <div className="flex space-x-2">
          <input
            type="number"
            placeholder="Token 1 Amount"
            className="rounded-md px-4 py-2 text-black"
          />
          <select
            name="cars"
            id="cars"
            className="rounded-lg text-gray-700 font-medium p-2"
          >
            <option value="USDT">USDT</option>
            <option value="ETH">ETH</option>
          </select>
        </div>
        <button
          type="submit"
          className="bg-red-400 rounded-lg px-4 py-2 font-bold"
        >
          {" "}
          Swap{" "}
        </button>
      </form>
    </div>
  );
}
