contract Hello {
  string32 message;

  // Constructor
  function Hello() {
    message = "Hello World";
  }

  // Sets the message.
  function setMessage(string32 _message) {
    message = _message;
  }

  // Gets the message.
  function getMessage() constant returns (string32) {
    return message;
  }
}
