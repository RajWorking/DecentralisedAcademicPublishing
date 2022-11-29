# car-manufacturing-contract
Tushar Jain - 2019101091
Raj Maheshwari - 2019101039

## Things you need to install

```
# for your solidity compiler (not too sure if this needed since we are using truffle)
npm install -g solc
# for the testing interface
npm install -g truffle
```

## To run the tests of a certain file
```
truffle test <path to file>
```
Read more on `https://trufflesuite.com/docs/truffle/quickstart/` for the truffle setup and such.

## Architecture

**A basic flow of the marketplace would be as such**
- The marketplace owner has the ability to register suppliers and manufacturers into the marketplace, with a simple call where he registers their address.
- The marketplace owner will put the market into the `INVENTORY_UPDATE` phase, where suppliers will update their inventory data. Their supply gets refilled according to their supply limit.
- The marketplace owner will then put the market into the `BID` phase, where manufacturers will view suppliers total supply and will place their bids by giving hash of (material, amt, price, nonce). Manufacturers also have to stake some amount larger than their actual bid.
- The marketplace owner will then put the market into the `REVEAL` phase, where manufacturers will reveal their bids. This will get checked against their hash and compared with stake amount.
- The marketplace owner will then put the market into the `CLOSED` phase, after which the smart contract will resolve the bids, give the manufacturers their respective materials, pay the suppliers, and refund any unused money of the manufacturers. It will not reset the inventory of the suppliers.
- The manufacturers, can then manufacture cars, and update their for-sale car inventory. They will not be able to register more cars than they could possible produce, as the smart contract will check this.
- Buyers can view and buy whatever cars they want at whatever time they want.

Here is a basic idea of the things we needed to build this marketplace. 
![](./img/flow.png)

## Overview of data stored in the contract

### Data structures

#### **NFT**
- `owner` - Address of the owner of this NFT
- `item` - Material of this NFT
- `objectId` - Unique ID of this non-fungible token

#### **Bidder**
- `bids` - The actual bids (quantity and bid amount) for each material.
- `blindBids` - Hash of bids corresponding to each material.
- `suppliers` - Suppliers for corresponding to each material.
- `totalAmt` - The address of the supplier the manufacturer wants the object from.

#### **Supplier**
- `supplierAddress` - Address of the supplier.
- `name` - Name of the supplier.
- `supply` - the list of all the supplies the supplier owns.
- `item` - type of material that the supplier produces.
- `totalProduced` - total number of goods produced till now.

#### **Manufacturer**
- `manufacturerAddress` - Address of the Manufacturer.
- `name` - Name of the supplier.
- `supply` - The list of all the supplies the manufacturer has bought through bidding and the cars produced.
- `totalProduced` - total number of goods produced till now.
- `carPrice` - Price of the cars produced.

#### **Customer**
- `customerAddress` - customer's address
- `name` - Name of Customer
- `cars` - the list of all the products owned by the customer.

### Data stored
We store the current phase of the market. This can be viewed by anyone.
We store lists for the customers, Suppliers and manufacturers, which store their respective data. There are functions for people to view relevant data, such as a function for customers to view the prices of the products of their manufactueres.
We store all the bids placed by the manufacturers for all the suppliers. Bids are revealed only in REVEAL phase.
We also store the stakes of each manufacturer.

### Resource Allocation Algorithm
First, we give the maximum possible wheels to manufacturers from suppliers as per their supply limits.
Then, for maximizing products, we take minimum of the car_bodies demand and wheels divided by 4. Higher bidder is given preference now since products produced is same. And then we give requested car bodies to lower bidder.
Finally, we redistribute the remaining items from which no products can any longer be produced to the highest bidder and then the lower bidder.

# How to run
Make sure ganache is running on port 7545

```
npm i
# To compile the  contract
truffle compile
# To run tests
truffle test 
```