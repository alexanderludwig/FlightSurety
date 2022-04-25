
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');


const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");


contract('Flight Surety Tests', async (accounts) => {

  var config;

    const airline1 = accounts[1];
    const airline2 = accounts[2];
    const airline3 = accounts[3];
    const airline4 = accounts[4];
    const airline5 = accounts[5];
    const airline6 = accounts[6];
    const airline7 = accounts[7];
    const customer1 = accounts[8];

    let flight;
    let timestamp;
    let flightKey;


  before('setup contract', async () => {
    config = await Test.Config(accounts);

    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    flight = 'ND1309'; 
    timestamp = Math.floor(Date.now() / 1000);
    flightKey = flightSuretyData.getFlightKey(airline1, flight, timestamp);
    


    assert.equal(await flightSuretyApp.isAuthorized(), true)
    assert(flightSuretyData.isAirlineRegistered.call(airline1))

});

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    let status = await flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await flightSuretyApp.setOperatingStatus(false, { from: accounts[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try 
    {
        await flightSuretyApp.setOperatingStatus(false, { from: accounts[0]});
    }
    catch(e) {
        accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
    
});



  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();


      let reverted = false;
      try 
      {
          await flightSuretyData.deauthorizeContract(FlightSuretyApp.address);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await flightSuretyApp.setOperatingStatus(true, { from: accounts[0]});

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    try {
        await flightSuretyApp.registerAirline(airline2, {from: airline1});
    }
    catch(e) {

    }
    let result = await flightSuretyApp.isAirlineRegistered.call(airline2); 

    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() after it provided funding', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    let fundingAmount = web3.utils.toWei("10", "ether");
    await flightSuretyApp.provideAirlineFunding({from: airline1, value: fundingAmount})
    
    fundedAmount = await flightSuretyData.getAirlineBalance.call(airline1);
    

    let result = await flightSuretyApp.isAirlineParticipating(airline1); 

    await flightSuretyApp.confirmAirlineRegistration(airline2, {from: airline1});    
    await flightSuretyApp.registerAirline(airline2, {from: airline1});

    let result2 = await flightSuretyApp.isAirlineRegistered.call(airline2); 


    assert.equal(result, true, "Airline should be participating after providing funding");
    assert.equal(result2, true, "Airline should be able to register another airline");

  });

  it('(airline) participating airline can add new airlines', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    assert(flightSuretyApp.isAirlineRegistered.call(airline1))
    assert(flightSuretyApp.isAirlineParticipating.call(airline1))


    await flightSuretyApp.confirmAirlineRegistration(airline3, {from: airline1});
    await flightSuretyApp.registerAirline(airline3, {from: airline1});
    await flightSuretyApp.confirmAirlineRegistration(airline4, {from: airline1});
    await flightSuretyApp.registerAirline(airline4, {from: airline1});
    numRegistered = await flightSuretyData.getNumberRegisteredAirlines.call();
    
    assert(numRegistered == 4);

    let fundingAmount = web3.utils.toWei("10", "ether");
    await flightSuretyApp.provideAirlineFunding({from: airline2, value: fundingAmount})
    await flightSuretyApp.provideAirlineFunding({from: airline3, value: fundingAmount})
    await flightSuretyApp.provideAirlineFunding({from: airline4, value: fundingAmount})

    let result2 = await flightSuretyApp.isAirlineParticipating.call(airline2); 
    let result3 = await flightSuretyApp.isAirlineParticipating.call(airline3); 
    let result4 = await flightSuretyApp.isAirlineParticipating.call(airline4); 
    assert(result2 && result3 && result4);

  });


  it('(multiparty) if not enough airlines confirm the registration of a new airline, the registration should fail', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();
    

    let reverted = false;
    try 
    {
        await flightSuretyApp.registerAirline(airline5, {from: airline1});
    }
    catch(e) {
        reverted = true;
    }

    
    
    assert.equal(reverted, true, "Airline should not be allowed to get confirmed");

  });

  it('(multiparty) if enough airlines confirm the registration of a new airline, the registration should succeed', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();

    await flightSuretyApp.confirmAirlineRegistration(airline5, {from: airline1});
    await flightSuretyApp.confirmAirlineRegistration(airline5, {from: airline2});
    await flightSuretyApp.confirmAirlineRegistration(airline5, {from: airline3});

    await flightSuretyApp.registerAirline(airline5, {from: airline1});


    
    let isRegistered = await flightSuretyApp.isAirlineRegistered(airline5, {from: airline1});
    
    
    assert.equal(isRegistered, true, "Airline should not be able to get confirmed.");
  });


  it('(airline) can register and update flights', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();


    await flightSuretyApp.registerFlight(airline1, flight, timestamp);
    await flightSuretyData.updateFlight(airline1, flight, timestamp, 10);

    let flightStatus = await flightSuretyData.getFlightStatus(airline1, flight, timestamp);
    
    assert.equal(flightStatus, 10, "Flight status did not get updated.");
  });


  it('customer can buy insurance for a flight', async () => {
    let flightSuretyApp = await FlightSuretyApp.deployed();
    let flightSuretyData = await FlightSuretyData.deployed();


    let insuranceAmount = web3.utils.toWei("0.5", "ether");
    await flightSuretyApp.buy(airline1, flight, timestamp, {from: customer1, value: insuranceAmount});
        
    let paidInsurance = await flightSuretyData.getPaidInsurance.call(customer1,airline1, flight, timestamp);
    
    assert.equal(insuranceAmount, BigNumber(paidInsurance), "Flight status did not get updated.");
  });
});
