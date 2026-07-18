import { useState } from "react";

function Contact() {

  const [message, setMessage] = useState("");

  const [showHelp, setShowHelp] = useState(false);

  return (
    <div className="card">

      <h2>Contact</h2>

      <input
        type="text"
        placeholder="Enter your message"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
      />

      <p>
        Message :
        {message}
      </p>

      <p>
        Character Count :
        {message.length}
      </p>

      <button onClick={() => setShowHelp(!showHelp)}>
        {showHelp ? "Hide Help" : "Show Help"}
      </button>

      {showHelp && (
        <p>
          Please enter your message above.
        </p>
      )}

    </div>
  );
}

export default Contact;