pragma solidity ^0.8.13;

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false


    address private currentAuthorized;

    // stores which existing airlines confirmed 1) a new airline or 2) change in operational status in contract
    mapping(address => mapping(address => bool)) confirmations;





    address[] private registeredAirlines;
    mapping(address => Airline) airlines;

    struct Airline {
        bool isRegistered;
        bool isFunded;
        uint256 balance;
    }


    mapping(bytes32 => bool) isFlightRegistered;
    bytes32[] registeredFlights;
    mapping(bytes32 => Flight) flightDetails;

    struct Flight {
        address airline;
        string flight;
        uint256 timestamp;
        uint8 statusCode;

    }



    // passengers
    // which passengers bought flight insurance for a respective flight
    mapping(bytes32 => address[]) insuredPassengers;

    // how much flight insurance did a customer pay
    mapping(bytes32 => mapping(address => uint256)) amountInsured;
    mapping(address => uint256) accountCredit;




    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Log(address msg, bool value);



    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (  
                                    address firstAirline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        //this.registerAirline(msg.sender, firstAirline);

        Airline memory airlineNew = Airline(true, false, 0);
        airlines[firstAirline] = airlineNew;
        registeredAirlines.push(firstAirline);


    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

  
    modifier requireIsRegistered(address sender){
        if (sender != contractOwner){
            require(this.isAirlineRegistered(sender), "Airline not registered");
        }
        _;
    }

    modifier requireIsParticipating(address sender){
        if (!(sender == contractOwner || address(this) == msg.sender || currentAuthorized == msg.sender)){
            require(this.isAirlineRegistered(sender), "Airline not registered.");
            require(this.isAirlineFunded(sender), "Airline did not provide enough funding");
        }
        _;
    }


    modifier requireIsCallerAuthorized(){
        require(currentAuthorized == msg.sender || contractOwner == msg.sender || address(this) == msg.sender, 'Contract is not authorized to call');
        _;
    }

    modifier requireIsFlightRegistered(
                                        address airline,
                                        string memory flight,
                                        uint256 timestamp
                                        )
    {
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);
        require(isFlightRegistered[flightKey], "Flight not registered for insurance");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

     function getContractOwner()
                                public
                                view
                                returns(address)
    {

        return contractOwner;
    }

    function getAddress() public view returns(address)

        {return address(this);} 

    
    
    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

    function isAuthorized(address authorized)
                                public
                                view
                                returns(bool)
    {

        return authorized == msg.sender;
    }



    function authorizeContract
                              (
                                  address appContract
                                ) 
                                external 
                                requireContractOwner
                                requireIsOperational
                                returns (bool)
    {
        currentAuthorized = appContract;
        return true;
    }


    function deauthorizeContract
                                (
                                    address appContract
                                ) 
                                external 
                                requireContractOwner
                                requireIsOperational
    {
        currentAuthorized = address(0);
    } 

    //function isContractAuthorized(address appContract) external 

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                address sender,
                                bool mode
                            ) 
                            external
                            requireIsCallerAuthorized
                            requireIsParticipating(sender)
    {
        operational = mode;

        //remove authorizations to prevent further status changes
        for(uint i = 0; i < registeredAirlines.length; i++)
        {
            confirmations[address(this)][registeredAirlines[i]] = false;
        }
        


    }



    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/



    function confirmTransaction
                                (
                                    address sender,
                                    address confirmAddress
                                ) 
                                external 
                                requireIsCallerAuthorized
                                requireIsParticipating(sender)
        {
            confirmations[confirmAddress][sender] = true;
         }

    function countConfirmations
                                (
                                   address toConfirmAddress 
                                )
                                view
                                external
                                requireIsCallerAuthorized
                                returns(uint256 countConfirmed)
    {
        countConfirmed = 0;
        for(uint i=0; i < registeredAirlines.length; i++) {
            if(confirmations[toConfirmAddress][registeredAirlines[i]]){
                countConfirmed +=1;
            }
        }
    }

    function getNumberRegisteredAirlines
                               (
                               )
                               view
                               external
                               requireIsCallerAuthorized
                               returns(uint256)
    {
        return registeredAirlines.length;
    }

    


   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (  
                                address sender,
                                address airlineAddress
                            )
                            external
                            requireIsCallerAuthorized
                            requireIsOperational
                            requireIsParticipating(sender)
    {
        Airline memory airlineNew = Airline(true, false, 0);
        airlines[airlineAddress] = airlineNew;
        registeredAirlines.push(airlineAddress);

    }

    function getRegisteredAirlines
                               (
                               )
                               external
                               requireIsCallerAuthorized
                               returns(address[] memory)
    {
        return registeredAirlines;
    }


    function isAirlineRegistered
                                (
                                    address airline
                                )
                                external
                                view
                                requireIsCallerAuthorized
                                returns(bool)
    {
        return airlines[airline].isRegistered;
    }

    function isAirlineFunded
                                (
                                    address airline
                                )
                                external
                                view
                                requireIsCallerAuthorized
                                returns(bool)
    {
        return this.getAirlineBalance(airline) >= 10 ether;
    }

    function getAirlineBalance

                                (
                                    address airline
                                )
                                external
                                view
                                requireIsCallerAuthorized
                                returns(uint256)
    {
        return airlines[airline].balance;
    }


    



    function registerFlight
                            (
                                address sender,
                                address airline,
                                string memory flight,
                                uint256 timestamp
                            ) 
                            external 
                            requireIsCallerAuthorized
                            requireIsOperational
                            requireIsParticipating(sender)
    {
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);
        isFlightRegistered[flightKey] = true;
        registeredFlights.push(flightKey);

        Flight memory flightInfo = Flight(airline, flight, timestamp, 0);
        flightDetails[flightKey] = flightInfo;

    }



    function updateFlight
                            (
                                address airline,
                                string memory flight,
                                uint256 timestamp,
                                uint8 statusCode
                            ) 
                            external 
                            requireIsCallerAuthorized
                            requireIsOperational
                            requireIsParticipating(airline)
    {
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);
        flightDetails[flightKey].statusCode = statusCode;
    }

    function getFlightStatus
                            (
                                address airline,
                                string memory flight,
                                uint256 timestamp
                            ) 
                            external 
                            view
                            requireIsCallerAuthorized
                            returns(uint256 statusCode)
    {
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);
        statusCode = flightDetails[flightKey].statusCode;
    }




    

   /**
    * @dev Buy insurance for a flight
    * TODO insurance can be only bought 60mins prior to the flight
    */   
    function buy
                            (          
                                address sender,
                                address airline,
                                string memory flight,
                                uint256 timestamp                   
                            )
                            external
                            payable
                            requireIsCallerAuthorized
                            requireIsOperational
                            requireIsFlightRegistered(airline, flight, timestamp)
                            
    {    
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);

        insuredPassengers[flightKey].push(sender);
        amountInsured[flightKey][sender] += msg.value;
    }

    function getInsuredPassengers
                               (
                                   bytes32 flightKey
                               )
                               external
                               requireIsCallerAuthorized
                               returns(address[] memory)
    {
        return insuredPassengers[flightKey];
    }

    function getPaidInsurance
                            (          
                                address insuree,
                                address airline,
                                string memory flight,
                                uint256 timestamp                   
                            )
                            external
                            view
                            requireIsCallerAuthorized
                            returns(uint256)

    {
        bytes32 flightKey = this.getFlightKey(airline, flight, timestamp);
        return amountInsured[flightKey][insuree];
    }


    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsuree
                                (
                                    address insuree, 
                                    uint256 userCredit 
                                )
                                external
                                requireIsCallerAuthorized
                                requireIsOperational
    {
        accountCredit[insuree] = userCredit;

    }

    function getAccountCredit
                                (
                                    address insuree
                                )
                                external
                                view
                                requireIsCallerAuthorized
                                returns(uint256)
                                
    {
      return accountCredit[insuree]; 
    }
                                
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                (
                    address insuree
                )
                external
                requireIsCallerAuthorized
                requireIsOperational
    {
        uint256 userCredit = accountCredit[insuree];
        accountCredit[insuree] = 0;
        address(insuree).call{value:userCredit}("");

    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund  
                                    (
                                        address airlineAddress
                                    )
                                    external
                                    payable
                                    requireIsCallerAuthorized
                                    requireIsOperational
    {
        airlines[airlineAddress].balance = airlines[airlineAddress].balance.add(msg.value);
    }

    

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        external
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    fallback() 
                            external 
                            payable 
    {
        this.fund(msg.sender);
    }


}

