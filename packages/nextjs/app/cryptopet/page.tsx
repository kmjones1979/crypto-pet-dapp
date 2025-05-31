import type { NextPage } from "next";
import { CryptoPet } from "~~/components/CryptoPet";

const CryptoPetPage: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div className="px-5">
        <h1 className="text-center">
          <span className="block text-4xl font-bold">CryptoPet dApp</span>
          <span className="block text-2xl mb-2">Your Digital Pet on the Blockchain</span>
        </h1>
        <p className="text-center text-lg opacity-80">Built with Vyper for maximum security and auditability</p>
      </div>

      <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
        <CryptoPet />
      </div>
    </div>
  );
};

export default CryptoPetPage;
