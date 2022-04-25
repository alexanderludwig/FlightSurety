
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
import * as bootstrap from 'bootstrap';



(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        if (window.location.pathname == '/') {
            console.log('PATHNAME', window.location.pathname)

            DOM.elid('go-airline').addEventListener('click', () => {
                window.location.href = 'airline.html';
            });
            DOM.elid('go-passenger').addEventListener('click', () => {
                window.location.href = 'passenger.html';
            });
        } else if (window.location.pathname == '/airline.html') {
            setupAirline();
        } else if (window.location.pathname == '/passenger.html') {
            setupPassenger();
        }


        let eventsText = [];
        contract.listenEvents((content) => {
            if (!eventsText.includes(content)) {
                console.log(content);
                DOM.elid('events').innerHTML += `<div class="alert alert-success" role="alert">${content}</div>`;
                eventsText.push(content);
            }
        });
 

    

        // User-submitted transaction
        /* DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        }) */
        function setupAirline(){
            DOM.elid('btn-confirm-airline').addEventListener('click', () => {
                let airline = DOM.elid('text-register-airline').value;
                contract.confirmAirlineRegistration(airline, (err, res) => {
                    showModal(err, 'Confirm Airline', 'Request was sent successfully, we will let you know when its ready.');
                });
    
            });
    
            DOM.elid('btn-register-airline').addEventListener('click', () => {
                let airline = DOM.elid('text-register-airline').value;
                contract.registerAirline(airline, (err, res) => {
                    showModal(err, 'Register Airline', 'Request was sent successfully.');
                });
    
            });
    
            DOM.elid('btn-fund-airline').addEventListener('click', () => {
                contract.provideAirlineFunding((err, res) => {
                    showModal(err, 'Fund Airline', 'Request was sent successfully.');
                });
            });
            DOM.elid('btn-register-flight').addEventListener('click', () => {
                 let airline = DOM.elid('text-register-flight-address').value;
                 let flight = DOM.elid('text-register-flight-number').value;
                 let timestamp = DOM.elid('text-register-flight-ts').value;
     
                 contract.registerFlight(airline, flight, timestamp, (err, res) => {
                     showModal(err, 'Register Airline', 'Request was sent successfully.');
                 });
             });

        }

        function setupPassenger(){

            DOM.elid('btn-account-information').addEventListener('click', () => {
                document.getElementById("information-account-address").innerHTML = "Address " + String(contract.account); 
                contract.getAccountCredit((error, result) => {
                    console.log(error,result);
                    document.getElementById("debit").innerHTML = "Debit: " + String(result);
                });
             });


            

             DOM.elid('btn-buy-insurance').addEventListener('click', () => {
                  let airline = DOM.elid('text-buy-insurance-flight-address').value;
                  let flight = DOM.elid('text-buy-insurance-flight-number').value;
                  let timestamp = DOM.elid('text-buy-insurance-flight-ts').value;
                  let amount = DOM.elid('text-buy-insurance-amount').value;
     
                  contract.buyInsurance(airline, flight, timestamp, amount, (err, res) => {
                      showModal(err, 'Register Airline', 'Request was sent successfully.');
                  });
              });

              DOM.elid('btn-retrieve-status-update').addEventListener('click', () => {
                console.log('PRESSED')
                let airline = DOM.elid('text-status-update-flight-address').value;
                let flight = DOM.elid('text-status-update-flight-number').value;
                let timestamp = DOM.elid('text-status-update-flight-ts').value;
                console.log('PRESSED2')

                contract.fetchFlightStatus(airline, flight, timestamp, (err, res) => {
                    showModal(err, 'Fetch flight status', 'Request was sent successfully.');
                });
                console.log('PRESSED3')

            });

            DOM.elid('btn-claim-funds').addEventListener('click', () => {
                let airline = DOM.elid('text-claim-funds-address').value;
   
            });


        }


        
 



    

    });

    function showModal(err, title, message) {
        var modal = new bootstrap.Modal(document.getElementById('modal'));

        document.getElementById('modal').addEventListener('shown.bs.modal', function (event) {
            document.getElementById('modal-title').innerHTML = title;
            if (err != null) {
                document.getElementById('modal-body').innerHTML = `Error: ${err}`;
            } else {
                document.getElementById('modal-body').innerHTML = message;
            }
        })
        modal.toggle();
    }
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







