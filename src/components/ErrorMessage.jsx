function ErrorMessage({ message, retry }) {
  return (
    <div className="card">
      <h2>Error</h2>

      <p>{message}</p>

      <button onClick={retry}>
        Retry
      </button>
    </div>
  );
}

export default ErrorMessage;