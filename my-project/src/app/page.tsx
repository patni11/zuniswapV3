import SwapModule from "./components/SwapModule";
import { ConnectButton } from "@rainbow-me/rainbowkit";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center p-24">
      <div className="flex h-fit">
        <h1 className="mb-10 text-xl font-bold"> ZuniSwap V3</h1>
        <ConnectButton></ConnectButton>
      </div>

      <SwapModule></SwapModule>
    </main>
  );
}
