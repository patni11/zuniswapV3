export default function SwapModule() {
  return (
    <div className="p-12 rounded-lg flex flex-col space-y-4 items-center bg-blue-800 h-auto">
      <div className="flex justify-between mb-6 items-center w-full">
        <h2 className="font-bold justify-self-start"> Swap </h2>
        <button className="bg-lime-700 rounded-lg px-2 py-2 font-bold justify-self-end">
          Add Liq
        </button>
      </div>

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
