# `IPFS2.ETH`
[![](https://gist.githubusercontent.com/sshmatrix/057d4cd05f99586abf22a3cb14f40ff6/raw/82bf4c4dcd8c25fd20f9f7908b308b5dd502f459/badge.svg)](https://github.com/namesys-eth/ipfs2-eth-resolver/actions/workflows/test.yml)

## [Install Foundry](https://getfoundry.sh/)
`curl -L https://foundry.paradigm.xyz | bash && source ~/.bashrc && foundryup`

## Install dependency
`forge install foundry-rs/forge-std --no-commit --no-git`

## Goerli Testnet
 `forge test --fork-url https://rpc.ankr.com/eth_goerli -vvvv --fork-block-number 8897000`

# Specification 

## IPFS2.ETH : Standalone ENS Resolver as Web3 IPFS Gateway
#### Authors: `sshmatrix`, `0xc0de4c0ffee`
###### tags: `specification` `resolver` `contenthash` `ccip` `ens`

IPFS2.eth ("IPFS-To-ETH") is a proof-of-concept IPFS gateway-like framework with an ENS CCIP-Read Resolver wrapped in a `base32` and `base36` decoder. IPFS2.eth is capable of resolving IPFS and IPNS (and IPLD) contenthashes as subdomains `*.ipfs2.eth` when queried as ENS subdomain or via public ENS gateway services such as `*.IPFS2.eth.limo`  

## Supported Subdomain Formats :
### IPFS (base32) : `b<base32>.ipfs2.eth`
> https://bafybeiftyo7xm6ktvsmijtwyzcqavotjybnmsiqfxx3fawxvpr666r6z64.ipfs2.eth.limo

### IPNS (base36) : `k<base36>.ipfs2.eth`
> https://k51qzi5uqu5dkgt2xdmfcyh6058cl8fa6tfnj06u6vdf510260imor3yak48fv.ipfs2.eth.limo

### IPLD(base32/dag-cbor) : 
https://bafyreie2nochynilsdmcyqpxid7d2dzdle4dbptvep65kujtg2uywm7jre.ipfs2.eth.limo
> 
### IPFS/IPNS (Base16/sub domains) : `f<prefix>.<bytes16>.<bytes16>.ipfs2.eth`
> https://f0172002408011220.32a1a9c61c6d14bbde2bca0be1b28c28.6be6b484fc804170e2d632b07f0c0b0d.ipfs2.eth.limo

### ENS Contenthash (Base16/sub domains) : `<prefix>.<bytes16>.<bytes16>.ipfs2.eth`

>https://e5010172002408011220.32a1a9c61c6d14bbde2bca0be1b28c28.6be6b484fc804170e2d632b07f0c0b0d.ipfs2.eth.limo

Several centralised providers offer public gateways for IPFS/IPNS resolution such as `https://dweb.link` and `https://ipfs.io`. IPFS2 is a service similar to these public IPFS gateways but it uses an ENS CCIP-Read Resolver and public ENS gateways (`eth.limo`, `eth.link` etc). IPFS2 uses `eth.limo` as its default CCIP gateway to read specific ENS records and is designed to fallback to secondary gateways.

## Design

IPFS2 architecture is as follows:

![](https://raw.githubusercontent.com/namesys-eth/ipfs2-resources/main/graphics/ipfs2.png)


### Resolve `contenthash`

Resolution of `<CIDv1-base32>.ipfs2.eth` will decode and resolve `<CIDv1-base32>` via CCIP as ABI-encoded contenthash. This functionality supports both IPNS and IPFS (and IPLD) contenthashes in `base32` format.

~~### Resolving ENS Records~~

~~IPFS2.eth doesn't support records management for ipfs/IPNS subdomains, we've no owner records for subs to validate & plaintext records are not good for security reasons..~~


#### Using Ethers JS, resolver contract converts ipfs/ipns hash subdomain as contenthash  

```js
let wallet = new BrowserProvider(window.ethereum);
const resolver = await wallet.getResolver("bafybeiftyo7xm6ktvsmijtwyzcqavotjybnmsiqfxx3fawxvpr666r6z64.ipfs2.eth");
let contenthash = await resolver.getContentHash();
console.log(contenthash);
```

## Contracts

Testnet : [`0x6418fc3db67e3c7a6aeafcb5a6416ccd6b75ef30`](https://goerli.etherscan.io/address/0x6418fc3db67e3c7a6aeafcb5a6416ccd6b75ef30#code)

Mainnet : [Code audit in progress](https://github.com/namesys-eth/ipfs2-eth-resolver/blob/main/src/IPFS2.sol)

## Source Codes

IPFS2 CCIP contracts are available on [GitHub](https://github.com/namesys-eth/ipfs2-eth-resolver)
