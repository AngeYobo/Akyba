"use client";

import { useState, useEffect } from "react";
import dynamic from "next/dynamic";
import { Lucid, Blockfrost, fromText, toUnit, MintingPolicy, Data, Constr , mintingPolicyToId} from "@lucid-evolution/lucid";
import { useCardano } from "@cardano-foundation/cardano-connect-with-wallet";
import { NetworkType } from "@cardano-foundation/cardano-connect-with-wallet-core";

const Mint_Akyba = () => {
  const networkEnv = process.env.NEXT_PUBLIC_NETWORK_ENV === "Preprod" ? NetworkType.MAINNET : NetworkType.TESTNET;
  const { isConnected, enabledWallet } = useCardano({ limitNetwork: networkEnv });

  const [lucid, setLucid] = useState<typeof Lucid | null>(null);
  const [walletAddress, setWalletAddress] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const initLucid = async () => {
      try {
        const blockfrostApiKey = process.env.NEXT_PUBLIC_BLOCKFROST_KEY_PREPROD || "";
        const lucidInstance = await Lucid(
          new Blockfrost(`https://cardano-${networkEnv.toLowerCase()}.blockfrost.io/api/v0`, blockfrostApiKey),
          networkEnv === NetworkType.TESTNET ? "Preprod" : "Mainnet"
        );

        if (enabledWallet) {
          const api = await window.cardano[enabledWallet].enable();
          lucidInstance.selectWallet.fromAPI(api);
          const address = await lucidInstance.wallet().address();
          setWalletAddress(address);
       
        }
      } catch (err) {
        console.error("❌ Wallet connection error:", err);
        setError("Failed to connect wallet.");
      }
    };

    initLucid();
  }, [enabledWallet]);

  const handleMint = async () => {
    if (!isConnected || !lucid || !walletAddress) {
      setError("Wallet is not connected.");
      return;
    }

    setLoading(true);
    setError(null);
    setTxHash(null);

    try {
      // Define CIP-68 Metadata
      const tokenName = "Akyba";
      const tokenImage = "ipfs://QmU2hT2bRNZvzV6r3xzULiaiX5S6LPi2yGGvV3sXzgZHZH";
      const metadataMap = new Map([
        [fromText("name"), fromText(tokenName)],
        [fromText("image"), fromText(tokenImage)],
      ]);

      const version = BigInt(1);
      const datum = Data.to(new Constr(0, [metadataMap, version]));
      const redeemer = Data.to(new Constr(0, [])); // Minting Redeemer

      // Define Minting Policy (Replace with real Plutus script)
      const rawMintingScript = "590cd6010100323232323232322322322322322322533300c323232..."; // Shortened
      const mintingPolicy: MintingPolicy = { type: "PlutusV3", script: rawMintingScript };
      const policyID = mintingPolicyToId(mintingPolicy);

      const prefix_100 = "000643b0";
      const usrUnit = toUnit(policyID, prefix_100 + fromText(tokenName));

      const tx = await lucid
        .newTx()
        .mintAssets({ [usrUnit]: 1n }, redeemer)
        .attachMintingPolicy(mintingPolicy)
        .payToAddress(walletAddress, { [usrUnit]: 1n }) // Send NFT to user
        .complete();

      const signedTx = await tx.sign().complete();
      const txHash = await signedTx.submit();
      setTxHash(txHash);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>Mint CIP-68 Token</h2>
      {walletAddress ? (
        <p>Connected Wallet: <strong>{walletAddress}</strong></p>
      ) : (
        <p style={{ color: "red" }}>❌ Wallet Not Connected</p>
      )}

      <button onClick={handleMint} disabled={loading || !walletAddress}>
        {loading ? "Minting..." : "Mint Token"}
      </button>

      {txHash && (
        <p>
          ✅ Transaction Submitted!{" "}
          <a
            href={`https://preprod.cardanoscan.io/transaction/${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
          >
            View on Cardanoscan
          </a>
        </p>
      )}

      {error && <p style={{ color: "red" }}>❌ {error}</p>}
    </div>
  );
};

export default dynamic(() => Promise.resolve(Mint_Akyba), { ssr: false });
