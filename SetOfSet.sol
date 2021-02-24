pragma solidity ^0.4.24;






contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SetOfSetToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    address public owner;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    IERC20 setToken;
    
    uint256 ttlSet;
    uint256[10] units;
    address[10] sets;
    mapping(address=>uint256) setUnits;


    constructor() public {
        symbol = "SetOfSet";
        name = "SOS Token";
        decimals = 18;
        owner = msg.sender;
        _totalSupply = 0;
        ttlSet=0;
        setToken = IERC20(0x4EcBa77ace8d7Bb94eeDe3A53DA5Eff75b90fC89);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    
    function addSet(address set, uint256 unit) public{
        require(setUnits[set]==0,"Set already inserted");
        require(unit>0,"Units should be >0");
        require(ttlSet<10,"MAX 10 set can be included");
        units[ttlSet]=unit;
        sets[ttlSet]=set;
        ttlSet+=1;
        setUnits[set]=unit;
    }
    
    function isSet(address set) public view returns(bool){
        return !(setUnits[set]>0);
    }
    
    function getUnits(address set) public view returns(uint256){
        return setUnits[set];
    }
    
    function sendNewToken(address addr, uint256 n) internal{
        balances[addr] = safeAdd( balances[addr] , n);
        emit Transfer(0x0000000000000000000000000000000000000000,addr,n);
    }
    
    function issueSetOfSet(uint256 n) public returns(address){
        for(uint i=0;i<ttlSet;i+=1){
            // IERC20(sets[i]).approve(this,n*units[i]);
            IERC20(sets[i]).transferFrom(msg.sender,this, n*units[i]);
        }
        _totalSupply+=n;
        sendNewToken(msg.sender,n);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
        // return setToken.totalSupply();
    }


    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }


    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}