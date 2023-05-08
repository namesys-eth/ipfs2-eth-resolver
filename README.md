# `IPFS2.ETH`
[![test](https://github.com/0xc0de4c0ffee/ipfs2-eth-resolver/actions/workflows/test.yml/badge.svg?event=workflow_run)](https://github.com/0xc0de4c0ffee/ipfs2-eth-resolver/actions/workflows/test.yml)

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

IPFS2.eth ("IPFS To ETH") is a proof-of-concept IPFS gateway `like` design using an ENS CCIP-read Resolver wrapped in a `base32`and `base36` decoder, it's capable of resolving IPFS and IPNS (and IPLD) contenthashes as subdomains `*.ipfs2.eth` when queried as ENS subdomain or from public ENS gateways services like `*.IPFS2.eth.limo`  

> IPFS : https://bafybeiftyo7xm6ktvsmijtwyzcqavotjybnmsiqfxx3fawxvpr666r6z64.ipfs2.eth.limo 
> IPNS : https://k51qzi5uqu5dkgt2xdmfcyh6058cl8fa6tfnj06u6vdf510260imor3yak48fv.ipfs2.eth.limo
> IPLD : https://bafyreie2nochynilsdmcyqpxid7d2dzdle4dbptvep65kujtg2uywm7jre.ipfs2.eth.limo

---

- to fetch the ENS contenthash as the parent domain's subdomain, and
- to fetch the RFC-8615 compliant ENS records stored at that contenthash, if requested.

Several centralised providers offer public gateways for IPFS/IPNS resolution such as `https://dweb.link` and `https://ipfs.io`. IPFS2 is a service similar to these public IPFS gateways but it uses an ENS CCIP Resolver and public ENS gateways (`eth.limo`, `eth.link` etc). IPFS2 uses `eth.limo` as its default CCIP gateway to read specific ENS records and is designed to fallback to secondary gateways.

## Design

IPFS2 architecture is as follows:

![](https://raw.githubusercontent.com/namesys-eth/ipfs2-resources/main/graphics/ipfs2.png)

## Query Syntax

### Resolve `contenthash`

Resolution of `<CIDv1-base32>.ipfs2.eth` will decode and resolve `<CIDv1-base32>` via CCIP as ABI-encoded contenthash. This functionality supports both IPNS and IPFS (and IPLD) contenthashes in `base32` format.

### Resolving ENS Records

IPFS2 Resolver also supports ENS-specific features such as querying ENS records associated with the (sub)domain. We use [RFC-8615](https://www.rfc-editor.org/rfc/rfc8615) `.well-known` directory format to implement this. The query syntax then reads:

```
https://<hash>.ipfs2.eth.*/.well-known/<data>.json
```

#### Some Examples

1. (Sub)domain's ENS avatar record is stored as `<CIDv1-base32>.ipfs2.eth.*/.well-known/avatar.json` in format

```
{
  "data": "0x_abi_encoded_avatar_string"
}
```

2. (Sub)domain's ETH address record is stored as `<CIDv1-base32>.ipfs2.eth.*/.well-known/addr-60.json` in format

```
{
  "data": "0x_abi_encoded_address"
}
```

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
