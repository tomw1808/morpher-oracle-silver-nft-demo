This is a demo for the [Morpher Oracle](https://oracle.morpher.com).

## Content

![Screenshot Demo App](./screenshot.png)

In this Demo App you can see how the Data-Dependent User Operations are working.

It creates a new ERC4337 Safe Wallet. Then it mints a Silver NFT with current USD prices for an Ounce of Silver. This is done by getting two prices:

The XAG/USD Prices, tick data accuracy. And the POL/USD Prices also with tick-level accuracy.

This is packaged up into an ERC4337 Transaction with two UserOps:

The first User-OP is updating the Oracle, the second User-Op is then talking to the Silver NFT and mints the NFT for current prices.

Read more on https://oracle.morpher.com