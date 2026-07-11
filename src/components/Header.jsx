function Header({ title, themeColor }) {
  return (
    <header
      style={{
        backgroundColor: themeColor,
        color: "white",
        padding: "20px",
        textAlign: "center"
      }}
    >
      <h1>{title}</h1>
      <p>Welcome to my React Portfolio</p>
    </header>
  );
}

export default Header;