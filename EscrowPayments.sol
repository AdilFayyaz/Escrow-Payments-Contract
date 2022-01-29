pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2; //Hint (or distraction): Allows returning arrays from functions

// Item - name,price,buyer,status
// A- avail, C - confirmed, D - disputed
// status can be set by buyer or 3rd party - not the seller
contract EscrowPayments {
    address payable public owner;
    Item [] public items; 
    address trusted_party;
    struct Item {
        string name;
        uint price;
        address payable buyer;
        bytes1 status;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    modifier onlyBuyer(string memory title, address sender){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                 require(sender == items[i].buyer);
             }
        }
        _;
    }
    modifier onlyTTP{
        require(msg.sender==trusted_party);
        _;
    }
    modifier onlyDisputed(string memory title){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                 require(items[i].status == 'D');
             }
        }
        _;
    }
    modifier onlyOwnerOrBuyer(string memory title){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                 require((items[i].buyer == msg.sender && items[i].status == 'R') 
                  || (owner == msg.sender && items[i].status == 'C'));
             }
        }
        _;
    }
    
    constructor(){
        trusted_party = address(0);
        owner = payable(msg.sender);
    }
    
    function addItem(string memory _title, uint8 _price) public onlyOwner{
        Item memory i;
        i.name = _title;
        i.price = _price;
        i.status = 'A';
        i.buyer = payable(address(0));
        items.push(i);
    }
    function listItems() public view returns(Item [] memory){
        return items;
    }
    function addTTP(address _ttp) public onlyOwner {
        require(trusted_party == address(0));
        trusted_party = _ttp;
    }
    function trustedTP() public view returns(address){
        return trusted_party;
    }
    
    function buyItem(string memory title) payable public{
        bool flag = false;
        for(uint i=0; i<items.length; i++){
            if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                require(items[i].status == 'A');
                require(msg.value >= items[i].price*1000000000000000000); // Require value to be more or equal to the price
                flag = true;
                items[i].buyer = payable(msg.sender);
                items[i].status='P';

            }
        }
        if(!flag){
            revert("Title searched not found");
        }
    }
    function confirmPurchase(string memory title, bool isSuccess) public onlyBuyer(title, msg.sender){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                if(isSuccess){
                    items[i].status ='C';
                }
                else{
                    items[i].status = 'D';
                }
             }
        }
    }
    
    function handleDispute(string memory title, bytes1 status) public onlyTTP onlyDisputed(title){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                 items[i].status = status;
             }
        }
    }
   
    function receivePayment(string memory title) public payable onlyOwnerOrBuyer(title){
        for(uint i=0;i<items.length;i++){
             if(keccak256(bytes(title)) == keccak256(bytes(items[i].name))){
                 if(items[i].status == 'R'){
                    items[i].buyer.transfer(items[i].price*1000000000000000000);
                    items[i].status = 'X';
                 }
                 else if(items[i].status == 'C'){
                     owner.transfer(items[i].price*1000000000000000000);
                     items[i].status = 'X';
                 }

             }  
        }
    }

}

// let myins = await EscrowPayments.deployed()
// myins.owner().then(value=>value.toString())
// myins.addTTP(accounts[2])
// myins.trustedTP().then(value=>value.toString())
// myins.addItem('ItemA', 1)
// myins.addItem('ItemB', 2)
// myins.addItem('ItemC', 3)
// myins.listItems().then(value=>value.toString())
// myins.buyItem('ItemB', {value:web3.utils.toWei('2','ether'), from:accounts[1]})
// myins.confirmPurchase('ItemB',false, {from:accounts[1]})
// myins.handleDispute('ItemB','0x52',{from:accounts[2]})
// myins.receivePayment('ItemB', {from:accounts[1]})

// web3.eth.getBalance(accounts[1])


