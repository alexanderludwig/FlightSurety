pragma solidity ^0.8.13;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    FlightSuretyData flightSuretyData;


    // Event fired each time a new flight is registered
    event FlightRegistered(address airline, string flight, uint256 timestamp);

    // Event fired each time a new airline is confirmed
    event RegistrationConfirmed(address indexed confimedBy, address indexed airline);

    // Event fired each time a new airline is registered
    event AirlineRegistered(address indexed airline);




 
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
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address payable dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/



    function isAuthorized() 
                            public 
                            view
                            returns(bool) 
    {
        return flightSuretyData.isAuthorized(address(this));  // Modify to call data contract's status
    }
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    function getAddress() public view returns(address)

        {return address(this);} 
        
    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  

    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            returns(bool success, uint256 votes)
    {
        (success, votes) = this.isConfirmed(address(flightSuretyData));
        if(success || contractOwner == msg.sender)
        {
            flightSuretyData.setOperatingStatus(msg.sender, mode);
        }
        else {
            revert();
        }
        
    }

    function checkAddress(address toCheck)
                                            external
                                            view 
                                            returns(bool)
    {
        if (toCheck == address(this))
            {return true;}
        else{return false;}
    }

    function confirmOperatingStatusChange
                                          (
                                          )
                                          external
    
    {
        flightSuretyData.confirmTransaction(msg.sender, address(flightSuretyData));
    }

    function confirmAirlineRegistration(
                                            address airlineToConfirm
                                       )
                                       external
    
    {
        flightSuretyData.confirmTransaction(msg.sender, airlineToConfirm);
        emit RegistrationConfirmed(msg.sender, airlineToConfirm);
    }



    function isConfirmed
                        (
                            address toConfirm
                        )
                        external
                        view
                        returns(bool success, uint256 votes)
    {
        votes = flightSuretyData.countConfirmations(toConfirm);
        uint256 numAirlines = flightSuretyData.getNumberRegisteredAirlines();
        success = false;
        if (numAirlines < 4) {
            if(votes>=1){
                success = true;
            }
        }
        else {
            if(votes >= numAirlines/2){
                success = true;
            }
        }
    }

    function isAirlineRegistered
                                (
                                    address airline
                                )
                                external
                                view
                                returns(bool)
    {
        return flightSuretyData.isAirlineRegistered(airline);
    }

    function isAirlineParticipating
                                (
                                    address airline
                                )
                                external
                                view
                                returns(bool)
    {
        uint256 airlineBalance = flightSuretyData.getAirlineBalance(airline);

        return flightSuretyData.isAirlineRegistered(airline) && (airlineBalance >= 10 ether);
    }



   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            ( 
                                address airline  
                            )
                            external
                            returns(bool success, uint256 votes)
    {
        this.confirmAirlineRegistration(airline);
        (success, votes) = this.isConfirmed(airline);
        if(success)
        {
            flightSuretyData.registerAirline(msg.sender, airline);
            emit AirlineRegistered(airline);
        }
        else {
            require(false, 'Airline could not be registered');
        }
    }

    function provideAirlineFunding
                                    (
                                    )
                                    external
                                    payable
                                    returns (uint256)
    {
        flightSuretyData.fund{value:msg.value}(msg.sender);
        return flightSuretyData.getAirlineBalance(msg.sender);
    }




    function buy
                (          
                    address airline,
                    string memory flight,
                    uint256 timestamp                   
                )
                external
                payable
    {
        require(msg.value <= 1 ether);
        flightSuretyData.buy{value:msg.value}(msg.sender, airline, flight, timestamp);
    }

    function pay 
                (
                )
                external
    {
        flightSuretyData.pay(msg.sender);
    }

       /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp  
                                )
                                external
    {
        this.fetchFlightStatus(airline, flight,timestamp);
        flightSuretyData.registerFlight(msg.sender, airline, flight, timestamp);
        emit FlightRegistered(airline, flight,timestamp);
    }

    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
    {
        // store the new flight status in the data contract
        flightSuretyData.updateFlight(airline, flight, timestamp, statusCode);

        if (statusCode == STATUS_CODE_LATE_AIRLINE){
            creditInsurees(airline, flight, timestamp);
        }
    }

    function creditInsurees
                            (
                                address airline,
                                string memory flight,
                                uint256 timestamp
                            )
                            internal
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        
        address[] memory insured = flightSuretyData.getInsuredPassengers(flightKey);

        for(uint i = 0; i< insured.length; i++){
            address insuree = insured[i];
            uint256 paidInsurance = flightSuretyData.getPaidInsurance(insuree, airline, flight, timestamp);
            uint256 userCredit = paidInsurance.mul(15).div(10);
            flightSuretyData.creditInsuree(insuree, userCredit);
        }

    }

    function getAccountCredit
                                (
                                )
                                public
                                view
                                returns(uint256)
                                
    {
      return flightSuretyData.getAccountCredit(msg.sender);
    }



    /********************************************************************************************/
    /*                                     ORACLES FUNCTIONS                                    */
    /********************************************************************************************/
    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));

        ResponseInfo storage info = oracleResponses[key];
        info.requester = msg.sender;
        info.isOpen = true;

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }



// endregion

}   
