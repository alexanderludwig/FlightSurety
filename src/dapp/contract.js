import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyApp.json';

import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        this.config = Config[network];
        //this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        console.log('test')
        //this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        //this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.confirmations = {};
        this.registeredFlights = [];
        this.setup(callback);
        this.initWeb3(callback);


    }

    

    // look for event FlightStatusInfo(airline, flight, timestamp, statusCode) after oracle processed the request 
    // emit event for registered airlines
    // dapp ability to register new airline - show registered airlines in a list, and if they need to be confirmed show a button next to them

    async setup(callback){



        this.flightSuretyApp.events.RegistrationConfirmed({
            fromBlock: 0
          }, function (error, event) {
            if (error) console.log(error)
            console.log(event)
            // console.log(event.returnValues[1])
            let confirmedBy = event.returnValues[0];
            let airline = event.returnValues[1];

            if (this.confirmations[airline]) {
                this.confirmations[airline].push(confirmedBy);
            } else {
                this.confirmations[airline] = [confirmedBy];
            }
        });

        this.flightSuretyApp.events.FlightRegistered({
            fromBlock: 0
          }, function (error, event) {
            if (error) console.log(error)
            //console.log(event)
            // console.log(event.returnValues[1])
            let airline = event.returnValues[0];
            let flight = event.returnValues[1];
            let timestamp = event.returnValues[2];

            this.registeredFlights.push([airline, flight, timestamp]);
        });


        callback();
        
    }
    
   

    async listenEvents(callback) {
        let self = this;
        this.flightSuretyData.events.AirlineRegistered().on('data', function (event) {
            let data = event.returnValues;
            callback(data);
        });
    }



    async initWeb3(callback) {
        // Modern dapp browsers...
        if (window.ethereum) {
            this.web3Provider = window.ethereum;
        try {
            // Request account access
            await window.ethereum.enable();
        } catch (error) {
            // User denied account access...
            console.error("User denied account access")
        }
        }
        // Legacy dapp browsers...
        else if (window.web3) {
            this.web3Provider = window.web3.currentProvider;
        }
        // If no injected web3 instance is detected, fall back to Ganache
        else {
            this.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        }
        this.web3 = new Web3(this.web3Provider);

        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, this.config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, this.config.dataAddress);
        
        this.account = await this.web3.eth.getAccounts();
        this.account = this.account[0]
        console.log(this.account)
        callback()
    }

    /* async listenEvents(callback) {
        this.flightSuretyData.events.FlightRegistered().on('data', function (event) {
            let data = event.returnValues;
            console.log('EVENT triggered.')
            callback(`Airline ${data.airline} registered flight ${data.flightKey} with ts ${data.timestamp}`);
        });
    } */


    async isOperational(callback) {
       this.flightSuretyApp.methods
            .isOperational()
            .call({ from: this.account}, callback);
    }

    async getAccountCredit(callback) {
        this.flightSuretyApp.methods
            .getAccountCredit()
            .call({ from: this.account}, callback);
    }


    async confirmAirlineRegistration(airline, callback) {
        await this.flightSuretyApp.methods.confirmAirlineRegistration(airline).send({
            from: this.account
        }, (err, res) => {
            callback(err, res);
        });
    }


    async registerAirline(airline, callback) {
        console.log('registering')
        await this.flightSuretyApp.methods.registerAirline(airline).send({
            from: this.account
        }, (err, res) => {
            callback(err, res);
        });
    }

    async provideAirlineFunding(callback) {
        await this.flightSuretyApp.methods.provideAirlineFunding().send({
            from: this.account, value: this.web3.utils.toWei("10", "ether")
        }, (err, res) => {
            callback(err, res);
        });
    }


    async registerFlight(airline, flight, timestamp, callback) {
        await this.flightSuretyApp.methods.registerFlight(airline, flight, timestamp).send({
            from: this.account
        }, (err, res) => {
            callback(err, res);
        });
        console.log('FLIght registered')
    }

    async buyInsurance(airline, flight, timestamp, amount, callback) {
        await this.flightSuretyApp.methods.buy(airline, flight, timestamp).send({
            from: this.account, value: this.web3.utils.toWei(amount, "ether")
        }, (err, res) => {
            callback(err, res);
        });
    }

    async fetchFlightStatus(airline, flight, timestamp, callback) {
        await this.flightSuretyApp.methods.fetchFlightStatus(airline, flight, timestamp).send({
            from: this.account}, (err, res) => {
            callback(err, res);
        });
    }

    async creditInsurees(airline, flight, timestamp, callback) {
        await this.flightSuretyApp.methods.creditInsurees(airline, flight, timestamp).send({
            from: this.account}, (err, res) => {
            callback(err, res);
        });
    }
    

 
 







/*     fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: 1650562771
        } 
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
 */
    fetchRegisteredAirlines(callback) {
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner},callback)
    }






}