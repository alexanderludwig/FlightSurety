const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const fs = require('fs');

module.exports = async function(deployer) {
    // deploy a contract

    let firstAirline = '0xf17f52151EbEF6C7334FAD080c5704D77216b732';
    await deployer.deploy(FlightSuretyData, firstAirline);
    //access information about your deployed contract instance
    const fsd = await FlightSuretyData.deployed();

    await deployer.deploy(FlightSuretyApp, FlightSuretyData.address);
    //access information about your deployed contract instance
    const fsa = await FlightSuretyApp.deployed();

    let config = {
        localhost: {
            url: 'http://localhost:8545',
            dataAddress: FlightSuretyData.address,
            appAddress: FlightSuretyApp.address
        }
    }
    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');

    fsd.authorizeContract(FlightSuretyApp.address)

  }
  