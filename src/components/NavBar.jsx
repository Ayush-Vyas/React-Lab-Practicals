import { Link } from "react-router-dom";

function NavBar() {
  return (
    <nav className="navbar">
      <h2>Student Portfolio</h2>

      <div>
        <Link to="/">Home</Link>

        <Link to="/projects">Projects</Link>

        <Link to="/contact">Contact</Link>
      </div>
    </nav>
  );
}

export default NavBar;